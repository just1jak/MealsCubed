import Foundation
import SwiftData

enum HealthTargets {
    static let calories = 2_000.0
    static let protein = 150.0
    static let fiber = 30.0
    static let saturatedFat = 13.0
}

@MainActor
enum StarterData {
    static func load(into context: ModelContext) throws {
        try seedFoods(into: context)
        try seedRecipes(into: context)
        try seedFreezerItems(into: context)
        try seedMealPlan(into: context)
        try context.save()
    }

    static func reset(in context: ModelContext) throws {
        for entry in try context.fetch(FetchDescriptor<MealPlanEntry>()).filter(\.isStarterData) {
            context.delete(entry)
        }
        for item in try context.fetch(FetchDescriptor<FreezerItem>()).filter(\.isStarterData) {
            context.delete(item)
        }
        for recipe in try context.fetch(FetchDescriptor<Recipe>()).filter(\.isStarterData) {
            context.delete(recipe)
        }
        for food in try context.fetch(FetchDescriptor<FoodItem>()).filter(\.isStarterData) {
            context.delete(food)
        }
        try context.save()
    }

    private static func seedFoods(into context: ModelContext) throws {
        let existingNames = Set(try context.fetch(FetchDescriptor<FoodItem>()).map { $0.name.seedKey })
        for seed in foodSeeds where !existingNames.contains(seed.name.seedKey) {
            context.insert(FoodItem(
                name: seed.name,
                category: seed.category,
                reason: seed.reason,
                isStarterData: true
            ))
        }
    }

    private static func seedRecipes(into context: ModelContext) throws {
        let existingNames = Set(try context.fetch(FetchDescriptor<Recipe>()).map { $0.name.seedKey })
        for seed in recipeSeeds where !existingNames.contains(seed.name.seedKey) {
            context.insert(Recipe(
                name: seed.name,
                recipeType: seed.recipeType,
                status: .wantToTry,
                cubeSize: seed.cubeSize,
                cubeYield: seed.cubeYield,
                servings: seed.servings,
                caloriesPerServing: seed.calories,
                proteinPerServing: seed.protein,
                carbsPerServing: seed.carbs,
                fatPerServing: seed.fat,
                saturatedFatPerServing: seed.saturatedFat,
                fiberPerServing: seed.fiber,
                sodiumPerServing: seed.sodium,
                ingredientsText: seed.ingredients,
                instructionsText: seed.instructions,
                notes: seed.notes,
                isVegetarian: seed.isVegetarian,
                isStarterData: true
            ))
        }
    }

    private static func seedFreezerItems(into context: ModelContext) throws {
        let existingItems = try context.fetch(FetchDescriptor<FreezerItem>())
        guard existingItems.isEmpty else { return }

        let made = Calendar.current.startOfDay(for: Date())
        let useBy = Calendar.current.date(byAdding: .month, value: 3, to: made) ?? made
        for seed in freezerSeeds {
            context.insert(FreezerItem(
                recipeName: seed.name,
                cubeSize: seed.cubeSize,
                cubesFrozen: seed.cubesFrozen,
                caloriesPerCube: seed.calories,
                proteinPerCube: seed.protein,
                fiberPerCube: seed.fiber,
                saturatedFatPerCube: seed.saturatedFat,
                dateMade: made,
                useByDate: useBy,
                notes: seed.notes,
                isStarterData: true
            ))
        }
    }

    private static func seedMealPlan(into context: ModelContext) throws {
        let existingEntries = try context.fetch(FetchDescriptor<MealPlanEntry>())
        guard existingEntries.isEmpty else { return }

        let today = Calendar.current.startOfDay(for: Date())
        for (offset, seed) in mealPlanSeeds.enumerated() {
            let date = Calendar.current.date(byAdding: .day, value: offset, to: today) ?? today
            context.insert(MealPlanEntry(
                date: date,
                lunchName: seed.lunch,
                dinnerName: seed.dinner,
                sideName: seed.side,
                snackOne: seed.snackOne,
                snackTwo: seed.snackTwo,
                plannedCalories: seed.calories,
                plannedProtein: seed.protein,
                plannedFiber: seed.fiber,
                plannedSaturatedFat: seed.saturatedFat,
                isStarterData: true
            ))
        }
    }
}

private struct FoodSeed {
    let name: String
    let category: FoodCategory
    let reason: String
}

