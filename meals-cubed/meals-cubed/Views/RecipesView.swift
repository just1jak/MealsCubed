import SwiftData
import SwiftUI

struct RecipesView: View {
    @Query(sort: \Recipe.dateModified, order: .reverse) private var recipes: [Recipe]

    @State private var searchText = ""
    @State private var statusFilter: RecipeStatus?
    @State private var typeFilter: RecipeType?
    @State private var cubeFilter: CubeSize?
    @State private var themeFilter: String?
    @State private var vegetarianOnly = false
    @State private var highProteinOnly = false
    @State private var highFiberOnly = false
    @State private var showingAddRecipe = false

    init() {}

    private var bowlRecipes: [Recipe] {
        recipes.filter(\.isBowlIdea)
    }

    private var snackRecipes: [Recipe] {
        recipes.filter { $0.recipeType == .snack }
    }

    private var themeCounts: [String: Int] {
        Dictionary(grouping: recipes, by: \.themeName)
            .mapValues(\.count)
    }

    private var filteredRecipes: [Recipe] {
        recipes.filter { recipe in
            let trimmedSearch = searchText.trimmed
            let matchesSearch = trimmedSearch.isEmpty ||
                recipe.name.localizedCaseInsensitiveContains(trimmedSearch) ||
                recipe.ingredientsText.localizedCaseInsensitiveContains(trimmedSearch) ||
                recipe.notes.localizedCaseInsensitiveContains(trimmedSearch) ||
                recipe.themeName.localizedCaseInsensitiveContains(trimmedSearch)
            let matchesStatus = statusFilter == nil || recipe.status == statusFilter
            let matchesType = typeFilter == nil || recipe.recipeType == typeFilter
            let matchesCube = cubeFilter == nil || recipe.cubeSize == cubeFilter
            let matchesTheme = themeFilter == nil || recipe.themeName.caseInsensitiveCompare(themeFilter ?? "") == .orderedSame
            let matchesVegetarian = !vegetarianOnly || recipe.isVegetarian
            let matchesProtein = !highProteinOnly || recipe.proteinPerServing >= 35
            let matchesFiber = !highFiberOnly || recipe.fiberPerServing >= 8
            return matchesSearch && matchesStatus && matchesType && matchesCube && matchesTheme && matchesVegetarian && matchesProtein && matchesFiber
        }
    }

    private var sections: [RecipeThemeSection] {
        let grouped = Dictionary(grouping: filteredRecipes, by: \.themeName)
        let ordered = RecipeTheme.all.compactMap { theme -> RecipeThemeSection? in
            guard let recipes = grouped[theme.name], !recipes.isEmpty else { return nil }
            return RecipeThemeSection(theme: theme, recipes: recipes.sortedByName)
        }

        let knownNames = Set(RecipeTheme.all.map(\.name))
        let custom = grouped.keys
            .filter { !knownNames.contains($0) }
            .sorted()
            .compactMap { name -> RecipeThemeSection? in
                guard let recipes = grouped[name], !recipes.isEmpty else { return nil }
                return RecipeThemeSection(theme: RecipeTheme.theme(named: name), recipes: recipes.sortedByName)
            }

        return ordered + custom
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18, pinnedViews: []) {
                libraryHeader

                RecipeThemeDeck(
                    themeFilter: $themeFilter,
                    themeCounts: themeCounts,
                    totalCount: recipes.count
                )

                RecipeFilterDeck(
                    statusFilter: $statusFilter,
                    typeFilter: $typeFilter,
                    cubeFilter: $cubeFilter,
                    vegetarianOnly: $vegetarianOnly,
                    highProteinOnly: $highProteinOnly,
                    highFiberOnly: $highFiberOnly
                )

                if sections.isEmpty {
                    EmptyStateView(title: "No Recipes", message: "Try a different filter, add a recipe, or load starter data.", systemImage: "book.closed")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.controlPanel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else {
                    ForEach(sections) { section in
                        RecipeThemeSectionView(section: section)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 110)
        }
        .background(Color.controlInk.ignoresSafeArea())
        .navigationTitle("Recipes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.controlInk, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .searchable(text: $searchText, prompt: "Search bowls, themes, ingredients")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddRecipe = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.controlLime)
                }
                .accessibilityLabel("Add Recipe")
            }
        }
        .sheet(isPresented: $showingAddRecipe) {
            NavigationStack {
                RecipeFormView()
            }
        }
    }

    private var libraryHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Global Bowl Atlas", systemImage: "map.fill")
                .font(.caption.weight(.black))
                .foregroundStyle(Color.controlPaprika)
                .textCase(.uppercase)

            Text("Bowls Around the World")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(Color.controlCream)
                .lineLimit(2)
                .minimumScaleFactor(0.76)

            Text("Low-effort freezer bowls and healthy snacks organized by theme, protein, cube size, and macro targets.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.controlCream.opacity(0.7))

            HStack(spacing: 10) {
                LibraryStat(value: "\(bowlRecipes.count)", title: "bowl ideas", color: .controlLime)
                LibraryStat(value: "\(RecipeTheme.all.count)", title: "themes", color: .controlPaprika)
                LibraryStat(value: "\(snackRecipes.count)", title: "snacks", color: .controlSteel)
            }
            .padding(.top, 4)
        }
    }
}

