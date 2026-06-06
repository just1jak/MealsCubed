import Foundation
import SwiftData

@Model
final class Recipe: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var recipeType: RecipeType
    var status: RecipeStatus
    var cubeSize: CubeSize
    var cubeYield: Double
    var servings: Double
    var caloriesPerServing: Double
    var proteinPerServing: Double
    var carbsPerServing: Double
    var fatPerServing: Double
    var saturatedFatPerServing: Double
    var fiberPerServing: Double
    var sodiumPerServing: Double
    var ingredientsText: String
    var instructionsText: String
    var notes: String
    var isVegetarian: Bool
    var isStarterData: Bool
    var dateCreated: Date
    var dateModified: Date

    init(
        id: UUID = UUID(),
        name: String,
        recipeType: RecipeType,
        status: RecipeStatus = .wantToTry,
        cubeSize: CubeSize = .none,
        cubeYield: Double = 0,
        servings: Double = 1,
        caloriesPerServing: Double = 0,
        proteinPerServing: Double = 0,
        carbsPerServing: Double = 0,
        fatPerServing: Double = 0,
        saturatedFatPerServing: Double = 0,
        fiberPerServing: Double = 0,
        sodiumPerServing: Double = 0,
        ingredientsText: String = "",
        instructionsText: String = "",
        notes: String = "",
        isVegetarian: Bool = false,
        isStarterData: Bool = false,
        dateCreated: Date = Date(),
        dateModified: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.recipeType = recipeType
        self.status = status
        self.cubeSize = cubeSize
        self.cubeYield = cubeYield
        self.servings = servings
        self.caloriesPerServing = caloriesPerServing
        self.proteinPerServing = proteinPerServing
        self.carbsPerServing = carbsPerServing
        self.fatPerServing = fatPerServing
        self.saturatedFatPerServing = saturatedFatPerServing
        self.fiberPerServing = fiberPerServing
        self.sodiumPerServing = sodiumPerServing
        self.ingredientsText = ingredientsText
        self.instructionsText = instructionsText
        self.notes = notes
        self.isVegetarian = isVegetarian
        self.isStarterData = isStarterData
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }

    var caloriesPerCube: Double {
        guard cubeYield > 0 else { return caloriesPerServing }
        return caloriesPerServing * servings / cubeYield
    }

    var proteinPerCube: Double {
        guard cubeYield > 0 else { return proteinPerServing }
        return proteinPerServing * servings / cubeYield
    }

    var fiberPerCube: Double {
        guard cubeYield > 0 else { return fiberPerServing }
        return fiberPerServing * servings / cubeYield
    }

    var saturatedFatPerCube: Double {
        guard cubeYield > 0 else { return saturatedFatPerServing }
        return saturatedFatPerServing * servings / cubeYield
    }
}