private struct RecipeSeed {
    let name: String
    let recipeType: RecipeType
    let cubeSize: CubeSize
    let cubeYield: Double
    let servings: Double
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let saturatedFat: Double
    let fiber: Double
    let sodium: Double
    let ingredients: String
    let instructions: String
    let notes: String
    let isVegetarian: Bool
}

private struct FreezerSeed {
    let name: String
    let cubeSize: CubeSize
    let cubesFrozen: Double
    let calories: Double
    let protein: Double
    let fiber: Double
    let saturatedFat: Double
    let notes: String
}

private struct MealPlanSeed {
    let lunch: String
    let dinner: String
    let side: String
    let snackOne: String
    let snackTwo: String
    let calories: Double
    let protein: Double
    let fiber: Double
    let saturatedFat: Double
}

private let foodSeeds: [FoodSeed] = [
    .init(name: "Oats", category: .eatMore, reason: "Soluble fiber, LDL-friendly"),
    .init(name: "Barley", category: .eatMore, reason: "Soluble fiber, good freezer side"),
    .init(name: "Lentils", category: .eatMore, reason: "High fiber, plant protein, reheats well"),
    .init(name: "Beans", category: .eatMore, reason: "High fiber, LDL-friendly, freezer-friendly"),
    .init(name: "Chickpeas", category: .eatMore, reason: "Plant protein and fiber"),
    .init(name: "Tofu", category: .eatMore, reason: "Vegetarian protein, low saturated fat"),
    .init(name: "Edamame", category: .eatMore, reason: "High-protein vegetarian add-on"),
    .init(name: "Nonfat Greek yogurt", category: .eatMore, reason: "High protein, low saturated fat"),
    .init(name: "Chicken breast", category: .eatMore, reason: "Lean protein"),
    .init(name: "Lean ground turkey", category: .eatMore, reason: "High protein, lower saturated fat than fatty meats"),
    .init(name: "Berries", category: .eatMore, reason: "Fiber and lower glycemic fruit option"),
    .init(name: "Apples", category: .eatMore, reason: "Soluble fiber"),
    .init(name: "Leafy greens", category: .eatMore, reason: "Salad base and micronutrients"),
    .init(name: "Cabbage/slaw mix", category: .eatMore, reason: "Holds up better than delicate greens"),
    .init(name: "Bell peppers", category: .eatMore, reason: "Reheats well in stews/chili"),
    .init(name: "Zucchini", category: .eatMore, reason: "Good in saucy freezer meals"),
    .init(name: "Mushrooms", category: .eatMore, reason: "Good texture in bolognese/chili"),
    .init(name: "Sweet potatoes", category: .eatMore, reason: "Good 1-cup cube side"),
    .init(name: "Brown rice", category: .eatMore, reason: "Quality carb side"),
    .init(name: "Quinoa", category: .eatMore, reason: "Quality carb and some protein"),
    .init(name: "Olive oil", category: .eatMore, reason: "Unsaturated fat source"),
    .init(name: "Avocado", category: .eatMore, reason: "Unsaturated fat source, use fresh"),
    .init(name: "Butter", category: .limitAvoid, reason: "Saturated fat"),
    .init(name: "Cream", category: .limitAvoid, reason: "Saturated fat"),
    .init(name: "High-fat cheese", category: .limitAvoid, reason: "Saturated fat"),
    .init(name: "Whole milk", category: .limitAvoid, reason: "Saturated fat"),
    .init(name: "Fatty beef", category: .limitAvoid, reason: "Saturated fat"),
    .init(name: "Bacon", category: .limitAvoid, reason: "Processed/fatty meat"),
    .init(name: "Sausage", category: .limitAvoid, reason: "Processed/fatty meat"),
    .init(name: "Fried foods", category: .limitAvoid, reason: "Often high saturated fat/calories"),
    .init(name: "Pastries", category: .limitAvoid, reason: "Saturated fat/refined carbs"),
    .init(name: "Coconut oil", category: .limitAvoid, reason: "High saturated fat"),
    .init(name: "Sugary drinks", category: .limitAvoid, reason: "Poor for A1C/metabolic health"),
    .init(name: "Candy/desserts", category: .limitAvoid, reason: "Added sugar"),
    .init(name: "White bread", category: .limitAvoid, reason: "Low fiber refined carb"),
    .init(name: "Large portions of white rice/pasta", category: .limitAvoid, reason: "Easier to overshoot carbs/calories")
]

