import Foundation
import SwiftData

@Model
final class MealPlanEntry: Identifiable {
    @Attribute(.unique) var id: UUID
    var date: Date
    var lunchName: String
    var dinnerName: String
    var sideName: String
    var snackOne: String
    var snackTwo: String
    var plannedCalories: Double
    var plannedProtein: Double
    var plannedFiber: Double
    var plannedSaturatedFat: Double
    var isDone: Bool
    var notes: String
    var isStarterData: Bool

    init(
        id: UUID = UUID(),
        date: Date,
        lunchName: String = "",
        dinnerName: String = "",
        sideName: String = "",
        snackOne: String = "",
        snackTwo: String = "",
        plannedCalories: Double = 0,
        plannedProtein: Double = 0,
        plannedFiber: Double = 0,
        plannedSaturatedFat: Double = 0,
        isDone: Bool = false,
        notes: String = "",
        isStarterData: Bool = false
    ) {
        self.id = id
        self.date = date
        self.lunchName = lunchName
        self.dinnerName = dinnerName
        self.sideName = sideName
        self.snackOne = snackOne
        self.snackTwo = snackTwo
        self.plannedCalories = plannedCalories
        self.plannedProtein = plannedProtein
        self.plannedFiber = plannedFiber
        self.plannedSaturatedFat = plannedSaturatedFat
        self.isDone = isDone
        self.notes = notes
        self.isStarterData = isStarterData
    }
}
