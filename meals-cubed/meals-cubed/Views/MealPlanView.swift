import SwiftData
import SwiftUI

struct MealPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealPlanEntry.date) private var mealPlanEntries: [MealPlanEntry]
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    @State private var activeSheet: MealPlanSheet?
    @State private var showCompleted = true
    @State private var didAutoLoadCatalog = false
    @State private var catalogLoadError: String?

    init() {}

    private var visibleEntries: [MealPlanEntry] {
        mealPlanEntries
            .filter { showCompleted || !$0.isDone }
            .sorted { $0.date < $1.date }
    }

    private var plannableRecipes: [Recipe] {
        recipes
            .filter { $0.isBowlIdea || $0.recipeType == .dinner || $0.recipeType == .lunch || $0.recipeType == .snack }
            .sortedForPlanning
    }

    private var shouldLoadCatalog: Bool {
        StarterData.recipesNeedRefresh(recipes)
    }

    var body: some View {
        List {
            Section {
                Button {
                    activeSheet = .buildWeek
                } label: {
                    Label("Choose Meals From Catalog", systemImage: "checklist")
                }

                Button {
                    activeSheet = .add
                } label: {
                    Label("Custom Day", systemImage: "square.and.pencil")
                }

                Button {
                    activeSheet = .shoppingCart
                } label: {
                    Label("Shopping Cart", systemImage: "cart.fill")
                }

                Toggle("Show completed", isOn: $showCompleted)

                if let catalogLoadError {
                    Text(catalogLoadError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Catalog Planner")
            } footer: {
                Text("The catalog stays ready to go. Your meal plan is just the meals you choose for the coming week or weeks.")
            }

            Section("Plans") {
                if visibleEntries.isEmpty {
                    EmptyStateView(title: "No Meal Plans", message: "Choose meals from the catalog to fill the coming week.", systemImage: "calendar")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(visibleEntries) { entry in
                        MealPlanRow(
                            entry: entry,
                            toggleDone: {
                                entry.isDone.toggle()
                                try? modelContext.save()
                            },
                            edit: {
                                activeSheet = .edit(entry)
                            }
                        )
                    }
                }
            }
        }
        .navigationTitle("Meal Plan")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    activeSheet = .buildWeek
                } label: {
                    Image(systemName: "checklist")
                }
                .accessibilityLabel("Choose Meals From Catalog")

                Button {
                    activeSheet = .shoppingCart
                } label: {
                    Image(systemName: "cart.fill")
                }
                .accessibilityLabel("Shopping Cart")

                Button {
                    activeSheet = .add
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Custom Day")
            }
        }
        .sheet(item: $activeSheet) { sheet in
            NavigationStack {
                switch sheet {
                case .add:
                    MealPlanFormView()
                case .buildWeek:
                    BuildMealPlanView(recipes: plannableRecipes, existingEntries: mealPlanEntries)
                case .edit(let entry):
                    MealPlanFormView(entry: entry)
                case .shoppingCart:
                    ShoppingCartView(recipes: recipes, mealPlanEntries: mealPlanEntries)
                }
            }
        }
        .task {
            autoLoadCatalogIfNeeded()
        }
    }

    private func autoLoadCatalogIfNeeded() {
        guard !didAutoLoadCatalog, shouldLoadCatalog else { return }
        didAutoLoadCatalog = true
        do {
            try StarterData.load(into: modelContext)
        } catch {
            catalogLoadError = "Could not load catalog: \(error.localizedDescription)"
        }
    }
}

private struct MealPlanRow: View {
    let entry: MealPlanEntry
    let toggleDone: () -> Void
    let edit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Button {
                    toggleDone()
                } label: {
                    Image(systemName: entry.isDone ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(entry.isDone ? Color.mealAccent : Color.secondary)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(entry.isDone ? "Mark not done" : "Mark done")

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.date.shortMealDate)
                        .font(.headline)
                    Text(entry.dinnerName.isEmpty ? "Dinner not set" : entry.dinnerName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    edit()
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Edit meal plan")
            }

            VStack(alignment: .leading, spacing: 6) {
                mealText("Lunch", entry.lunchName)
                mealText("Side", entry.sideName)
                mealText("Snacks", [entry.snackOne, entry.snackTwo].filter { !$0.trimmed.isEmpty }.joined(separator: ", "))
            }

            TargetProgressRow(title: "Calories", value: entry.plannedCalories, target: HealthTargets.calories, unit: "")
            TargetProgressRow(title: "Protein", value: entry.plannedProtein, target: HealthTargets.protein, unit: "g")
            TargetProgressRow(title: "Fiber", value: entry.plannedFiber, target: HealthTargets.fiber, unit: "g")
            TargetProgressRow(title: "Saturated Fat", value: entry.plannedSaturatedFat, target: HealthTargets.saturatedFat, unit: "g", isMaximum: true)
        }
        .padding(.vertical, 8)
    }

    private func mealText(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.caption.weight(.semibold))
                .frame(width: 48, alignment: .leading)
            Text(value.isEmpty ? "Not set" : value)
                .font(.caption)
                .foregroundStyle(value.isEmpty ? .secondary : .primary)
        }
    }
}