private let recipeSeeds: [RecipeSeed] = [
    .init(
        name: "Turkey & Lentil Chili",
        recipeType: .dinner,
        cubeSize: .twoCup,
        cubeYield: 8,
        servings: 8,
        calories: 650,
        protein: 55,
        carbs: 65,
        fat: 14,
        saturatedFat: 3,
        fiber: 18,
        sodium: 0,
        ingredients: """
        2.5 lb lean ground turkey, preferably 93-99% lean
        2 cups dry brown or green lentils
        2 cans black beans, drained
        2 cans kidney or pinto beans, drained
        3 large 28 oz cans crushed tomatoes
        2 onions, diced
        3 bell peppers, diced
        2 zucchini, diced
        Chili powder
        Cumin
        Smoked paprika
        Garlic
        Oregano
        Optional: 2 cups frozen corn
        """,
        instructions: """
        1. Brown turkey in a large pot.
        2. Add onions, peppers, zucchini, garlic, and spices.
        3. Add lentils, beans, and crushed tomatoes.
        4. Simmer until lentils are tender.
        5. Portion into 8 two-cup freezer cubes.
        """,
        notes: "Good LDL-friendly high-fiber main. Serve with 1 cup quinoa or brown rice if more calories are needed.",
        isVegetarian: false
    ),
    .init(
        name: "Chicken White Bean Verde Stew",
        recipeType: .dinner,
        cubeSize: .twoCup,
        cubeYield: 8,
        servings: 8,
        calories: 620,
        protein: 60,
        carbs: 45,
        fat: 10,
        saturatedFat: 2,
        fiber: 12,
        sodium: 0,
        ingredients: """
        3 lb chicken breast
        3 cans cannellini or great northern beans, drained
        2 jars salsa verde, about 16 oz each
        1 large onion
        2 bell peppers
        2 zucchini
        1 bag frozen spinach or kale
        4 cups low-sodium chicken broth
        Cumin
        Garlic
        Oregano
        Lime
        """,
        instructions: """
        1. Add chicken, broth, salsa verde, onion, peppers, zucchini, and spices to a large pot or slow cooker.
        2. Cook until chicken is shreddable.
        3. Shred chicken.
        4. Add beans and frozen greens.
        5. Simmer until thickened.
        6. Portion into 2-cup cubes.
        """,
        notes: "High-protein freezer dinner. Serve with sweet potato, brown rice, cabbage slaw, or salad.",
        isVegetarian: false
    ),
    .init(
        name: "Tofu Chickpea Tomato Curry",
        recipeType: .dinner,
        cubeSize: .twoCup,
        cubeYield: 6,
        servings: 6,
        calories: 700,
        protein: 42,
        carbs: 70,
        fat: 24,
        saturatedFat: 5,
        fiber: 16,
        sodium: 0,
        ingredients: """
        4 blocks extra-firm tofu
        3 cans chickpeas, drained
        1 large 28 oz can crushed tomatoes
        1 can light coconut milk, optional
        1 bag frozen spinach
        1 bag frozen cauliflower or mixed vegetables
        1 onion
        Curry powder
        Turmeric
        Cumin
        Garlic
        Ginger
        Optional: frozen shelled edamame for extra protein
        """,
        instructions: """
        1. Press and cube tofu.
        2. Saute onion, garlic, ginger, and spices.
        3. Add tomatoes, chickpeas, tofu, vegetables, and optional light coconut milk.
        4. Simmer until thick.
        5. Portion into 2-cup cubes.
        """,
        notes: "Vegetarian and fiber-rich. Protein is lower than chicken/turkey meals, so pair with edamame, Greek yogurt, or protein shake.",
        isVegetarian: true
    ),
    .init(
        name: "Lentil-Turkey Bolognese",
        recipeType: .dinner,
        cubeSize: .twoCup,
        cubeYield: 6,
        servings: 6,
        calories: 720,
        protein: 56,
        carbs: 70,
        fat: 14,
        saturatedFat: 3,
        fiber: 16,
        sodium: 0,
        ingredients: """
        1.5 to 2 lb lean ground turkey
        1.5 cups dry lentils
        2 jars low-sugar marinara
        1 onion
        2 carrots, finely diced
        2 celery stalks, finely diced
        1 package mushrooms, finely chopped
        Italian seasoning
        Garlic
        Crushed red pepper
        Chickpea pasta or whole-wheat pasta for serving
        """,
        instructions: """
        1. Brown turkey.
        2. Add onion, carrots, celery, mushrooms, garlic, and seasoning.
        3. Add lentils and marinara.
        4. Simmer until lentils are tender.
        5. Portion sauce into 2-cup cubes.
        6. Serve with chickpea pasta or whole-wheat pasta.
        """,
        notes: "Good protein/fiber freezer meal. Pasta can be cooked fresh or stored separately.",
        isVegetarian: false
    ),
    .init(name: "Brown Rice", recipeType: .side, cubeSize: .oneCup, cubeYield: 6, servings: 6, calories: 215, protein: 5, carbs: 45, fat: 2, saturatedFat: 0, fiber: 3.5, sodium: 0, ingredients: "Cooked brown rice", instructions: "Cook, cool slightly, and portion into 1-cup cubes.", notes: "Quality carb side.", isVegetarian: true),
    .init(name: "Quinoa", recipeType: .side, cubeSize: .oneCup, cubeYield: 6, servings: 6, calories: 220, protein: 8, carbs: 40, fat: 4, saturatedFat: 0, fiber: 5, sodium: 0, ingredients: "Cooked quinoa", instructions: "Cook, cool slightly, and portion into 1-cup cubes.", notes: "Quality carb and some protein.", isVegetarian: true),
    .init(name: "Sweet Potato Mash", recipeType: .side, cubeSize: .oneCup, cubeYield: 6, servings: 6, calories: 180, protein: 4, carbs: 41, fat: 0, saturatedFat: 0, fiber: 6, sodium: 0, ingredients: "Sweet potatoes", instructions: "Roast or steam, mash, and portion into 1-cup cubes.", notes: "Freezer-friendly carb side.", isVegetarian: true),
    .init(name: "Edamame Add-On", recipeType: .side, cubeSize: .oneCup, cubeYield: 4, servings: 4, calories: 190, protein: 18, carbs: 15, fat: 8, saturatedFat: 1, fiber: 8, sodium: 0, ingredients: "Shelled edamame", instructions: "Steam, cool, and portion into 1-cup cubes.", notes: "High-protein vegetarian add-on.", isVegetarian: true),
    .init(name: "Salsa Verde Sauce", recipeType: .sauce, cubeSize: .halfCup, cubeYield: 8, servings: 8, calories: 40, protein: 1, carbs: 8, fat: 0, saturatedFat: 0, fiber: 1, sodium: 0, ingredients: "Salsa verde", instructions: "Portion into 1/2-cup cubes.", notes: "Easy sauce or stew starter.", isVegetarian: true),
    .init(name: "Lemon Dijon Dressing Concentrate", recipeType: .sauce, cubeSize: .twoTbsp, cubeYield: 12, servings: 12, calories: 80, protein: 0, carbs: 2, fat: 8, saturatedFat: 1, fiber: 0, sodium: 0, ingredients: "Lemon juice, Dijon mustard, olive oil, garlic, herbs", instructions: "Blend or whisk and portion into 2 Tbsp cubes.", notes: "Use as a fresh salad booster.", isVegetarian: true)
]

