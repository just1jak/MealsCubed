import SwiftData
import SwiftUI

@main
struct MealCubeTrackerApp: App {
    private let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            FoodItem.self,
            Recipe.self,
            FreezerItem.self,
            MealPlanEntry.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create MealCube Tracker store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(modelContainer)
    }
}
