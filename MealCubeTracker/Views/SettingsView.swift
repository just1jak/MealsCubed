import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var foods: [FoodItem]
    @Query private var recipes: [Recipe]
    @Query private var freezerItems: [FreezerItem]
    @Query private var mealPlanEntries: [MealPlanEntry]

    @State private var message: String?
    @State private var showResetConfirmation = false

    init() {}

    var body: some View {
        List {
            Section("Data") {
                Button {
                    loadStarterData()
                } label: {
                    Label("Load Starter Data", systemImage: "tray.and.arrow.down.fill")
                }

                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    Label("Reset Starter Data", systemImage: "arrow.counterclockwise")
                }

                if let message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Library") {
                SettingsCountRow(title: "Foods", count: foods.count, systemImage: "leaf.fill")
                SettingsCountRow(title: "Recipes", count: recipes.count, systemImage: "book.closed.fill")
                SettingsCountRow(title: "Freezer Items", count: freezerItems.count, systemImage: "snowflake")
                SettingsCountRow(title: "Meal Plans", count: mealPlanEntries.count, systemImage: "calendar")
            }

            Section("About Health Targets") {
                LabeledContent("Calories", value: "About 2,000/day")
                LabeledContent("Protein", value: "About 150g/day")
                LabeledContent("Fiber", value: "30g+/day")
                LabeledContent("Saturated Fat", value: "Under 13g/day")
                LabeledContent("Latest LDL", value: "199 mg/dL")
                LabeledContent("A1C", value: "5.6%")
                Text("This app is for meal planning and tracking only. It is not medical advice. Review lab results and treatment decisions with a licensed clinician.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .confirmationDialog("Reset starter data?", isPresented: $showResetConfirmation) {
            Button("Reset Starter Data", role: .destructive) {
                resetStarterData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Starter foods, recipes, freezer items, and meal plans will be removed. Your manually added items will stay.")
        }
    }

    private func loadStarterData() {
        do {
            try StarterData.load(into: modelContext)
            message = "Starter data loaded."
        } catch {
            message = "Could not load starter data: \(error.localizedDescription)"
        }
    }

    private func resetStarterData() {
        do {
            try StarterData.reset(in: modelContext)
            message = "Starter data reset."
        } catch {
            message = "Could not reset starter data: \(error.localizedDescription)"
        }
    }
}

private struct SettingsCountRow: View {
    let title: String
    let count: Int
    let systemImage: String

    var body: some View {
        Label {
            HStack {
                Text(title)
                Spacer()
                Text("\(count)")
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(Color.mealAccent)
        }
    }
}

#if DEBUG
@MainActor
private struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
        }
        .modelContainer(PreviewData.container)
    }
}
#endif