private let freezerSeeds: [FreezerSeed] = [
    .init(name: "Brown Rice", cubeSize: .oneCup, cubesFrozen: 6, calories: 215, protein: 5, fiber: 3.5, saturatedFat: 0, notes: "Starter side inventory"),
    .init(name: "Quinoa", cubeSize: .oneCup, cubesFrozen: 6, calories: 220, protein: 8, fiber: 5, saturatedFat: 0, notes: "Starter side inventory"),
    .init(name: "Sweet Potato Mash", cubeSize: .oneCup, cubesFrozen: 6, calories: 180, protein: 4, fiber: 6, saturatedFat: 0, notes: "Starter side inventory"),
    .init(name: "Edamame Add-On", cubeSize: .oneCup, cubesFrozen: 4, calories: 190, protein: 18, fiber: 8, saturatedFat: 1, notes: "Starter high-protein side"),
    .init(name: "Salsa Verde Sauce", cubeSize: .halfCup, cubesFrozen: 8, calories: 40, protein: 1, fiber: 1, saturatedFat: 0, notes: "Starter sauce inventory"),
    .init(name: "Lemon Dijon Dressing Concentrate", cubeSize: .twoTbsp, cubesFrozen: 12, calories: 80, protein: 0, fiber: 0, saturatedFat: 1, notes: "Starter flavor booster")
]