private struct BuildMealPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let recipes: [Recipe]
    let existingEntries: [MealPlanEntry]

    @State private var startDate = Date()
    @State private var weekCount = 1
    @State private var mealSlot: WeeklyPlanMealSlot = .dinner
    @State private var themeFilter: String?
    @State private var searchText = ""
    @State private var selectedRecipeIDs: Set<UUID> = []
    @State private var validationMessage: String?

    private var dayCount: Int {
        weekCount * 7
    }

    private var selectedRecipes: [Recipe] {
        availableRecipes
            .filter { selectedRecipeIDs.contains($0.id) }
            .sortedForPlanning
    }

    private var availableRecipes: [Recipe] {
        recipes.filter { recipe in
            switch mealSlot {
            case .lunch, .dinner, .lunchAndDinner:
                recipe.recipeType != .snack
            case .snacks:
                recipe.recipeType == .snack
            case .fullDay:
                true
            }
        }
    }

    private var filteredRecipes: [Recipe] {
        availableRecipes.filter { recipe in
            let search = searchText.trimmed
            let matchesSearch = search.isEmpty ||
                recipe.name.localizedCaseInsensitiveContains(search) ||
                recipe.themeName.localizedCaseInsensitiveContains(search) ||
                recipe.ingredientsText.localizedCaseInsensitiveContains(search)
            let matchesTheme = themeFilter == nil || recipe.themeName.caseInsensitiveCompare(themeFilter ?? "") == .orderedSame
            return matchesSearch && matchesTheme
        }
    }

    private var sections: [PlannerRecipeSection] {
        let grouped = Dictionary(grouping: filteredRecipes, by: \.themeName)
        let known = Set(RecipeTheme.all.map(\.name))
        let ordered = RecipeTheme.all.compactMap { theme -> PlannerRecipeSection? in
            guard let recipes = grouped[theme.name]?.sortedForPlanning, !recipes.isEmpty else { return nil }
            return PlannerRecipeSection(theme: theme, recipes: recipes)
        }
        let custom = grouped.keys
            .filter { !known.contains($0) }
            .sorted()
            .compactMap { name -> PlannerRecipeSection? in
                guard let recipes = grouped[name]?.sortedForPlanning, !recipes.isEmpty else { return nil }
                return PlannerRecipeSection(theme: RecipeTheme.theme(named: name), recipes: recipes)
            }
        return ordered + custom
    }

    private var selectedMeals: [Recipe] {
        selectedRecipes.filter { $0.recipeType != .snack }
    }

    private var selectedSnacks: [Recipe] {
        selectedRecipes.filter { $0.recipeType == .snack }
    }

    var body: some View {
        Form {
            Section("When") {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                Stepper(value: $weekCount, in: 1...4) {
                    Text(weekCount == 1 ? "1 week" : "\(weekCount) weeks")
                }
                Picker("Fill", selection: $mealSlot) {
                    ForEach(WeeklyPlanMealSlot.allCases) { slot in
                        Text(slot.title).tag(slot)
                    }
                }
                .onChange(of: mealSlot) {
                    selectedRecipeIDs.removeAll()
                    themeFilter = nil
                }
            }

            Section("Choose Catalog Items") {
                Picker("Theme", selection: $themeFilter) {
                    Text("All themes").tag(nil as String?)
                    ForEach(RecipeTheme.all) { theme in
                        Text(theme.name).tag(Optional(theme.name))
                    }
                }

                HStack {
                    Label("\(selectedRecipes.count) selected", systemImage: "checkmark.square.fill")
                    Spacer()
                    Button("Clear") {
                        selectedRecipeIDs.removeAll()
                    }
                    .disabled(selectedRecipeIDs.isEmpty)
                }

                HStack {
                    Button("Select Visible") {
                        selectedRecipeIDs.formUnion(filteredRecipes.map(\.id))
                    }
                    .disabled(filteredRecipes.isEmpty)

                    Spacer()

                    Text("\(dayCount * mealSlot.slotsPerDay) slots")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }

            if availableRecipes.isEmpty {
                Section {
                    EmptyStateView(title: "No Catalog Items", message: "Load starter data or add catalog items before planning.", systemImage: "book.closed")
                }
            } else if sections.isEmpty {
                Section {
                    EmptyStateView(title: "No Matches", message: "Try a different search or theme.", systemImage: "magnifyingglass")
                }
            } else {
                ForEach(sections) { section in
                    Section(section.theme.name) {
                        ForEach(section.recipes) { recipe in
                            PlannerRecipeRow(recipe: recipe, isSelected: selectedRecipeIDs.contains(recipe.id)) {
                                toggle(recipe)
                            }
                        }
                    }
                }
            }

            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Choose Meals")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search recipes")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add to Plan") {
                    save()
                }
                .disabled(selectedRecipeIDs.isEmpty)
            }
        }
    }

    private func toggle(_ recipe: Recipe) {
        if selectedRecipeIDs.contains(recipe.id) {
            selectedRecipeIDs.remove(recipe.id)
        } else {
            selectedRecipeIDs.insert(recipe.id)
        }
    }

    private func save() {
        let pickedRecipes = selectedRecipes
        guard !pickedRecipes.isEmpty else {
            validationMessage = "Select at least one catalog item."
            return
        }

        guard !mealSlot.needsMealCatalog || !selectedMeals.isEmpty else {
            validationMessage = "Select at least one lunch or dinner meal."
            return
        }

        guard !mealSlot.includesSnacks || !selectedSnacks.isEmpty else {
            validationMessage = "Select at least one snack."
            return
        }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        var mealIndex = 0
        var snackIndex = 0

        for offset in 0..<dayCount {
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { continue }

            let existing = existingEntry(on: date)
            let target = existing ?? MealPlanEntry(date: date)
            target.date = date
            target.isDone = false
            target.isStarterData = false

            var plannedRecipes: [Recipe] = []

            if mealSlot.includesLunch {
                let recipe = selectedMeals[mealIndex % selectedMeals.count]
                mealIndex += 1
                target.lunchName = recipe.name
                plannedRecipes.append(recipe)
            }

            if mealSlot.includesDinner {
                let recipe = selectedMeals[mealIndex % selectedMeals.count]
                mealIndex += 1
                target.dinnerName = recipe.name
                plannedRecipes.append(recipe)
            }

            if mealSlot.includesSnacks {
                let firstSnack = selectedSnacks[snackIndex % selectedSnacks.count]
                snackIndex += 1
                let secondSnack = selectedSnacks[snackIndex % selectedSnacks.count]
                snackIndex += 1
                target.snackOne = firstSnack.name
                target.snackTwo = secondSnack.name
                plannedRecipes.append(firstSnack)
                plannedRecipes.append(secondSnack)
            }

            if target.sideName.trimmed.isEmpty {
                target.sideName = "Freezer side or fresh greens"
            }

            target.plannedCalories = plannedRecipes.reduce(0) { $0 + $1.caloriesPerServing }
            target.plannedProtein = plannedRecipes.reduce(0) { $0 + $1.proteinPerServing }
            target.plannedFiber = plannedRecipes.reduce(0) { $0 + $1.fiberPerServing }
            target.plannedSaturatedFat = plannedRecipes.reduce(0) { $0 + $1.saturatedFatPerServing }
            let durationText = weekCount == 1 ? "1 week" : "\(weekCount) weeks"
            target.notes = "Built from selected recipes for \(durationText)."

            if existing == nil {
                modelContext.insert(target)
            }
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            validationMessage = "Could not save plan: \(error.localizedDescription)"
        }
    }

    private func existingEntry(on date: Date) -> MealPlanEntry? {
        existingEntries.first { entry in
            Calendar.current.isDate(entry.date, inSameDayAs: date)
        }
    }
}

