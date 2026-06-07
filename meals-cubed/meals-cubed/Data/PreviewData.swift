import Foundation
import SwiftData

@MainActor
enum PreviewData {
    static var container: ModelContainer {
        let schema = Schema([
            FoodItem.self,
            Recipe.self,
            FreezerItem.self,
            MealPlanEntry.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        try! StarterData.load(into: container.mainContext)
        return container
    }
}
