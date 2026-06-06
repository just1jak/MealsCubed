import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.dateModified, order: .reverse) private var recipes: [Recipe]
    @Query(sort: \FoodItem.name) private var foods: [FoodItem]
    @Query(sort: \FreezerItem.useByDate) private var freezerItems: [FreezerItem]
    @Query(sort: \MealPlanEntry.date) private var mealPlanEntries: [MealPlanEntry]

    @State private var activeSheet: DashboardSheet?
    @State private var message: String?

    init() {}

    private var todaysPlan: MealPlanEntry? {
        mealPlanEntries.first { Calendar.current.isDateInToday($0.date) }
    }

    private var activeFreezerItems: [FreezerItem] {
        freezerItems.filter { !$0.isArchived }
    }

    private var totalCubes: Double {
        activeFreezerItems.reduce(0) { $0 + $1.cubesFrozen }
    }

    private var favoriteRecipes: Int {
        recipes.filter { $0.status == .favorite }.count
    }

    private var shouldShowStarterButton: Bool {
        foods.isEmpty || recipes.isEmpty || mealPlanEntries.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if shouldShowStarterButton {
                    starterDataCard
                }

                dailyTargetsCard

                todayCard

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatTile(title: "Freezer Cubes", value: totalCubes.compactString, subtitle: "Active portions", symbolName: "snowflake")
                    StatTile(title: "Favorite Recipes", value: "\(favoriteRecipes)", subtitle: "Marked favorite", symbolName: "star.fill")
                    StatTile(title: "Recipes", value: "\(recipes.count)", subtitle: "Saved ideas", symbolName: "book.closed.fill")
                    StatTile(title: "Foods", value: "\(foods.count)", subtitle: "Food guide items", symbolName: "leaf.fill")
                }

                quickActionsCard
            }
            .padding()
        }
        .background(Color.mealBackground.ignoresSafeArea())
        .navigationTitle("MealCube Tracker")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    activeSheet = .settings
                } label: {
                    Image(systemName: "gearshape.fill")
                }
                .accessibilityLabel("Settings")
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addRecipe:
                NavigationStack {
                    RecipeFormView()
                }
            case .addFreezerItem:
                NavigationStack {
                    FreezerFormView()
                }
            case .settings:
                NavigationStack {
                    SettingsView()
                }
            }
        }
    }

    private var starterDataCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Starter Data", systemImage: "tray.and.arrow.down.fill")
                    .font(.headline)
                    .foregroundStyle(Color.mealAccent)
                Text("Load the LDL-friendly foods, starter recipes, freezer sides, and two-week meal plan.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Button {
                    loadStarterData()
                } label: {
                    Label("Load Starter Data", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.mealAccent)
            }
        }
    }

    private var dailyTargetsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Daily Targets")
                    .font(.headline)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    MacroPill(title: "Calories", value: "2,000")
                    MacroPill(title: "Protein", value: "150g")
                    MacroPill(title: "Fiber", value: "30g+")
                    MacroPill(title: "Sat Fat", value: "<13g")
                }
            }
        }
    }

    private var todayCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Today", systemImage: "calendar")
                        .font(.headline)
                    Spacer()
                    Badge(text: Date().shortMealDate)
                }

                if let todaysPlan {
                    VStack(alignment: .leading, spacing: 8) {
                        mealLine(title: "Lunch", value: todaysPlan.lunchName)
                        mealLine(title: "Dinner", value: todaysPlan.dinnerName)
                        mealLine(title: "Side", value: todaysPlan.sideName)
                        Divider()
                        TargetProgressRow(title: "Calories", value: todaysPlan.plannedCalories, target: HealthTargets.calories, unit: "")
                        TargetProgressRow(title: "Protein", value: todaysPlan.plannedProtein, target: HealthTargets.protein, unit: "g")
                        TargetProgressRow(title: "Fiber", value: todaysPlan.plannedFiber, target: HealthTargets.fiber, unit: "g")
                        TargetProgressRow(title: "Saturated Fat", value: todaysPlan.plannedSaturatedFat, target: HealthTargets.saturatedFat, unit: "g", isMaximum: true)
                    }
                } else {
                    Text("No plan for today yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var quickActionsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Add")
                    .font(.headline)
                HStack(spacing: 10) {
                    Button {
                        activeSheet = .addRecipe
                    } label: {
                        Label("Recipe", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.mealAccent)

                    Button {
                        activeSheet = .addFreezerItem
                    } label: {
                        Label("Freezer", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private func mealLine(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(width: 58, alignment: .leading)
            Text(value.isEmpty ? "Not set" : value)
                .font(.subheadline)
                .foregroundStyle(value.isEmpty ? .secondary : .primary)
            Spacer()
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
}

private enum DashboardSheet: Identifiable {
    case addRecipe
    case addFreezerItem
    case settings

    var id: String {
        switch self {
        case .addRecipe:
            "addRecipe"
        case .addFreezerItem:
            "addFreezerItem"
        case .settings:
            "settings"
        }
    }
}

#if DEBUG
@MainActor
private struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DashboardView()
        }
        .modelContainer(PreviewData.container)
    }
}
#endif
