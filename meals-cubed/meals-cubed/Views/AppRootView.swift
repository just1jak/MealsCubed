import SwiftUI
import SwiftData

struct AppRootView: View {
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        tabContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.controlInk.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ControlRoomTabBar(selectedTab: $selectedTab)
            }
            .statusBarHidden(selectedTab == .dashboard)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .dashboard:
            NavigationStack {
                DashboardView()
            }
        case .foods:
            NavigationStack {
                FoodsView()
            }
        case .recipes:
            NavigationStack {
                RecipesView()
            }
        case .freezer:
            NavigationStack {
                FreezerView()
            }
        case .mealPlan:
            NavigationStack {
                MealPlanView()
            }
        }
    }
}

private enum AppTab: String, CaseIterable, Identifiable {
    case dashboard
    case foods
    case recipes
    case freezer
    case mealPlan

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard:
            "Dashboard"
        case .foods:
            "Foods"
        case .recipes:
            "Recipes"
        case .freezer:
            "Freezer"
        case .mealPlan:
            "Meal Plan"
        }
    }

    var symbolName: String {
        switch self {
        case .dashboard:
            "square.grid.2x2.fill"
        case .foods:
            "leaf.fill"
        case .recipes:
            "book.closed.fill"
        case .freezer:
            "snowflake"
        case .mealPlan:
            "calendar"
        }
    }
}

private struct ControlRoomTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.symbolName)
                            .font(.system(size: 23, weight: .semibold))
                            .frame(height: 28)
                        Text(tab.title.uppercased())
                            .font(.custom("AvenirNextCondensed-Heavy", size: 12))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    .foregroundStyle(selectedTab == tab ? Color.controlLime : Color.controlCream.opacity(0.72))
                    .frame(maxWidth: .infinity, minHeight: 72)
                    .background {
                        if selectedTab == tab {
                            LinearGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.28, blue: 0.25),
                                    Color(red: 0.0, green: 0.17, blue: 0.16)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                    }
                    .overlay(alignment: .bottom) {
                        if selectedTab == tab {
                            Capsule()
                                .fill(Color(red: 0.0, green: 0.76, blue: 0.70))
                                .frame(width: 52, height: 3)
                                .padding(.bottom, 7)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 3)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [
                    Color.controlPanel.opacity(0.98),
                    Color.black.opacity(0.99)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(red: 0.0, green: 0.76, blue: 0.70))
                .frame(height: 1)
        }
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
