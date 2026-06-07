import Foundation
import SwiftData

@Model
final class FoodItem: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: FoodCategory
    var notes: String
    var reason: String
    var isFavorite: Bool
    var isStarterData: Bool

    init(
        id: UUID = UUID(),
        name: String,
        category: FoodCategory,
        notes: String = "",
        reason: String,
        isFavorite: Bool = false,
        isStarterData: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.notes = notes
        self.reason = reason
        self.isFavorite = isFavorite
        self.isStarterData = isStarterData
    }
}
