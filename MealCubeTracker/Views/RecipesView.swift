import SwiftData
import SwiftUI

struct RecipesView: View {
    @Query(sort: \Recipe.dateModified, order: .reverse) private var recipes: [Recipe]

    @State private var searchText = ""
    @State private var statusFilter: RecipeStatus?
    @State private var typeFilter: RecipeType?
    @State private var cubeFilter: CubeSize?
    @State private var vegetarianOnly = false
    @State private var highProteinOnly = false
    @State private var highFiberOnly = false
    @State private var showingAddRecipe = false

    init() {}

    private var filteredRecipes: [Recipe] {
        recipes.filter { recipe in
            let matchesSearch = searchText.trimmed.isEmpty ||
                recipe.name.localizedCaseInsensitiveContains(searchText) ||
                recipe.ingredientsText.localizedCaseInsensitiveContains(searchText) ||
                recipe.notes.localizedCaseInsensitiveContains(searchText)
            let matchesStatus = statusFilter == nil || recipe.status == statusFilter
            let matchesType = typeFilter == nil || recipe.recipeType == typeFilter
            let matchesCube = cubeFilter == nil || recipe.cubeSize == cubeFilter
            let matchesVegetarian = !vegetarianOnly || recipe.isVegetarian
            let matchesProtein = !highProteinOnly || recipe.proteinPerServing >= 35
            let matchesFiber = !highFiberOnly || recipe.fiberPerServing >= 8
            return matchesSearch && matchesStatus && matchesType && matchesCube && matchesVegetarian && matchesProtein && matchesFiber
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            RecipeFilterBar(
                statusFilter: $statusFilter,
                typeFilter: $typeFilter,
                cubeFilter: $cubeFilter,
                vegetarianOnly: $vegetarianOnly,
                highProteinOnly: $highProteinOnly,
                highFiberOnly: $highFiberOnly
            )
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.background)

            List {
                if filteredRecipes.isEmpty {
                    EmptyStateView(title: "No Recipes", message: "Try a different filter, add a recipe, or load starter data.", systemImage: "book.closed")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredRecipes) { recipe in
                        NavigationLink {
                            RecipeDetailView(recipe: recipe)
                        } label: {
                            RecipeRow(recipe: recipe)
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Recipes")
        .searchable(text: $searchText, prompt: "Search recipes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddRecipe = true
                } label: {
                    Image(systemName: "plus")
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
}

private struct RecipeFilterBar: View {
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

private struct FilterChip: View {
    let title: String
    let isActive: Bool

    var body: some View {
        Label(title, systemImage: "line.3.horizontal.decrease.circle")
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(isActive ? .white : .primary)
            .background(isActive ? Color.mealAccent : Color(.secondarySystemBackground), in: Capsule())
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
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(isOn ? .white : .primary)
                .background(isOn ? Color.mealAccent : Color(.secondarySystemBackground), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct RecipeRow: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.headline)
                    HStack {
                        Badge(text: recipe.status.title)
                        Badge(text: recipe.recipeType.title, color: .secondary)
                    }
                }
                Spacer()
                if recipe.isVegetarian {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(Color.mealAccent)
                }
            }

            HStack(spacing: 8) {
                Label(recipe.cubeSize.title, systemImage: "cube.fill")
                Text("\(recipe.cubeYield.compactString) cubes")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Text("\(recipe.caloriesPerServing.compactString) cal")
                Text("\(recipe.proteinPerServing.compactString)g protein")
                Text("\(recipe.fiberPerServing.compactString)g fiber")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
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
