import SwiftUI

struct AppRootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2.fill")
            }

            NavigationStack {
                FoodsView()
            }
            .tabItem {
                Label("Foods", systemImage: "leaf.fill")
            }

            NavigationStack {
                RecipesView()
            }
            .tabItem {
                Label("Recipes", systemImage: "book.closed.fill")
            }

            NavigationStack {
                FreezerView()
            }
            .tabItem {
                Label("Freezer", systemImage: "snowflake")
            }

            NavigationStack {
                MealPlanView()
            }
            .tabItem {
                Label("Meal Plan", systemImage: "calendar")
            }
        }
        .tint(Color.mealAccent)
    }
}

#if DEBUG
@MainActor
private struct AppRootView_Previews: PreviewProvider {
    static var previews: some View {
        AppRootView()
            .modelContainer(PreviewData.container)
    }
}
#endif
