import SwiftData
import SwiftUI

struct MealPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealPlanEntry.date) private var mealPlanEntries: [MealPlanEntry]

    @State private var activeSheet: MealPlanSheet?
    @State private var showCompleted = true

    init() {}

    private var visibleEntries: [MealPlanEntry] {
        mealPlanEntries
            .filter { showCompleted || !$0.isDone }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        List {
            Section {
                Toggle("Show completed", isOn: $showCompleted)
            }

            Section("Plans") {
                if visibleEntries.isEmpty {
                    EmptyStateView(title: "No Meal Plans", message: "Add a plan or load the two-week starter plan.", systemImage: "calendar")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(visibleEntries) { entry in
                        MealPlanRow(
                            entry: entry,
                            toggleDone: {
                                entry.isDone.toggle()
                                try? modelContext.save()
                            },
                            edit: {
                                activeSheet = .edit(entry)
                            }
                        )
                    }
                }
            }
        }
        .navigationTitle("Meal Plan")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    activeSheet = .add
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Meal Plan")
            }
        }
        .sheet(item: $activeSheet) { sheet in
            NavigationStack {
                switch sheet {
                case .add:
                    MealPlanFormView()
                case .edit(let entry):
                    MealPlanFormView(entry: entry)
                }
            }
        }
    }
}

private struct MealPlanRow: View {
    let entry: MealPlanEntry
    let toggleDone: () -> Void
    let edit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Button {
                    toggleDone()
                } label: {
                    Image(systemName: entry.isDone ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(entry.isDone ? Color.mealAccent : Color.secondary)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(entry.isDone ? "Mark not done" : "Mark done")

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.date.shortMealDate)
                        .font(.headline)
                    Text(entry.dinnerName.isEmpty ? "Dinner not set" : entry.dinnerName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    edit()
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Edit meal plan")
            }

            VStack(alignment: .leading, spacing: 6) {
                mealText("Lunch", entry.lunchName)
                mealText("Side", entry.sideName)
                mealText("Snacks", [entry.snackOne, entry.snackTwo].filter { !$0.trimmed.isEmpty }.joined(separator: ", "))
            }

            TargetProgressRow(title: "Calories", value: entry.plannedCalories, target: HealthTargets.calories, unit: "")
            TargetProgressRow(title: "Protein", value: entry.plannedProtein, target: HealthTargets.protein, unit: "g")
            TargetProgressRow(title: "Fiber", value: entry.plannedFiber, target: HealthTargets.fiber, unit: "g")
            TargetProgressRow(title: "Saturated Fat", value: entry.plannedSaturatedFat, target: HealthTargets.saturatedFat, unit: "g", isMaximum: true)
        }
        .padding(.vertical, 8)
    }

    private func mealText(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.caption.weight(.semibold))
                .frame(width: 48, alignment: .leading)
            Text(value.isEmpty ? "Not set" : value)
                .font(.caption)
                .foregroundStyle(value.isEmpty ? .secondary : .primary)
        }
    }
}

private enum MealPlanSheet: Identifiable {
    case add
    case edit(MealPlanEntry)

    var id: String {
        switch self {
        case .add:
            "add"
        case .edit(let entry):
            entry.id.uuidString
        }
    }
}

#if DEBUG
@MainActor
private struct MealPlanView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MealPlanView()
        }
        .modelContainer(PreviewData.container)
    }
}
#endif
