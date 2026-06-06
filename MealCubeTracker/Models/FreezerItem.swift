import Foundation
import SwiftData

@Model
final class FreezerItem: Identifiable {
    @Attribute(.unique) var id: UUID
    var recipeName: String
    var cubeSize: CubeSize
    var cubesFrozen: Double
    var caloriesPerCube: Double
    var proteinPerCube: Double
    var fiberPerCube: Double
    var saturatedFatPerCube: Double
    var dateMade: Date
    var useByDate: Date
    var notes: String
    var isArchived: Bool
    var isStarterData: Bool

    init(
        id: UUID = UUID(),
        recipeName: String,
        cubeSize: CubeSize,
        cubesFrozen: Double,
        caloriesPerCube: Double = 0,
        proteinPerCube: Double = 0,
        fiberPerCube: Double = 0,
        saturatedFatPerCube: Double = 0,
        dateMade: Date = Date(),
        useByDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date(),
        notes: String = "",
        isArchived: Bool = false,
        isStarterData: Bool = false
    ) {
        self.id = id
        self.recipeName = recipeName
        self.cubeSize = cubeSize
        self.cubesFrozen = cubesFrozen
        self.caloriesPerCube = caloriesPerCube
        self.proteinPerCube = proteinPerCube
        self.fiberPerCube = fiberPerCube
        self.saturatedFatPerCube = saturatedFatPerCube
        self.dateMade = dateMade
        self.useByDate = useByDate
        self.notes = notes
        self.isArchived = isArchived
        self.isStarterData = isStarterData
    }
}
