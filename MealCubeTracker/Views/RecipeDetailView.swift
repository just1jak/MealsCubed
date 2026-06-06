import SwiftData
import SwiftUI

struct RecipeDetailView: View {
    @Bindable var recipe: Recipe
    @Environment(\.modelContext) private var modelContext

    @State private var activeSheet: RecipeDetailSheet?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(recipe.name)
                                    .font(.title2.weight(.bold))
                                HStack {
                                    Badge(text: recipe.recipeType.title)
                                    Badge(text: recipe.cubeSize.title, color: .secondary)
                                    if recipe.isVegetarian {
                                        Badge(text: "Vegetarian")
                                    }
                                }
                            }
                            Spacer()
                        }

                        Picker("Status", selection: $recipe.status) {
                            ForEach(RecipeStatus.allCases) { status in
                                Text(status.title).tag(status)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: recipe.status) {
                            recipe.dateModified = Date()
                            try? modelContext.save()
                        }
                    }
                }

                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Macros Per Serving")
                            .font(.headline)
                        MacroGrid(
                            calories: recipe.caloriesPerServing,
                            protein: recipe.proteinPerServing,
                            carbs: recipe.carbsPerServing,
                            fat: recipe.fatPerServing,
                            fiber: recipe.fiberPerServing,
                            saturatedFat: recipe.saturatedFatPerServing,
                            sodium: recipe.sodiumPerServing
                        )
                    }
                }

                AppCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Cube Plan")
                            .font(.headline)
                        LabeledContent("Cube Size", value: recipe.cubeSize.title)
                        LabeledContent("Role", value: recipe.cubeSize.freezerRole)
                        LabeledContent("Yield", value: "\(recipe.cubeYield.compactString) cubes")
                        LabeledContent("Servings", value: recipe.servings.compactString)
                        Button {
                            activeSheet = .addToFreezer
                        } label: {
                            Label("Add to Freezer", systemImage: "snowflake")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.mealAccent)
                    }
                }

                textCard(title: "Ingredients", text: recipe.ingredientsText)
                textCard(title: "Instructions", text: recipe.instructionsText)
                if !recipe.notes.trimmed.isEmpty {
                    textCard(title: "Notes", text: recipe.notes)
                }
            }
            .padding()
        }
        .background(Color.mealBackground.ignoresSafeArea())
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    activeSheet = .edit
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            NavigationStack {
                switch sheet {
                case .edit:
                    RecipeFormView(recipe: recipe)
                case .addToFreezer:
                    FreezerFormView(recipe: recipe)
                }
            }
        }
    }

    private func textCard(title: String, text: String) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                Text(text.trimmed.isEmpty ? "Not set" : text)
                    .font(.body)
                    .foregroundStyle(text.trimmed.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private enum RecipeDetailSheet: Identifiable {
    case edit
    case addToFreezer

    var id: String {
        switch self {
        case .edit:
            "edit"
        case .addToFreezer:
            "addToFreezer"
        }
    }
}

#if DEBUG
@MainActor
private struct RecipeDetailPreviewHost: View {
    private let container = PreviewData.container

    var body: some View {
        let recipe = try! container.mainContext.fetch(FetchDescriptor<Recipe>()).first!
        NavigationStack {
            RecipeDetailView(recipe: recipe)
        }
        .modelContainer(container)
    }
}

@MainActor
private struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeDetailPreviewHost()
    }
}
#endif