private struct PlannerRecipeRow: View {
    let recipe: Recipe
    let isSelected: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.mealAccent : Color.secondary)

                VStack(alignment: .leading, spacing: 5) {
                    Text(recipe.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        PlannerMetric(value: "\(Int(recipe.proteinPerServing))g", title: "protein")
                        PlannerMetric(value: "\(Int(recipe.fiberPerServing))g", title: "fiber")
                        PlannerMetric(value: "\(recipe.prepMinutes ?? 20)m", title: "prep")
                    }
                }

                Spacer()

                Text(recipe.theme.shortName)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(recipe.theme.color)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(recipe.theme.color.opacity(0.12), in: Capsule())
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct PlannerMetric: View {
    let value: String
    let title: String

    var body: some View {
        Text("\(value) \(title)")
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}

private struct PlannerRecipeSection: Identifiable {
    let theme: RecipeTheme
    let recipes: [Recipe]

    var id: String { theme.id }
}

private struct ShoppingCartView: View {
    @Environment(\.dismiss) private var dismiss

    let recipes: [Recipe]
    let mealPlanEntries: [MealPlanEntry]

    @State private var range: ShoppingCartRange = .twoWeeks
    @State private var checkedItemIDs: Set<String> = []

    private var plannedEntries: [MealPlanEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endDate = range.endDate(from: today, calendar: calendar)

        return mealPlanEntries
            .filter { entry in
                let day = calendar.startOfDay(for: entry.date)
                guard day >= today, !entry.isDone else { return false }
                guard let endDate else { return true }
                return day <= endDate
            }
            .sorted { $0.date < $1.date }
    }

    private var recipeByName: [String: Recipe] {
        Dictionary(grouping: recipes, by: { $0.name.shoppingKey })
            .compactMapValues { $0.sortedForPlanning.first }
    }

    private var plannedRecipeNames: [String] {
        plannedEntries.flatMap(\.cartRecipeNames)
    }

    private var plannedRecipes: [Recipe] {
        plannedRecipeNames.compactMap { recipeByName[$0.shoppingKey] }
    }

    private var plannedRecipeCounts: [ShoppingCartItem] {
        makeItems(from: plannedRecipes.map(\.name))
    }

    private var shoppingItems: [ShoppingCartItem] {
        makeItems(from: plannedRecipes.flatMap(\.shoppingIngredientLines))
    }

    private var unmatchedPlanItems: [ShoppingCartItem] {
        let ignoredKeys = Set(["Freezer side or fresh greens"].map(\.shoppingKey))
        let unmatched = plannedRecipeNames.filter { name in
            !ignoredKeys.contains(name.shoppingKey) && recipeByName[name.shoppingKey] == nil
        }
        return makeItems(from: unmatched)
    }

    var body: some View {
        Form {
            Section("Range") {
                Picker("Cart", selection: $range) {
                    ForEach(ShoppingCartRange.allCases) { range in
                        Text(range.title).tag(range)
                    }
                }
            }

            Section {
                if shoppingItems.isEmpty {
                    EmptyStateView(
                        title: "Nothing To Buy Yet",
                        message: "Choose catalog meals or snacks for upcoming days, then your ingredients will appear here.",
                        systemImage: "cart"
                    )
                } else {
                    ForEach(shoppingItems) { item in
                        ShoppingCartItemRow(item: item, isChecked: checkedItemIDs.contains(item.id)) {
                            toggle(item)
                        }
                    }
                }
            } header: {
                Text("Shopping Cart")
            } footer: {
                if !plannedRecipes.isEmpty {
                    Text("\(plannedRecipes.count) planned catalog items matched for this cart.")
                }
            }

            if !plannedRecipeCounts.isEmpty {
                Section("Planned Catalog Items") {
                    ForEach(plannedRecipeCounts) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            if item.count > 1 {
                                Text("\(item.count)x")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if !unmatchedPlanItems.isEmpty {
                Section("Custom Plan Items") {
                    ForEach(unmatchedPlanItems) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            if item.count > 1 {
                                Text("\(item.count)x")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Shopping Cart")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Clear") {
                    checkedItemIDs.removeAll()
                }
                .disabled(checkedItemIDs.isEmpty)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }

    private func toggle(_ item: ShoppingCartItem) {
        if checkedItemIDs.contains(item.id) {
            checkedItemIDs.remove(item.id)
        } else {
            checkedItemIDs.insert(item.id)
        }
    }

    private func makeItems(from names: [String]) -> [ShoppingCartItem] {
        let cleanNames = names
            .map(\.trimmed)
            .filter { !$0.isEmpty }
        let grouped = Dictionary(grouping: cleanNames, by: \.shoppingKey)

        return grouped.compactMap { key, values in
            guard let name = values.first else { return nil }
            return ShoppingCartItem(id: key, name: name, count: values.count)
        }
        .sorted { lhs, rhs in
            lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
}

private struct ShoppingCartItemRow: View {
    let item: ShoppingCartItem
    let isChecked: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isChecked ? Color.mealAccent : Color.secondary)

                Text(item.name)
                    .font(.subheadline)
                    .foregroundStyle(isChecked ? .secondary : .primary)
                    .strikethrough(isChecked)

                Spacer()

                if item.count > 1 {
                    Text("\(item.count)x")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.mealAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.mealAccent.opacity(0.12), in: Capsule())
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct ShoppingCartItem: Identifiable {
    let id: String
    let name: String
    let count: Int
}

private enum ShoppingCartRange: String, CaseIterable, Identifiable {
    case oneWeek
    case twoWeeks
    case allUpcoming

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneWeek:
            "Next 7 Days"
        case .twoWeeks:
            "Next 14 Days"
        case .allUpcoming:
            "All Upcoming"
        }
    }

    func endDate(from startDate: Date, calendar: Calendar) -> Date? {
        switch self {
        case .oneWeek:
            calendar.date(byAdding: .day, value: 6, to: startDate)
        case .twoWeeks:
            calendar.date(byAdding: .day, value: 13, to: startDate)
        case .allUpcoming:
            nil
        }
    }
}

private enum WeeklyPlanMealSlot: String, CaseIterable, Identifiable, Hashable {
    case lunch
    case dinner
    case snacks
    case lunchAndDinner
    case fullDay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lunch:
            "Lunches"
        case .dinner:
            "Dinners"
        case .snacks:
            "Snacks"
        case .lunchAndDinner:
            "Lunches + Dinners"
        case .fullDay:
            "Full Day"
        }
    }

    var includesLunch: Bool {
        self == .lunch || self == .lunchAndDinner || self == .fullDay
    }

    var includesDinner: Bool {
        self == .dinner || self == .lunchAndDinner || self == .fullDay
    }

    var includesSnacks: Bool {
        self == .snacks || self == .fullDay
    }

    var needsMealCatalog: Bool {
        includesLunch || includesDinner
    }

    var slotsPerDay: Int {
        switch self {
        case .lunch, .dinner:
            1
        case .snacks:
            2
        case .lunchAndDinner:
            2
        case .fullDay:
            4
        }
    }
}

private enum MealPlanSheet: Identifiable {
    case add
    case buildWeek
    case edit(MealPlanEntry)
    case shoppingCart

    var id: String {
        switch self {
        case .add:
            "add"
        case .buildWeek:
            "buildWeek"
        case .edit(let entry):
            entry.id.uuidString
        case .shoppingCart:
            "shoppingCart"
        }
    }
}

private extension Array where Element == Recipe {
    var sortedForPlanning: [Recipe] {
        sorted { lhs, rhs in
            lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
}

private extension MealPlanEntry {
    var cartRecipeNames: [String] {
        [lunchName, dinnerName, sideName, snackOne, snackTwo]
            .map(\.trimmed)
            .filter { !$0.isEmpty }
    }
}

private extension Recipe {
    var shoppingIngredientLines: [String] {
        ingredientsText
            .split(separator: "\n")
            .map { String($0).shoppingIngredientLine }
            .filter { !$0.isEmpty }
    }
}

private extension String {
    var shoppingKey: String {
        trimmed.lowercased()
    }

    var shoppingIngredientLine: String {
        let prefixes = [
            "Base:",
            "Protein:",
            "Protein source:",
            "Vegetables:",
            "Sauce or seasoning:",
            "Fresh finish:",
            "Optional:"
        ]
        var line = trimmed
        for prefix in prefixes where line.lowercased().hasPrefix(prefix.lowercased()) {
            line = String(line.dropFirst(prefix.count)).trimmed
            break
        }
        return line
    }
}

#if DEBUG
@MainActor
private struct MealPlanView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MealPlanView()
        }
        .modelContainer(PreviewData.container)
    }
}
#endif
