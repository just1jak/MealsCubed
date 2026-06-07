import SwiftData
import SwiftUI

struct FreezerFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let item: FreezerItem?

    @State private var recipeName: String
    @State private var cubeSize: CubeSize
    @State private var cubesFrozen: String
    @State private var caloriesPerCube: String
    @State private var proteinPerCube: String
    @State private var fiberPerCube: String
    @State private var saturatedFatPerCube: String
    @State private var dateMade: Date
    @State private var useByDate: Date
    @State private var notes: String
    @State private var isArchived: Bool
    @State private var validationMessage: String?

    init(item: FreezerItem? = nil, recipe: Recipe? = nil) {
        self.item = item
        let defaultUseBy = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        _recipeName = State(initialValue: item?.recipeName ?? recipe?.name ?? "")
        _cubeSize = State(initialValue: item?.cubeSize ?? recipe?.cubeSize ?? .twoCup)
        _cubesFrozen = State(initialValue: (item?.cubesFrozen ?? recipe?.cubeYield ?? 1).compactString)
        _caloriesPerCube = State(initialValue: (item?.caloriesPerCube ?? recipe?.caloriesPerCube ?? 0).compactString)
        _proteinPerCube = State(initialValue: (item?.proteinPerCube ?? recipe?.proteinPerCube ?? 0).compactString)
        _fiberPerCube = State(initialValue: (item?.fiberPerCube ?? recipe?.fiberPerCube ?? 0).compactString)
        _saturatedFatPerCube = State(initialValue: (item?.saturatedFatPerCube ?? recipe?.saturatedFatPerCube ?? 0).compactString)
        _dateMade = State(initialValue: item?.dateMade ?? Date())
        _useByDate = State(initialValue: item?.useByDate ?? defaultUseBy)
        _notes = State(initialValue: item?.notes ?? "")
        _isArchived = State(initialValue: item?.isArchived ?? false)
    }

    var body: some View {
        Form {
            Section("Item") {
                TextField("Recipe or item name", text: $recipeName)
                Picker("Cube Size", selection: $cubeSize) {
                    ForEach(CubeSize.allCases) { cube in
                        Text(cube.title).tag(cube)
                    }
                }
                DecimalTextField(title: "Cubes Frozen", text: $cubesFrozen)
                Toggle("Archived", isOn: $isArchived)
            }

            Section("Per Cube") {
                DecimalTextField(title: "Calories", text: $caloriesPerCube)
                DecimalTextField(title: "Protein (g)", text: $proteinPerCube)
                DecimalTextField(title: "Fiber (g)", text: $fiberPerCube)
                DecimalTextField(title: "Saturated Fat (g)", text: $saturatedFatPerCube)
            }

            Section("Dates") {
                DatePicker("Made", selection: $dateMade, displayedComponents: .date)
                DatePicker("Use By", selection: $useByDate, displayedComponents: .date)
            }

            Section("Notes") {
                TextField("Optional notes", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
            }

            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(item == nil ? "Add Freezer Item" : "Edit Freezer Item")
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
        guard !recipeName.trimmed.isEmpty else {
            validationMessage = "Name is required."
            return
        }

        guard let cubes = cubesFrozen.doubleValue,
              let calories = caloriesPerCube.doubleValue,
              let protein = proteinPerCube.doubleValue,
              let fiber = fiberPerCube.doubleValue,
              let saturatedFat = saturatedFatPerCube.doubleValue else {
            validationMessage = "Cube and macro fields must be numbers."
            return
        }

        let target = item ?? FreezerItem(recipeName: recipeName.trimmed, cubeSize: cubeSize, cubesFrozen: cubes)
        target.recipeName = recipeName.trimmed
        target.cubeSize = cubeSize
        target.cubesFrozen = max(0, cubes)
        target.caloriesPerCube = max(0, calories)
        target.proteinPerCube = max(0, protein)
        target.fiberPerCube = max(0, fiber)
        target.saturatedFatPerCube = max(0, saturatedFat)
        target.dateMade = dateMade
        target.useByDate = useByDate
        target.notes = notes.trimmed
        target.isArchived = isArchived || cubes <= 0

        if item == nil {
            modelContext.insert(target)
        }

        try? modelContext.save()
        dismiss()
    }
}

#if DEBUG
@MainActor
private struct FreezerFormView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FreezerFormView()
        }
        .modelContainer(PreviewData.container)
    }
}
#endif
