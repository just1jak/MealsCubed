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
            .filter { $0.isBowlIdea || $0.recipeType == .dinner || $0.recipeType == .lunch }
            .sortedForPlanning
    }

    private var shouldLoadCatalog: Bool {
        recipes.isEmpty || recipes.filter(\.isBowlIdea).count < 60
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
        recipes
            .filter { selectedRecipeIDs.contains($0.id) }
            .sortedForPlanning
    }

    private var filteredRecipes: [Recipe] {
        recipes.filter { recipe in
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
            }

            Section("Choose Catalog Meals") {
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

                    Text("\(dayCount * mealSlot.mealsPerDay) meal slots")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }

            if recipes.isEmpty {
                Section {
                    EmptyStateView(title: "No Recipes", message: "Load starter data or add recipes before building a week.", systemImage: "book.closed")
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
            validationMessage = "Select at least one recipe."
            return
        }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        var recipeIndex = 0

        for offset in 0..<dayCount {
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { continue }

            let existing = existingEntry(on: date)
            let target = existing ?? MealPlanEntry(date: date)
            target.date = date
            target.isDone = false
            target.isStarterData = false

            var plannedRecipes: [Recipe] = []

            if mealSlot.includesLunch {
                let recipe = pickedRecipes[recipeIndex % pickedRecipes.count]
                recipeIndex += 1
                target.lunchName = recipe.name
                plannedRecipes.append(recipe)
            }

            if mealSlot.includesDinner {
                let recipe = pickedRecipes[recipeIndex % pickedRecipes.count]
                recipeIndex += 1
                target.dinnerName = recipe.name
                plannedRecipes.append(recipe)
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

private enum WeeklyPlanMealSlot: String, CaseIterable, Identifiable, Hashable {
    case lunch
    case dinner
    case lunchAndDinner

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lunch:
            "Lunches"
        case .dinner:
            "Dinners"
        case .lunchAndDinner:
            "Lunches + Dinners"
        }
    }

    var includesLunch: Bool {
        self == .lunch || self == .lunchAndDinner
    }

    var includesDinner: Bool {
        self == .dinner || self == .lunchAndDinner
    }

    var mealsPerDay: Int {
        switch self {
        case .lunch, .dinner:
            1
        case .lunchAndDinner:
            2
        }
    }
}

private enum MealPlanSheet: Identifiable {
    case add
    case buildWeek
    case edit(MealPlanEntry)

    var id: String {
        switch self {
        case .add:
            "add"
        case .buildWeek:
            "buildWeek"
        case .edit(let entry):
            entry.id.uuidString
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