private let mealPlanSeeds: [MealPlanSeed] = [
    .init(lunch: "Lentil-chicken kale salad", dinner: "Turkey & Lentil Chili", side: "Quinoa", snackOne: "Protein shake", snackTwo: "Greek yogurt with berries", calories: 2000, protein: 155, fiber: 35, saturatedFat: 10),
    .init(lunch: "Turkey taco salad bowl", dinner: "Chicken White Bean Verde Stew", side: "Sweet Potato Mash", snackOne: "Protein shake", snackTwo: "Cottage cheese and orange", calories: 2000, protein: 150, fiber: 32, saturatedFat: 10),
    .init(lunch: "Chickpea tofu power salad", dinner: "Tofu Chickpea Tomato Curry", side: "Brown Rice", snackOne: "Protein shake", snackTwo: "Greek yogurt and carrots/hummus", calories: 2000, protein: 150, fiber: 38, saturatedFat: 12),
    .init(lunch: "Lentil-chicken kale salad", dinner: "Turkey & Lentil Chili", side: "Salad or vegetables", snackOne: "Protein shake", snackTwo: "Greek yogurt and fruit", calories: 2000, protein: 155, fiber: 35, saturatedFat: 10),
    .init(lunch: "Mediterranean edamame salad", dinner: "Chicken White Bean Verde Stew", side: "Brown Rice", snackOne: "Protein shake", snackTwo: "Cottage cheese and apple", calories: 2000, protein: 150, fiber: 32, saturatedFat: 10),
    .init(lunch: "Turkey taco salad bowl", dinner: "Lentil-Turkey Bolognese", side: "Chickpea pasta", snackOne: "Protein shake", snackTwo: "Greek yogurt with berries", calories: 2050, protein: 155, fiber: 36, saturatedFat: 11),
    .init(lunch: "Chickpea tofu power salad", dinner: "Tofu Chickpea Tomato Curry", side: "Quinoa", snackOne: "Protein shake", snackTwo: "Greek yogurt and fruit", calories: 2000, protein: 150, fiber: 38, saturatedFat: 12),
    .init(lunch: "Mediterranean edamame salad", dinner: "Turkey & Lentil Chili", side: "Brown Rice", snackOne: "Protein shake", snackTwo: "Greek yogurt and apple", calories: 2000, protein: 150, fiber: 35, saturatedFat: 10),
    .init(lunch: "Lentil-chicken kale salad", dinner: "Lentil-Turkey Bolognese", side: "Chickpea pasta", snackOne: "Protein shake", snackTwo: "Cottage cheese with berries", calories: 2050, protein: 155, fiber: 36, saturatedFat: 11),
    .init(lunch: "Turkey taco salad bowl", dinner: "Chicken White Bean Verde Stew", side: "Sweet Potato Mash", snackOne: "Protein shake", snackTwo: "Greek yogurt and fruit", calories: 2000, protein: 155, fiber: 32, saturatedFat: 10),
    .init(lunch: "Chickpea tofu power salad", dinner: "Tofu Chickpea Tomato Curry", side: "Brown Rice and Edamame Add-On", snackOne: "Protein shake", snackTwo: "Cottage cheese and carrots/hummus", calories: 2000, protein: 150, fiber: 40, saturatedFat: 12),
    .init(lunch: "Lentil-chicken kale salad", dinner: "Turkey & Lentil Chili", side: "Quinoa", snackOne: "Protein shake", snackTwo: "Greek yogurt and nuts/fruit", calories: 2000, protein: 155, fiber: 35, saturatedFat: 11),
    .init(lunch: "Mediterranean edamame salad", dinner: "Chicken White Bean Verde Stew", side: "Salad and corn tortillas", snackOne: "Protein shake", snackTwo: "Greek yogurt and apple", calories: 2000, protein: 150, fiber: 32, saturatedFat: 10),
    .init(lunch: "Turkey taco salad bowl", dinner: "Lentil-Turkey Bolognese", side: "Roasted vegetables or chickpea pasta", snackOne: "Protein shake", snackTwo: "Greek yogurt with berries", calories: 2050, protein: 155, fiber: 36, saturatedFat: 11)
]

private extension String {
    var seedKey: String {
        trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
