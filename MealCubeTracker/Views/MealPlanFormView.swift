import SwiftData
import SwiftUI

struct MealPlanFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let entry: MealPlanEntry?

    @State private var date: Date
    @State private var lunchName: String
    @State private var dinnerName: String
    @State private var sideName: String
    @State private var snackOne: String
    @State private var snackTwo: String
    @State private var plannedCalories: String
    @State private var plannedProtein: String
    @State private var plannedFiber: String
    @State private var plannedSaturatedFat: String
    @State private var isDone: Bool
    @State private var notes: String
    @State private var validationMessage: String?

    init(entry: MealPlanEntry? = nil) {
        self.entry = entry
        _date = State(initialValue: entry?.date ?? Date())
        _lunchName = State(initialValue: entry?.lunchName ?? "")
        _dinnerName = State(initialValue: entry?.dinnerName ?? "")
        _sideName = State(initialValue: entry?.sideName ?? "")
        _snackOne = State(initialValue: entry?.snackOne ?? "")
        _snackTwo = State(initialValue: entry?.snackTwo ?? "")
        _plannedCalories = State(initialValue: (entry?.plannedCalories ?? HealthTargets.calories).compactString)
        _plannedProtein = State(initialValue: (entry?.plannedProtein ?? HealthTargets.protein).compactString)
        _plannedFiber = State(initialValue: (entry?.plannedFiber ?? HealthTargets.fiber).compactString)
        _plannedSaturatedFat = State(initialValue: (entry?.plannedSaturatedFat ?? 10).compactString)
        _isDone = State(initialValue: entry?.isDone ?? false)
        _notes = State(initialValue: entry?.notes ?? "")
    }

    var body: some View {
        Form {
            Section("Date") {
                DatePicker("Plan Date", selection: $date, displayedComponents: .date)
                Toggle("Done", isOn: $isDone)
            }

            Section("Meals") {
                TextField("Lunch", text: $lunchName)
                TextField("Dinner", text: $dinnerName)
                TextField("Side", text: $sideName)
                TextField("Snack One", text: $snackOne)
                TextField("Snack Two", text: $snackTwo)
            }

            Section("Daily Totals") {
                DecimalTextField(title: "Calories", text: $plannedCalories)
                DecimalTextField(title: "Protein (g)", text: $plannedProtein)
                DecimalTextField(title: "Fiber (g)", text: $plannedFiber)
                DecimalTextField(title: "Saturated Fat (g)", text: $plannedSaturatedFat)
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
        .navigationTitle(entry == nil ? "Add Plan" : "Edit Plan")
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
        guard let calories = plannedCalories.doubleValue,
              let protein = plannedProtein.doubleValue,
              let fiber = plannedFiber.doubleValue,
              let saturatedFat = plannedSaturatedFat.doubleValue else {
            validationMessage = "Daily totals must be numbers."
            return
        }

        guard !lunchName.trimmed.isEmpty || !dinnerName.trimmed.isEmpty else {
            validationMessage = "Add at least lunch or dinner."
            return
        }

        let target = entry ?? MealPlanEntry(date: date)
        target.date = Calendar.current.startOfDay(for: date)
        target.lunchName = lunchName.trimmed
        target.dinnerName = dinnerName.trimmed
        target.sideName = sideName.trimmed
        target.snackOne = snackOne.trimmed
        target.snackTwo = snackTwo.trimmed
        target.plannedCalories = max(0, calories)
        target.plannedProtein = max(0, protein)
        target.plannedFiber = max(0, fiber)
        target.plannedSaturatedFat = max(0, saturatedFat)
        target.isDone = isDone
        target.notes = notes.trimmed

        if entry == nil {
            modelContext.insert(target)
        }

        try? modelContext.save()
        dismiss()
    }
}

#if DEBUG
@MainActor
private struct MealPlanFormView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MealPlanFormView()
        }
        .modelContainer(PreviewData.container)
    }
}
#endif