private struct RecipeThemeSection: Identifiable {
    let theme: RecipeTheme
    let recipes: [Recipe]

    var id: String { theme.id }
}

private struct LibraryStat: View {
    let value: String
    let title: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.controlCream.opacity(0.58))
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.controlPanel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.controlLine, lineWidth: 1)
        )
    }
}

private struct RecipeThemeDeck: View {
    @Binding var themeFilter: String?
    let themeCounts: [String: Int]
    let totalCount: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ThemeChip(
                    title: "All",
                    count: totalCount,
                    symbolName: "sparkles",
                    color: .controlLime,
                    isActive: themeFilter == nil
                ) {
                    themeFilter = nil
                }

                ForEach(RecipeTheme.all) { theme in
                    ThemeChip(
                        title: theme.shortName,
                        count: themeCounts[theme.name, default: 0],
                        symbolName: theme.symbolName,
                        color: theme.color,
                        isActive: themeFilter == theme.name
                    ) {
                        themeFilter = theme.name
                    }
                }
            }
        }
    }
}

private struct RecipeFilterDeck: View {
    @Binding var statusFilter: RecipeStatus?
    @Binding var typeFilter: RecipeType?
    @Binding var cubeFilter: CubeSize?
    @Binding var vegetarianOnly: Bool
    @Binding var highProteinOnly: Bool
    @Binding var highFiberOnly: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Menu {
                    Button("Any Status") { statusFilter = nil }
                    ForEach(RecipeStatus.allCases) { status in
                        Button(status.title) { statusFilter = status }
                    }
                } label: {
                    FilterChip(title: statusFilter?.title ?? "Status", isActive: statusFilter != nil)
                }

                Menu {
                    Button("Any Type") { typeFilter = nil }
                    ForEach(RecipeType.allCases) { type in
                        Button(type.title) { typeFilter = type }
                    }
                } label: {
                    FilterChip(title: typeFilter?.title ?? "Type", isActive: typeFilter != nil)
                }

                Menu {
                    Button("Any Cube") { cubeFilter = nil }
                    ForEach(CubeSize.allCases) { cube in
                        Button(cube.title) { cubeFilter = cube }
                    }
                } label: {
                    FilterChip(title: cubeFilter?.title ?? "Cube", isActive: cubeFilter != nil)
                }

                ToggleChip(title: "Vegetarian", isOn: $vegetarianOnly)
                ToggleChip(title: "High Protein", isOn: $highProteinOnly)
                ToggleChip(title: "High Fiber", isOn: $highFiberOnly)
            }
        }
    }
}

