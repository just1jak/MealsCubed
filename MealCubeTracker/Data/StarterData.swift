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

private let coreRecipeSeeds: [RecipeSeed] = [
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

private let recipeSeeds: [RecipeSeed] = coreRecipeSeeds + lowEffortBowlSeeds

private func bowlSeed(
    _ name: String,
    theme: String,
    summary: String,
    base: String,
    proteinSource: String,
    vegetables: String,
    sauce: String,
    fresh: String,
    calories: Double,
    protein: Double,
    carbs: Double,
    fat: Double,
    saturatedFat: Double,
    fiber: Double,
    isVegetarian: Bool = false,
    prepMinutes: Int = 20
) -> RecipeSeed {
    RecipeSeed(
        name: name,
        recipeType: .dinner,
        cubeSize: .twoCup,
        cubeYield: 6,
        servings: 6,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        saturatedFat: saturatedFat,
        fiber: fiber,
        sodium: 0,
        ingredients: """
        Base: \(base)
        Protein: \(proteinSource)
        Vegetables: \(vegetables)
        Sauce or seasoning: \(sauce)
        Fresh finish: \(fresh)
        """,
        instructions: """
        1. Cook the base, or use a prepared freezer-friendly grain.
        2. Warm the protein, vegetables, and sauce in one pot or skillet until thick.
        3. Fold in the base, taste, and adjust seasoning.
        4. Portion into six 2-cup Souper Cube portions.
        5. Freeze, reheat, and add the fresh finish after warming.
        """,
        notes: """
        Theme: \(theme)
        Prep: \(prepMinutes) min
        Summary: \(summary)
        Bowl Idea
        Low effort, freezer friendly, high fiber, and built for quick burrito bowl or Buddha bowl style meals.
        """,
        isVegetarian: isVegetarian
    )
}

private let lowEffortBowlSeeds: [RecipeSeed] = [
    bowlSeed(
        "Smoky Black Bean Burrito Bowl",
        theme: "Tex-Mex",
        summary: "Black beans, quinoa, corn, peppers, and smoky salsa for a dump-and-stir burrito bowl.",
        base: "quinoa or brown rice",
        proteinSource: "black beans plus optional nonfat Greek yogurt after reheating",
        vegetables: "frozen corn, bell peppers, onion, and spinach",
        sauce: "salsa, cumin, smoked paprika, chili powder, and lime",
        fresh: "cabbage slaw, cilantro, and avocado",
        calories: 520,
        protein: 28,
        carbs: 82,
        fat: 10,
        saturatedFat: 1,
        fiber: 18,
        isVegetarian: true,
        prepMinutes: 18
    ),
    bowlSeed(
        "Chipotle Chicken Quinoa Bowl",
        theme: "Tex-Mex",
        summary: "Rotisserie-style chicken, quinoa, beans, and chipotle salsa with almost no chopping.",
        base: "quinoa",
        proteinSource: "shredded chicken breast and pinto beans",
        vegetables: "frozen peppers, onions, corn, and zucchini",
        sauce: "chipotle salsa, cumin, garlic, and oregano",
        fresh: "lime, pico de gallo, and lettuce",
        calories: 610,
        protein: 52,
        carbs: 67,
        fat: 11,
        saturatedFat: 2,
        fiber: 13,
        prepMinutes: 20
    ),
    bowlSeed(
        "Turkey Taco Sweet Potato Bowl",
        theme: "Tex-Mex",
        summary: "Lean turkey taco filling with sweet potato and beans for a hearty freezer bowl.",
        base: "roasted sweet potatoes",
        proteinSource: "lean ground turkey and black beans",
        vegetables: "frozen peppers, onions, and spinach",
        sauce: "taco seasoning, salsa roja, and lime",
        fresh: "shredded lettuce and Greek yogurt",
        calories: 640,
        protein: 50,
        carbs: 66,
        fat: 16,
        saturatedFat: 3,
        fiber: 15,
        prepMinutes: 22
    ),
    bowlSeed(
        "Salsa Verde Chicken Rice Bowl",
        theme: "Tex-Mex",
        summary: "Chicken, brown rice, white beans, and salsa verde in one bright reheatable bowl.",
        base: "brown rice",
        proteinSource: "shredded chicken breast and white beans",
        vegetables: "zucchini, spinach, peppers, and onion",
        sauce: "salsa verde, cumin, garlic, and lime",
        fresh: "cilantro, cabbage, and jalapeno",
        calories: 590,
        protein: 55,
        carbs: 58,
        fat: 9,
        saturatedFat: 2,
        fiber: 12,
        prepMinutes: 20
    ),
    bowlSeed(
        "Lentil Fajita Bowl",
        theme: "Tex-Mex",
        summary: "Lentils, fajita vegetables, brown rice, and salsa for a low-lift vegetarian bowl.",
        base: "brown rice",
        proteinSource: "brown lentils and pinto beans",
        vegetables: "frozen fajita peppers, onion, spinach, and corn",
        sauce: "salsa, chili powder, cumin, and smoked paprika",
        fresh: "lime, cilantro, and avocado",
        calories: 560,
        protein: 27,
        carbs: 88,
        fat: 9,
        saturatedFat: 1,
        fiber: 20,
        isVegetarian: true,
        prepMinutes: 20
    ),
    bowlSeed(
        "Pinto Bean Corn Barley Bowl",
        theme: "Tex-Mex",
        summary: "Barley, pinto beans, corn, and enchilada sauce for a freezer-friendly comfort bowl.",
        base: "barley",
        proteinSource: "pinto beans and optional edamame",
        vegetables: "corn, peppers, onions, and kale",
        sauce: "red enchilada sauce, cumin, garlic, and lime",
        fresh: "scallions and cabbage slaw",
        calories: 540,
        protein: 25,
        carbs: 87,
        fat: 8,
        saturatedFat: 1,
        fiber: 19,
        isVegetarian: true,
        prepMinutes: 18
    ),

    bowlSeed(
        "Lemon Chickpea Farro Bowl",
        theme: "Mediterranean",
        summary: "Chickpeas, farro, spinach, and lemon herbs for an easy Mediterranean bowl.",
        base: "farro",
        proteinSource: "chickpeas and white beans",
        vegetables: "spinach, zucchini, roasted peppers, and onion",
        sauce: "lemon, garlic, oregano, and olive oil",
        fresh: "cucumber, tomato, parsley, and yogurt",
        calories: 560,
        protein: 25,
        carbs: 79,
        fat: 14,
        saturatedFat: 2,
        fiber: 17,
        isVegetarian: true,
        prepMinutes: 18
    ),
    bowlSeed(
        "Chicken Tzatziki Quinoa Bowl",
        theme: "Mediterranean",
        summary: "Lemon chicken, quinoa, white beans, and vegetables finished with quick tzatziki.",
        base: "quinoa",
        proteinSource: "chicken breast and white beans",
        vegetables: "spinach, zucchini, peppers, and onion",
        sauce: "lemon, oregano, garlic, and dill",
        fresh: "tzatziki, cucumber, and tomato",
        calories: 600,
        protein: 56,
        carbs: 54,
        fat: 13,
        saturatedFat: 2,
        fiber: 11,
        prepMinutes: 20
    ),
    bowlSeed(
        "Turkey Kofta Lentil Bowl",
        theme: "Mediterranean",
        summary: "Lean turkey, lentils, warm spices, and barley for a kofta-inspired freezer bowl.",
        base: "barley",
        proteinSource: "lean ground turkey and lentils",
        vegetables: "spinach, tomato, onion, and zucchini",
        sauce: "cumin, coriander, garlic, tomato paste, and lemon",
        fresh: "parsley, cucumber, and yogurt sauce",
        calories: 650,
        protein: 54,
        carbs: 62,
        fat: 15,
        saturatedFat: 3,
        fiber: 16,
        prepMinutes: 22
    ),
    bowlSeed(
        "Greek White Bean Orzo Bowl",
        theme: "Mediterranean",
        summary: "White beans, orzo, spinach, and lemon tomato sauce for a fast vegetarian bowl.",
        base: "whole-wheat or chickpea orzo",
        proteinSource: "cannellini beans",
        vegetables: "spinach, zucchini, tomatoes, and onion",
        sauce: "crushed tomato, lemon, garlic, oregano, and dill",
        fresh: "cucumber, parsley, and a little feta if desired",
        calories: 540,
        protein: 27,
        carbs: 76,
        fat: 11,
        saturatedFat: 2,
        fiber: 15,
        isVegetarian: true,
        prepMinutes: 18
    ),
    bowlSeed(
        "Harissa Tofu Couscous Bowl",
        theme: "Mediterranean",
        summary: "Tofu, chickpeas, couscous, and harissa vegetables with a bright lemon finish.",
        base: "whole-wheat couscous",
        proteinSource: "extra-firm tofu and chickpeas",
        vegetables: "cauliflower, peppers, spinach, and onion",
        sauce: "harissa, lemon, garlic, cumin, and tomato",
        fresh: "parsley, cucumber, and yogurt",
        calories: 590,
        protein: 34,
        carbs: 70,
        fat: 18,
        saturatedFat: 3,
        fiber: 15,
        isVegetarian: true,
        prepMinutes: 20
    ),
    bowlSeed(
        "Za'atar Chicken Barley Bowl",
        theme: "Mediterranean",
        summary: "Chicken, barley, greens, and za'atar lemon sauce for a simple high-protein bowl.",
        base: "barley",
        proteinSource: "chicken breast and chickpeas",
        vegetables: "spinach, zucchini, carrots, and onion",
        sauce: "za'atar, lemon, garlic, and olive oil",
        fresh: "tomato, cucumber, and parsley",
        calories: 610,
        protein: 54,
        carbs: 61,
        fat: 13,
        saturatedFat: 2,
        fiber: 13,
        prepMinutes: 20
    ),

    bowlSeed(
        "Gochujang Turkey Bowl",
        theme: "Korean",
        summary: "Lean turkey, rice, edamame, cabbage, and gochujang for a fast savory bowl.",
        base: "brown rice",
        proteinSource: "lean ground turkey and shelled edamame",
        vegetables: "cabbage, carrots, spinach, and mushrooms",
        sauce: "gochujang, low-sodium soy sauce, garlic, ginger, and rice vinegar",
        fresh: "scallions, cucumber, and sesame seeds",
        calories: 650,
        protein: 52,
        carbs: 66,
        fat: 16,
        saturatedFat: 3,
        fiber: 12,
        prepMinutes: 20
    ),
    bowlSeed(
        "Tofu Bibimbap Freezer Bowl",
        theme: "Korean",
        summary: "Tofu, rice, mushrooms, spinach, and carrots with a freezer-safe bibimbap sauce.",
        base: "brown rice",
        proteinSource: "extra-firm tofu and edamame",
        vegetables: "mushrooms, carrots, spinach, zucchini, and cabbage",
        sauce: "gochujang, garlic, ginger, soy sauce, and rice vinegar",
        fresh: "cucumber, scallions, and kimchi",
        calories: 590,
        protein: 35,
        carbs: 71,
        fat: 17,
        saturatedFat: 3,
        fiber: 13,
        isVegetarian: true,
        prepMinutes: 22
    ),
    bowlSeed(
        "Chicken Kimchi Brown Rice Bowl",
        theme: "Korean",
        summary: "Chicken, brown rice, kimchi, cabbage, and greens for a punchy reheatable bowl.",
        base: "brown rice",
        proteinSource: "chicken breast and edamame",
        vegetables: "cabbage, spinach, carrots, and mushrooms",
        sauce: "kimchi brine, gochujang, garlic, ginger, and soy sauce",
        fresh: "kimchi and scallions",
        calories: 610,
        protein: 56,
        carbs: 58,
        fat: 12,
        saturatedFat: 2,
        fiber: 10,
        prepMinutes: 18
    ),
    bowlSeed(
        "Edamame Mushroom Japchae Bowl",
        theme: "Korean",
        summary: "Mushrooms, edamame, spinach, and sweet potato noodles in a low-lift japchae bowl.",
        base: "sweet potato glass noodles",
        proteinSource: "edamame and tofu",
        vegetables: "mushrooms, spinach, carrots, cabbage, and onion",
        sauce: "soy sauce, garlic, ginger, sesame oil, and rice vinegar",
        fresh: "scallions and cucumber",
        calories: 560,
        protein: 30,
        carbs: 72,
        fat: 15,
        saturatedFat: 2,
        fiber: 12,
        isVegetarian: true,
        prepMinutes: 22
    ),
    bowlSeed(
        "Lentil Gochujang Sweet Potato Bowl",
        theme: "Korean",
        summary: "Lentils, sweet potatoes, cabbage, and gochujang make a hearty vegetarian bowl.",
        base: "roasted sweet potatoes",
        proteinSource: "brown lentils and edamame",
        vegetables: "cabbage, carrots, spinach, and mushrooms",
        sauce: "gochujang, garlic, ginger, rice vinegar, and soy sauce",
        fresh: "cucumber and scallions",
        calories: 580,
        protein: 31,
        carbs: 80,
        fat: 13,
        saturatedFat: 2,
        fiber: 18,
        isVegetarian: true,
        prepMinutes: 20
    ),
    bowlSeed(
        "Sesame Turkey Cauliflower Rice Bowl",
        theme: "Korean",
        summary: "Lean turkey, cauliflower rice, edamame, and sesame sauce for a lighter bowl.",
        base: "cauliflower rice and brown rice blend",
        proteinSource: "lean ground turkey and edamame",
        vegetables: "cabbage, carrots, spinach, and mushrooms",
        sauce: "soy sauce, garlic, ginger, sesame oil, and vinegar",
        fresh: "scallions and cucumber",
        calories: 560,
        protein: 52,
        carbs: 42,
        fat: 17,
        saturatedFat: 3,
        fiber: 11,
        prepMinutes: 18
    ),

    bowlSeed(
        "Lentil Dal Bowl",
        theme: "Indian",
        summary: "Red lentils, brown rice, spinach, and warming spices in a one-pot dal bowl.",
        base: "brown rice",
        proteinSource: "red lentils and optional edamame",
        vegetables: "spinach, cauliflower, carrots, and onion",
        sauce: "turmeric, cumin, garlic, ginger, tomato, and garam masala",
        fresh: "cilantro, lime, and yogurt",
        calories: 560,
        protein: 28,
        carbs: 88,
        fat: 9,
        saturatedFat: 1,
        fiber: 18,
        isVegetarian: true,
        prepMinutes: 20
    ),
    bowlSeed(
        "Chickpea Tikka Masala Bowl",
        theme: "Indian",
        summary: "Chickpeas, quinoa, cauliflower, and tikka sauce without a high-effort curry night.",
        base: "quinoa",
        proteinSource: "chickpeas and tofu",
        vegetables: "cauliflower, spinach, peas, and onion",
        sauce: "tomato, tikka masala spices, garlic, ginger, and light yogurt",
        fresh: "cilantro and cucumber",
        calories: 610,
        protein: 34,
        carbs: 78,
        fat: 15,
        saturatedFat: 2,
        fiber: 17,
        isVegetarian: true,
        prepMinutes: 20
    ),
    bowlSeed(
        "Chicken Saag Brown Rice Bowl",
        theme: "Indian",
        summary: "Chicken, spinach, rice, and tomato spices for a high-protein saag-inspired bowl.",
        base: "brown rice",
        proteinSource: "chicken breast and lentils",
        vegetables: "spinach, onion, cauliflower, and peas",
        sauce: "tomato, garlic, ginger, cumin, coriander, and garam masala",
        fresh: "cilantro and yogurt",
        calories: 620,
        protein: 58,
        carbs: 61,
        fat: 12,
        saturatedFat: 2,
        fiber: 13,
        prepMinutes: 22
    ),
    bowlSeed(
        "Tofu Pea Curry Bowl",
        theme: "Indian",
        summary: "Tofu, peas, rice, and a tomato curry sauce for a simple freezer bowl.",
        base: "brown rice",
        proteinSource: "extra-firm tofu and green peas",
        vegetables: "spinach, cauliflower, carrots, and onion",
        sauce: "tomato, curry powder, turmeric, garlic, and ginger",
        fresh: "cilantro, lime, and yogurt",
        calories: 570,
        protein: 32,
        carbs: 72,
        fat: 16,
        saturatedFat: 2,
        fiber: 14,
        isVegetarian: true,
        prepMinutes: 18
    ),
    bowlSeed(
        "Turkey Keema Quinoa Bowl",
        theme: "Indian",
        summary: "Lean turkey, quinoa, peas, and tomato spices for a quick keema-style bowl.",
        base: "quinoa",
        proteinSource: "lean ground turkey and lentils",
        vegetables: "peas, carrots, spinach, and onion",
        sauce: "tomato, cumin, coriander, turmeric, garlic, and ginger",
        fresh: "cilantro, cucumber, and yogurt",
        calories: 650,
        protein: 55,
        carbs: 62,
        fat: 16,
        saturatedFat: 3,
        fiber: 14,
        prepMinutes: 20
    ),
    bowlSeed(
        "Rajma Kidney Bean Bowl",
        theme: "Indian",
        summary: "Kidney beans, barley, tomato, and spices for a hands-off rajma-inspired bowl.",
        base: "barley",
        proteinSource: "kidney beans and lentils",
        vegetables: "spinach, carrots, cauliflower, and onion",
        sauce: "tomato, cumin, garam masala, garlic, and ginger",
        fresh: "cilantro and lime",
        calories: 550,
        protein: 27,
        carbs: 86,
        fat: 8,
        saturatedFat: 1,
        fiber: 21,
        isVegetarian: true,
        prepMinutes: 20
    ),

    bowlSeed(
        "Thai Peanut Chicken Noodle Bowl",
        theme: "Thai",
        summary: "Chicken, rice noodles, vegetables, and light peanut sauce for a takeout-style bowl.",
        base: "brown rice noodles",
        proteinSource: "chicken breast and edamame",
        vegetables: "cabbage, carrots, peppers, and spinach",
        sauce: "peanut powder, lime, soy sauce, garlic, ginger, and chili paste",
        fresh: "cilantro, cucumber, and lime",
        calories: 660,
        protein: 56,
        carbs: 66,
        fat: 17,
        saturatedFat: 3,
        fiber: 10,
        prepMinutes: 20
    ),
    bowlSeed(
        "Tofu Red Curry Rice Bowl",
        theme: "Thai",
        summary: "Tofu, brown rice, vegetables, and red curry sauce with light coconut milk.",
        base: "brown rice",
        proteinSource: "extra-firm tofu and edamame",
        vegetables: "broccoli, peppers, spinach, carrots, and onion",
        sauce: "red curry paste, light coconut milk, lime, garlic, and ginger",
        fresh: "cilantro and basil",
        calories: 620,
        protein: 34,
        carbs: 70,
        fat: 20,
        saturatedFat: 4,
        fiber: 13,
        isVegetarian: true,
        prepMinutes: 20
    ),
    bowlSeed(
        "Turkey Basil Veg Bowl",
        theme: "Thai",
        summary: "Lean turkey, vegetables, brown rice, and basil-garlic sauce for a fast bowl.",
        base: "brown rice",
        proteinSource: "lean ground turkey",
        vegetables: "green beans, peppers, carrots, spinach, and onion",
        sauce: "soy sauce, garlic, ginger, chili paste, and basil",
        fresh: "basil, lime, and cucumber",
        calories: 610,
        protein: 50,
        carbs: 58,
        fat: 15,
        saturatedFat: 3,
        fiber: 10,
        prepMinutes: 18
    ),
    bowlSeed(
        "Chickpea Green Curry Bowl",
        theme: "Thai",
        summary: "Chickpeas, quinoa, vegetables, and green curry for a vegetarian freezer bowl.",
        base: "quinoa",
        proteinSource: "chickpeas and edamame",
        vegetables: "broccoli, peas, spinach, peppers, and onion",
        sauce: "green curry paste, light coconut milk, lime, garlic, and ginger",
        fresh: "cilantro, basil, and cucumber",
        calories: 600,
        protein: 31,
        carbs: 75,
        fat: 18,
        saturatedFat: 4,
        fiber: 16,
        isVegetarian: true,
        prepMinutes: 20
    ),
    bowlSeed(
        "Chicken Coconut-Lite Sweet Potato Bowl",
        theme: "Thai",
        summary: "Chicken, sweet potato, greens, and a light coconut curry sauce for easy reheating.",
        base: "roasted sweet potatoes",
        proteinSource: "chicken breast and lentils",
        vegetables: "spinach, peppers, carrots, and onion",
        sauce: "yellow curry paste, light coconut milk, lime, garlic, and ginger",
        fresh: "cilantro and lime",
        calories: 650,
        protein: 55,
        carbs: 66,
        fat: 16,
        saturatedFat: 4,
        fiber: 13,
        prepMinutes: 22
    ),
    bowlSeed(
        "Edamame Lime Slaw Rice Bowl",
        theme: "Thai",
        summary: "Edamame, rice, cabbage, carrots, and lime sauce for a bright vegetarian bowl.",
        base: "brown rice",
        proteinSource: "edamame and tofu",
        vegetables: "cabbage, carrots, peppers, spinach, and onion",
        sauce: "lime, soy sauce, garlic, ginger, chili paste, and peanut powder",
        fresh: "cilantro, cucumber, and lime",
        calories: 580,
        protein: 34,
        carbs: 67,
        fat: 17,
        saturatedFat: 2,
        fiber: 13,
        isVegetarian: true,
        prepMinutes: 18
    ),

    bowlSeed(
        "Miso Tofu Rice Bowl",
        theme: "Japanese",
        summary: "Tofu, rice, mushrooms, edamame, and miso sauce for a calm freezer bowl.",
        base: "brown rice",
        proteinSource: "extra-firm tofu and edamame",
        vegetables: "mushrooms, spinach, carrots, cabbage, and onion",
        sauce: "miso, soy sauce, rice vinegar, garlic, and ginger",
        fresh: "scallions, cucumber, and sesame",
        calories: 580,
        protein: 34,
        carbs: 69,
        fat: 16,
        saturatedFat: 3,
        fiber: 12,
        isVegetarian: true,
        prepMinutes: 18
    ),
    bowlSeed(
        "Teriyaki Turkey Barley Bowl",
        theme: "Japanese",
        summary: "Lean turkey, barley, vegetables, and light teriyaki sauce for a hearty bowl.",
        base: "barley",
        proteinSource: "lean ground turkey and edamame",
        vegetables: "broccoli, carrots, spinach, mushrooms, and onion",
        sauce: "low-sugar teriyaki, garlic, ginger, and rice vinegar",
        fresh: "scallions and cucumber",
        calories: 630,
        protein: 52,
        carbs: 62,
        fat: 15,
        saturatedFat: 3,
        fiber: 14,
        prepMinutes: 20
    ),
    bowlSeed(
        "Chicken Edamame Sushi Bowl",
        theme: "Japanese",
        summary: "Chicken, brown rice, edamame, carrots, and sushi-bowl seasonings.",
        base: "brown rice",
        proteinSource: "chicken breast and edamame",
        vegetables: "carrots, cabbage, spinach, and mushrooms",
        sauce: "rice vinegar, soy sauce, ginger, garlic, and a little sesame oil",
        fresh: "cucumber, nori strips, and scallions",
        calories: 600,
        protein: 56,
        carbs: 57,
        fat: 13,
        saturatedFat: 2,
        fiber: 10,
        prepMinutes: 18
    ),
    bowlSeed(
        "Mushroom Soba Protein Bowl",
        theme: "Japanese",
        summary: "Soba, tofu, mushrooms, and greens with ginger miso sauce.",
        base: "soba noodles",
        proteinSource: "tofu and edamame",
        vegetables: "mushrooms, spinach, cabbage, carrots, and onion",
        sauce: "miso, ginger, garlic, soy sauce, and rice vinegar",
        fresh: "scallions and cucumber",
        calories: 590,
        protein: 35,
        carbs: 70,
        fat: 17,
        saturatedFat: 3,
        fiber: 12,
        isVegetarian: true,
        prepMinutes: 20
    ),
    bowlSeed(
        "Ginger Chicken Brown Rice Bowl",
        theme: "Japanese",
        summary: "Chicken, brown rice, carrots, cabbage, and ginger-soy sauce.",
        base: "brown rice",
        proteinSource: "chicken breast",
        vegetables: "cabbage, carrots, mushrooms, spinach, and onion",
        sauce: "ginger, garlic, soy sauce, rice vinegar, and sesame oil",
        fresh: "scallions and cucumber",
        calories: 580,
        protein: 54,
        carbs: 56,
        fat: 12,
        saturatedFat: 2,
        fiber: 9,
        prepMinutes: 18
    ),
    bowlSeed(
        "White Bean Miso Sweet Potato Bowl",
        theme: "Japanese",
        summary: "White beans, sweet potatoes, spinach, and miso ginger sauce.",
        base: "roasted sweet potatoes",
        proteinSource: "white beans and edamame",
        vegetables: "spinach, mushrooms, carrots, and cabbage",
        sauce: "miso, ginger, garlic, rice vinegar, and soy sauce",
        fresh: "scallions and cucumber",
        calories: 570,
        protein: 29,
        carbs: 78,
        fat: 14,
        saturatedFat: 2,
        fiber: 17,
        isVegetarian: true,
        prepMinutes: 20
    ),

    bowlSeed(
        "Lentil Shepherd Bowl",
        theme: "Cozy Vegetarian",
        summary: "Lentils, peas, carrots, mushrooms, and sweet potato for a freezer shepherd bowl.",
        base: "sweet potato mash",
        proteinSource: "lentils and white beans",
        vegetables: "peas, carrots, mushrooms, spinach, and onion",
        sauce: "tomato paste, garlic, thyme, rosemary, and vegetable broth",
        fresh: "parsley and black pepper",
        calories: 560,
        protein: 27,
        carbs: 86,
        fat: 9,
        saturatedFat: 1,
        fiber: 21,
        isVegetarian: true,
        prepMinutes: 22
    ),
    bowlSeed(
        "Mushroom Barley Umami Bowl",
        theme: "Cozy Vegetarian",
        summary: "Mushrooms, barley, white beans, and greens in a savory low-effort bowl.",
        base: "barley",
        proteinSource: "white beans and edamame",
        vegetables: "mushrooms, spinach, carrots, celery, and onion",
        sauce: "miso, thyme, garlic, and low-sodium broth",
        fresh: "parsley and lemon",
        calories: 540,
        protein: 28,
        carbs: 76,
        fat: 12,
        saturatedFat: 2,
        fiber: 18,
        isVegetarian: true,
        prepMinutes: 20
    ),
    bowlSeed(
        "Red Bean Chili Mac Bowl",
        theme: "Cozy Vegetarian",
        summary: "Beans, chickpea pasta, tomato, and chili spices for comfort-food freezer cubes.",
        base: "chickpea pasta",
        proteinSource: "kidney beans and pinto beans",
        vegetables: "tomatoes, peppers, spinach, corn, and onion",
        sauce: "crushed tomato, chili powder, cumin, garlic, and paprika",
        fresh: "scallions and Greek yogurt",
        calories: 620,
        protein: 34,
        carbs: 82,
        fat: 13,
        saturatedFat: 2,
        fiber: 20,
        isVegetarian: true,
        prepMinutes: 20
    ),
    bowlSeed(
        "Split Pea Sweet Potato Bowl",
        theme: "Cozy Vegetarian",
        summary: "Split peas, sweet potato, carrots, and greens for an easy freezer stew bowl.",
        base: "sweet potato cubes",
        proteinSource: "split peas and edamame",
        vegetables: "carrots, celery, spinach, onion, and peas",
        sauce: "low-sodium broth, garlic, thyme, and smoked paprika",
        fresh: "parsley and lemon",
        calories: 550,
        protein: 30,
        carbs: 82,
        fat: 9,
        saturatedFat: 1,
        fiber: 22,
        isVegetarian: true,
        prepMinutes: 20
    ),
    bowlSeed(
        "Tomato Chickpea Polenta Bowl",
        theme: "Cozy Vegetarian",
        summary: "Chickpeas, polenta, tomato, and greens for a soft, cozy freezer bowl.",
        base: "firm polenta cubes",
        proteinSource: "chickpeas and white beans",
        vegetables: "spinach, zucchini, mushrooms, and onion",
        sauce: "crushed tomato, garlic, basil, oregano, and red pepper",
        fresh: "parsley and a spoon of yogurt",
        calories: 570,
        protein: 26,
        carbs: 78,
        fat: 14,
        saturatedFat: 2,
        fiber: 17,
        isVegetarian: true,
        prepMinutes: 18
    ),
    bowlSeed(
        "Butternut Black Bean Bowl",
        theme: "Cozy Vegetarian",
        summary: "Butternut squash, black beans, quinoa, and greens with smoky spices.",
        base: "quinoa",
        proteinSource: "black beans and edamame",
        vegetables: "butternut squash, spinach, peppers, and onion",
        sauce: "smoked paprika, cumin, garlic, tomato, and lime",
        fresh: "cilantro and cabbage slaw",
        calories: 590,
        protein: 31,
        carbs: 82,
        fat: 13,
        saturatedFat: 2,
        fiber: 19,
        isVegetarian: true,
        prepMinutes: 22
    ),

    bowlSeed(
        "Turkey Marinara Chickpea Pasta Bowl",
        theme: "Lean Turkey",
        summary: "Lean turkey, chickpea pasta, marinara, mushrooms, and spinach.",
        base: "chickpea pasta",
        proteinSource: "lean ground turkey",
        vegetables: "mushrooms, spinach, zucchini, carrots, and onion",
        sauce: "low-sugar marinara, garlic, oregano, and basil",
        fresh: "parsley and red pepper",
        calories: 680,
        protein: 58,
        carbs: 65,
        fat: 17,
        saturatedFat: 3,
        fiber: 15,
        prepMinutes: 20
    ),
    bowlSeed(
        "Turkey Verde Rice Bowl",
        theme: "Lean Turkey",
        summary: "Lean turkey, brown rice, white beans, and salsa verde in a bowl format.",
        base: "brown rice",
        proteinSource: "lean ground turkey and white beans",
        vegetables: "peppers, zucchini, spinach, corn, and onion",
        sauce: "salsa verde, cumin, garlic, and lime",
        fresh: "cilantro and cabbage",
        calories: 640,
        protein: 52,
        carbs: 65,
        fat: 14,
        saturatedFat: 3,
        fiber: 13,
        prepMinutes: 18
    ),
    bowlSeed(
        "Turkey Mushroom Stroganoff Bowl",
        theme: "Lean Turkey",
        summary: "Turkey, mushrooms, barley, and yogurt-finished stroganoff flavors.",
        base: "barley",
        proteinSource: "lean ground turkey",
        vegetables: "mushrooms, spinach, carrots, celery, and onion",
        sauce: "low-sodium broth, Dijon, garlic, thyme, and nonfat Greek yogurt after reheating",
        fresh: "parsley and black pepper",
        calories: 620,
        protein: 54,
        carbs: 57,
        fat: 14,
        saturatedFat: 3,
        fiber: 12,
        prepMinutes: 22
    ),
    bowlSeed(
        "Turkey Shawarma Grain Bowl",
        theme: "Lean Turkey",
        summary: "Shawarma-spiced turkey, quinoa, chickpeas, and vegetables.",
        base: "quinoa",
        proteinSource: "lean ground turkey and chickpeas",
        vegetables: "spinach, peppers, zucchini, onion, and carrots",
        sauce: "cumin, coriander, paprika, garlic, lemon, and yogurt finish",
        fresh: "cucumber, tomato, and parsley",
        calories: 650,
        protein: 55,
        carbs: 64,
        fat: 16,
        saturatedFat: 3,
        fiber: 14,
        prepMinutes: 20
    ),
    bowlSeed(
        "Turkey Chili Corn Bowl",
        theme: "Lean Turkey",
        summary: "Lean turkey chili with corn, beans, brown rice, and smoky spices.",
        base: "brown rice",
        proteinSource: "lean ground turkey, black beans, and kidney beans",
        vegetables: "corn, peppers, spinach, zucchini, and onion",
        sauce: "crushed tomato, chili powder, cumin, garlic, and paprika",
        fresh: "lime, cilantro, and cabbage",
        calories: 670,
        protein: 56,
        carbs: 70,
        fat: 15,
        saturatedFat: 3,
        fiber: 18,
        prepMinutes: 20
    ),
    bowlSeed(
        "Turkey Enchilada Quinoa Bowl",
        theme: "Lean Turkey",
        summary: "Turkey, quinoa, beans, vegetables, and enchilada sauce with minimal prep.",
        base: "quinoa",
        proteinSource: "lean ground turkey and pinto beans",
        vegetables: "peppers, corn, spinach, zucchini, and onion",
        sauce: "red enchilada sauce, cumin, garlic, and oregano",
        fresh: "cilantro, lime, and lettuce",
        calories: 650,
        protein: 54,
        carbs: 66,
        fat: 15,
        saturatedFat: 3,
        fiber: 15,
        prepMinutes: 18
    ),

    bowlSeed(
        "Lemon Dijon Chicken Barley Bowl",
        theme: "Chicken",
        summary: "Chicken, barley, greens, and lemon Dijon sauce for a clean freezer bowl.",
        base: "barley",
        proteinSource: "chicken breast and white beans",
        vegetables: "spinach, carrots, celery, zucchini, and onion",
        sauce: "lemon, Dijon, garlic, thyme, and low-sodium broth",
        fresh: "parsley and cucumber",
        calories: 610,
        protein: 56,
        carbs: 58,
        fat: 12,
        saturatedFat: 2,
        fiber: 13,
        prepMinutes: 20
    ),
    bowlSeed(
        "Chicken White Bean Kale Bowl",
        theme: "Chicken",
        summary: "Chicken, white beans, kale, quinoa, and lemon herbs in one batch.",
        base: "quinoa",
        proteinSource: "chicken breast and white beans",
        vegetables: "kale, zucchini, carrots, celery, and onion",
        sauce: "lemon, garlic, rosemary, thyme, and broth",
        fresh: "parsley and lemon",
        calories: 620,
        protein: 58,
        carbs: 60,
        fat: 12,
        saturatedFat: 2,
        fiber: 14,
        prepMinutes: 20
    ),
    bowlSeed(
        "BBQ Chicken Lentil Bowl",
        theme: "Chicken",
        summary: "Chicken, lentils, sweet potato, and a low-sugar BBQ sauce for comfort prep.",
        base: "roasted sweet potatoes",
        proteinSource: "chicken breast and lentils",
        vegetables: "corn, spinach, peppers, and onion",
        sauce: "low-sugar BBQ sauce, smoked paprika, garlic, and vinegar",
        fresh: "cabbage slaw and scallions",
        calories: 650,
        protein: 56,
        carbs: 69,
        fat: 13,
        saturatedFat: 2,
        fiber: 16,
        prepMinutes: 22
    ),
    bowlSeed(
        "Chicken Pesto Farro Bowl",
        theme: "Chicken",
        summary: "Chicken, farro, white beans, spinach, and light pesto flavors.",
        base: "farro",
        proteinSource: "chicken breast and white beans",
        vegetables: "spinach, zucchini, mushrooms, and onion",
        sauce: "light pesto, lemon, garlic, and low-sodium broth",
        fresh: "tomato, basil, and lemon",
        calories: 640,
        protein: 56,
        carbs: 60,
        fat: 16,
        saturatedFat: 3,
        fiber: 13,
        prepMinutes: 18
    ),
    bowlSeed(
        "Chicken Ginger Veg Rice Bowl",
        theme: "Chicken",
        summary: "Chicken, rice, mixed vegetables, and ginger-garlic sauce.",
        base: "brown rice",
        proteinSource: "chicken breast and edamame",
        vegetables: "broccoli, carrots, cabbage, spinach, and onion",
        sauce: "ginger, garlic, soy sauce, rice vinegar, and a little sesame oil",
        fresh: "scallions and cucumber",
        calories: 610,
        protein: 56,
        carbs: 60,
        fat: 12,
        saturatedFat: 2,
        fiber: 10,
        prepMinutes: 18
    ),
    bowlSeed(
        "Chicken Mole-ish Black Bean Bowl",
        theme: "Chicken",
        summary: "Chicken, black beans, rice, cocoa-chili tomato sauce, and peppers.",
        base: "brown rice",
        proteinSource: "chicken breast and black beans",
        vegetables: "peppers, spinach, zucchini, corn, and onion",
        sauce: "tomato, chili powder, cumin, cinnamon, cocoa powder, and garlic",
        fresh: "cilantro and lime",
        calories: 640,
        protein: 55,
        carbs: 67,
        fat: 13,
        saturatedFat: 2,
        fiber: 15,
        prepMinutes: 22
    ),

    bowlSeed(
        "Tofu Black Bean Sofrito Bowl",
        theme: "Tofu + Beans",
        summary: "Tofu, black beans, rice, sofrito, and peppers for a bright freezer bowl.",
        base: "brown rice",
        proteinSource: "extra-firm tofu and black beans",
        vegetables: "peppers, spinach, zucchini, corn, and onion",
        sauce: "sofrito, cumin, garlic, tomato, and lime",
        fresh: "cilantro and cabbage",
        calories: 590,
        protein: 34,
        carbs: 72,
        fat: 16,
        saturatedFat: 2,
        fiber: 16,
        isVegetarian: true,
        prepMinutes: 20
    ),
    bowlSeed(
        "Tofu Lentil Peanut Bowl",
        theme: "Tofu + Beans",
        summary: "Tofu, lentils, vegetables, and a light peanut-lime sauce.",
        base: "quinoa",
        proteinSource: "extra-firm tofu and lentils",
        vegetables: "cabbage, carrots, spinach, peppers, and onion",
        sauce: "peanut powder, lime, garlic, ginger, and soy sauce",
        fresh: "cilantro and cucumber",
        calories: 620,
        protein: 38,
        carbs: 72,
        fat: 18,
        saturatedFat: 3,
        fiber: 17,
        isVegetarian: true,
        prepMinutes: 20
    ),
    bowlSeed(
        "Chickpea Edamame Power Bowl",
        theme: "Tofu + Beans",
        summary: "Chickpeas, edamame, farro, greens, and lemon tahini-style sauce.",
        base: "farro",
        proteinSource: "chickpeas and edamame",
        vegetables: "spinach, carrots, cucumber after reheating, and peppers",
        sauce: "lemon, garlic, tahini, and water to thin",
        fresh: "parsley and cucumber",
        calories: 620,
        protein: 35,
        carbs: 76,
        fat: 18,
        saturatedFat: 2,
        fiber: 18,
        isVegetarian: true,
        prepMinutes: 18
    ),
    bowlSeed(
        "White Bean Tomato Tofu Bowl",
        theme: "Tofu + Beans",
        summary: "Tofu, white beans, barley, tomato, and greens for an easy savory bowl.",
        base: "barley",
        proteinSource: "extra-firm tofu and white beans",
        vegetables: "spinach, zucchini, mushrooms, carrots, and onion",
        sauce: "crushed tomato, garlic, basil, oregano, and red pepper",
        fresh: "parsley and lemon",
        calories: 580,
        protein: 34,
        carbs: 72,
        fat: 15,
        saturatedFat: 2,
        fiber: 17,
        isVegetarian: true,
        prepMinutes: 20
    ),
    bowlSeed(
        "Black Eyed Pea Tofu Bowl",
        theme: "Tofu + Beans",
        summary: "Black eyed peas, tofu, rice, greens, and smoky tomato seasoning.",
        base: "brown rice",
        proteinSource: "extra-firm tofu and black eyed peas",
        vegetables: "collards or spinach, peppers, carrots, and onion",
        sauce: "smoked paprika, garlic, tomato, vinegar, and thyme",
        fresh: "scallions and hot sauce",
        calories: 590,
        protein: 34,
        carbs: 74,
        fat: 15,
        saturatedFat: 2,
        fiber: 16,
        isVegetarian: true,
        prepMinutes: 20
    ),
    bowlSeed(
        "Three Bean Tofu Chili Bowl",
        theme: "Tofu + Beans",
        summary: "Tofu, three beans, quinoa, tomatoes, and chili spices for a prep staple.",
        base: "quinoa",
        proteinSource: "tofu, black beans, kidney beans, and pinto beans",
        vegetables: "peppers, zucchini, spinach, corn, and onion",
        sauce: "crushed tomato, chili powder, cumin, garlic, and smoked paprika",
        fresh: "cilantro, lime, and cabbage",
        calories: 620,
        protein: 38,
        carbs: 76,
        fat: 16,
        saturatedFat: 2,
        fiber: 20,
        isVegetarian: true,
        prepMinutes: 22
    )
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
