import SwiftData
import SwiftUI

struct RecipeFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let recipe: Recipe?

    @State private var name: String
    @State private var recipeType: RecipeType
    @State private var status: RecipeStatus
    @State private var cubeSize: CubeSize
    @State private var cubeYield: String
    @State private var servings: String
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    @State private var saturatedFat: String
    @State private var fiber: String
    @State private var sodium: String
    @State private var ingredientsText: String
    @State private var instructionsText: String
    @State private var notes: String
    @State private var isVegetarian: Bool
    @State private var validationMessage: String?

    init(recipe: Recipe? = nil) {
        self.recipe = recipe
        _name = State(initialValue: recipe?.name ?? "")
        _recipeType = State(initialValue: recipe?.recipeType ?? .dinner)
        _status = State(initialValue: recipe?.status ?? .wantToTry)
        _cubeSize = State(initialValue: recipe?.cubeSize ?? .twoCup)
        _cubeYield = State(initialValue: (recipe?.cubeYield ?? 0).compactString)
        _servings = State(initialValue: (recipe?.servings ?? 1).compactString)
        _calories = State(initialValue: (recipe?.caloriesPerServing ?? 0).compactString)
        _protein = State(initialValue: (recipe?.proteinPerServing ?? 0).compactString)
        _carbs = State(initialValue: (recipe?.carbsPerServing ?? 0).compactString)
        _fat = State(initialValue: (recipe?.fatPerServing ?? 0).compactString)
        _saturatedFat = State(initialValue: (recipe?.saturatedFatPerServing ?? 0).compactString)
        _fiber = State(initialValue: (recipe?.fiberPerServing ?? 0).compactString)
        _sodium = State(initialValue: (recipe?.sodiumPerServing ?? 0).compactString)
        _ingredientsText = State(initialValue: recipe?.ingredientsText ?? "")
        _instructionsText = State(initialValue: recipe?.instructionsText ?? "")
        _notes = State(initialValue: recipe?.notes ?? "")
        _isVegetarian = State(initialValue: recipe?.isVegetarian ?? false)
    }

    var body: some View {
        Form {
            Section("Basics") {
                TextField("Recipe name", text: $name)
                Picker("Type", selection: $recipeType) {
                    ForEach(RecipeType.allCases) { type in
                        Text(type.title).tag(type)
                    }
                }
                Picker("Status", selection: $status) {
                    ForEach(RecipeStatus.allCases) { status in
                        Text(status.title).tag(status)
                    }
                }
                Toggle("Vegetarian", isOn: $isVegetarian)
            }

            Section("Cube Plan") {
                Picker("Cube Size", selection: $cubeSize) {
                    ForEach(CubeSize.allCases) { cubeSize in
                        Text(cubeSize.title).tag(cubeSize)
                    }
                }
                DecimalTextField(title: "Cube Yield", text: $cubeYield)
                DecimalTextField(title: "Servings", text: $servings)
            }

            Section("Macros Per Serving") {
                DecimalTextField(title: "Calories", text: $calories)
                DecimalTextField(title: "Protein (g)", text: $protein)
                DecimalTextField(title: "Carbs (g)", text: $carbs)
                DecimalTextField(title: "Fat (g)", text: $fat)
                DecimalTextField(title: "Saturated Fat (g)", text: $saturatedFat)
                DecimalTextField(title: "Fiber (g)", text: $fiber)
                DecimalTextField(title: "Sodium (mg)", text: $sodium)
            }

            Section("Ingredients") {
                TextEditor(text: $ingredientsText)
                    .frame(minHeight: 140)
            }

            Section("Instructions") {
                TextEditor(text: $instructionsText)
                    .frame(minHeight: 140)
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 90)
            }

            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(recipe == nil ? "Add Recipe" : "Edit Recipe")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
            }
        }
    }

    private func save() {
        guard !name.trimmed.isEmpty else {
            validationMessage = "Recipe name is required."
            return
        }

        guard let cubeYieldValue = cubeYield.doubleValue,
              let servingsValue = servings.doubleValue,
              let caloriesValue = calories.doubleValue,
              let proteinValue = protein.doubleValue,
              let carbsValue = carbs.doubleValue,
              let fatValue = fat.doubleValue,
              let saturatedFatValue = saturatedFat.doubleValue,
              let fiberValue = fiber.doubleValue,
              let sodiumValue = sodium.doubleValue else {
            validationMessage = "Macro and cube fields must be numbers."
            return
        }

        guard servingsValue > 0 else {
            validationMessage = "Servings must be greater than zero."
            return
        }

        let now = Date()
        let target = recipe ?? Recipe(name: name.trimmed, recipeType: recipeType)
        target.name = name.trimmed
        target.recipeType = recipeType
        target.status = status
        target.cubeSize = cubeSize
        target.cubeYield = max(0, cubeYieldValue)
        target.servings = servingsValue
        target.caloriesPerServing = max(0, caloriesValue)
        target.proteinPerServing = max(0, proteinValue)
        target.carbsPerServing = max(0, carbsValue)
        target.fatPerServing = max(0, fatValue)
        target.saturatedFatPerServing = max(0, saturatedFatValue)
        target.fiberPerServing = max(0, fiberValue)
        target.sodiumPerServing = max(0, sodiumValue)
        target.ingredientsText = ingredientsText.trimmed
        target.instructionsText = instructionsText.trimmed
        target.notes = notes.trimmed
        target.isVegetarian = isVegetarian
        target.dateModified = now

        if recipe == nil {
            target.dateCreated = now
            modelContext.insert(target)
        }

        try? modelContext.save()
        dismiss()
    }
}

#if DEBUG
@MainActor
private struct RecipeFormView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RecipeFormView()
        }
        .modelContainer(PreviewData.container)
    }
}
#endif