private struct RecipeThemeSectionView: View {
    let section: RecipeThemeSection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: section.theme.symbolName)
                    .font(.headline.weight(.black))
                    .foregroundStyle(section.theme.color)
                    .frame(width: 34, height: 34)
                    .background(section.theme.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(section.theme.name)
                        .font(.title3.weight(.black))
                        .foregroundStyle(Color.controlCream)
                    Text("\(section.recipes.count) low-effort ideas")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.controlCream.opacity(0.55))
                        .textCase(.uppercase)
                }

                Spacer()
            }

            VStack(spacing: 12) {
                ForEach(section.recipes) { recipe in
                    NavigationLink {
                        RecipeDetailView(recipe: recipe)
                    } label: {
                        RecipeLibraryCard(recipe: recipe)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct RecipeLibraryCard: View {
    let recipe: Recipe

    private var theme: RecipeTheme {
        recipe.theme
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                CubeTrayDiagram(cubeSize: recipe.cubeSize, count: min(recipe.cubeYield, 6), tint: theme.color, compact: true)
                    .frame(width: 78)

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .top) {
                        Text(recipe.name)
                            .font(.headline.weight(.black))
                            .foregroundStyle(Color.controlCream)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.black))
                            .foregroundStyle(Color.controlCream.opacity(0.34))
                    }

                    Text(recipe.recipeSummary)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.controlCream.opacity(0.66))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        RecipeTinyPill(text: recipe.themeName, color: theme.color)
                        RecipeTinyPill(text: recipe.prepMinutes.map { "\($0) min" } ?? "Low Effort", color: .controlSteel)
                        if recipe.isVegetarian {
                            RecipeTinyPill(text: "Vegetarian", color: .controlLime)
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                RecipeMetric(title: "cal", value: recipe.caloriesPerServing.compactString)
                RecipeMetric(title: "protein", value: "\(recipe.proteinPerServing.compactString)g")
                RecipeMetric(title: "fiber", value: "\(recipe.fiberPerServing.compactString)g")
                RecipeMetric(title: "sat fat", value: "\(recipe.saturatedFatPerServing.compactString)g")
            }
        }
        .padding(12)
        .background(Color.controlPanel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(theme.color.opacity(0.55), lineWidth: 1)
        )
    }
}

private struct ThemeChip: View {
    let title: String
    let count: Int
    let symbolName: String
    let color: Color
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: symbolName)
                    .font(.caption.weight(.black))
                Text(title)
                    .font(.subheadline.weight(.black))
                    .lineLimit(1)
                Text("\(count)")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(isActive ? Color.controlCream : color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background((isActive ? Color.controlInk : color.opacity(0.18)), in: Capsule())
            }
            .foregroundStyle(isActive ? Color.controlInk : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isActive ? color : Color.controlPanel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(color.opacity(0.52), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct FilterChip: View {
    let title: String
    let isActive: Bool

    var body: some View {
        Label(title, systemImage: "line.3.horizontal.decrease.circle")
            .font(.subheadline.weight(.bold))
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .foregroundStyle(isActive ? Color.controlInk : Color.controlCream)
            .background(isActive ? Color.controlLime : Color.controlPanelSoft, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isActive ? Color.controlLime : Color.controlLine, lineWidth: 1)
            )
    }
}

private struct ToggleChip: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            Label(title, systemImage: isOn ? "checkmark.circle.fill" : "circle")
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .foregroundStyle(isOn ? Color.controlInk : Color.controlCream)
                .background(isOn ? Color.controlLime : Color.controlPanelSoft, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isOn ? Color.controlLime : Color.controlLine, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct RecipeTinyPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.black))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.14), in: Capsule())
    }
}

private struct RecipeMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.caption.weight(.black))
                .foregroundStyle(Color.controlCream)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.controlCream.opacity(0.52))
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.controlInk.opacity(0.36), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private extension Array where Element == Recipe {
    var sortedByName: [Recipe] {
        sorted { lhs, rhs in
            lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
}

#if DEBUG
@MainActor
private struct RecipesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RecipesView()
        }
        .modelContainer(PreviewData.container)
    }
}
#endif
