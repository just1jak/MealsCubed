import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.dateModified, order: .reverse) private var recipes: [Recipe]
    @Query(sort: \FoodItem.name) private var foods: [FoodItem]
    @Query(sort: \FreezerItem.useByDate) private var freezerItems: [FreezerItem]
    @Query(sort: \MealPlanEntry.date) private var mealPlanEntries: [MealPlanEntry]

    let openFreezer: () -> Void
    let openMealPlan: () -> Void

    @State private var activeSheet: DashboardSheet?
    @State private var message: String?
    @State private var didAutoLoadStarterData = false

    init(
        openFreezer: @escaping () -> Void = {},
        openMealPlan: @escaping () -> Void = {}
    ) {
        self.openFreezer = openFreezer
        self.openMealPlan = openMealPlan
    }

    private var todaysPlan: MealPlanEntry? {
        mealPlanEntries.first { Calendar.current.isDateInToday($0.date) }
    }

    private var activeFreezerItems: [FreezerItem] {
        freezerItems.filter { !$0.isArchived }
    }

    private var totalCubes: Double {
        activeFreezerItems.reduce(0) { $0 + $1.cubesFrozen }
    }

    private var shouldLoadStarterData: Bool {
        foods.isEmpty ||
            StarterData.recipesNeedRefresh(recipes)
    }

    private var plannedCubes: Int {
        min(10, max(8, Int(totalCubes / 5)))
    }

    private var plannedBowlCount: Int {
        guard let todaysPlan else { return 0 }
        return [todaysPlan.lunchName, todaysPlan.dinnerName]
            .filter { !$0.trimmed.isEmpty }
            .count
    }

    private var nextLunchTitle: String {
        let lunch = todaysPlan?.lunchName.trimmed ?? ""
        return lunch.isEmpty ? "Pick lunch bowls\nfor this week" : lunch
    }

    private var nextDinnerTitle: String {
        let dinner = todaysPlan?.dinnerName.trimmed ?? ""
        return dinner.isEmpty ? "Choose dinner bowls\nfrom Recipes" : dinner
    }

    private var nextLunchCubeLabel: String {
        (todaysPlan?.lunchName.trimmed ?? "").isEmpty ? "SELECT" : "1 CUP"
    }

    private var nextDinnerCubeLabel: String {
        (todaysPlan?.dinnerName.trimmed ?? "").isEmpty ? "SELECT" : "1/2 CUP"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroHeader

                VStack(spacing: 7) {
                    prepStatusPanel
                    freezerInventoryConsole
                    nutritionPanel
                    nextUpGrid
                    actionRow
                    readyRail
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 156)
            }
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea(edges: .top)
        .background(Color.controlInk.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            autoLoadStarterDataIfNeeded()
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

    private var heroHeader: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                BundleImage(name: "mealcube-hero")
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: 190)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [
                                .black.opacity(0.98),
                                .black.opacity(0.78),
                                .black.opacity(0.22)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        LinearGradient(
                            colors: [
                                .clear,
                                Color.controlInk.opacity(0.88),
                                Color.controlInk
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Culinary Control Room")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(red: 0.0, green: 0.76, blue: 0.70))

                            Text("MEALCUBE")
                                .font(.custom("AvenirNextCondensed-Heavy", size: 46))
                                .foregroundStyle(Color.controlCream)
                                .shadow(color: .black.opacity(0.65), radius: 3, x: 0, y: 2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.58)

                            Text("TRACKER")
                                .font(.custom("AvenirNextCondensed-Heavy", size: 24))
                                .tracking(6)
                                .foregroundStyle(Color(red: 0.0, green: 0.76, blue: 0.70))
                                .lineLimit(1)
                                .minimumScaleFactor(0.58)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Button {
                            activeSheet = .settings
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.title2.weight(.black))
                                .foregroundStyle(Color.controlCream)
                                .frame(width: 46, height: 46)
                                .background(Color.controlPanel.opacity(0.95), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color.controlCream.opacity(0.45), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }

                    if let message {
                        Text(message)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.controlLime)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 52)
                .frame(width: proxy.size.width, alignment: .leading)
            }
        }
        .frame(height: 190)
    }

    private var prepStatusPanel: some View {
        MetalBlackPanel {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("TODAY'S PREP STATUS")
                        .font(.custom("AvenirNextCondensed-Heavy", size: 14))
                        .foregroundStyle(Color(red: 0.0, green: 0.76, blue: 0.70))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text("ON TRACK")
                        .font(.custom("AvenirNextCondensed-Heavy", size: 31))
                        .foregroundStyle(Color.controlLime)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                    Text("Great work. You're set for a high-protein day.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.controlCream.opacity(0.9))
                        .lineLimit(3)
                        .minimumScaleFactor(0.82)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                DailyGauge(percent: 78)
                    .frame(width: 82, height: 82)

                VStack(alignment: .leading, spacing: 10) {
                    PrepMetric(symbolName: "square.grid.3x3", value: "\(plannedCubes) / 10", title: "CUBES", subtitle: "planned")
                    Divider().overlay(Color.controlCream.opacity(0.32))
                    PrepMetric(symbolName: "takeoutbag.and.cup.and.straw", value: "\(plannedBowlCount)", title: "BOWLS", subtitle: "planned")
                }
                .frame(width: 112)
            }
        }
        .offset(y: -10)
        .padding(.bottom, -7)
    }

    private var freezerInventoryConsole: some View {
        Button {
            openFreezer()
        } label: {
            VStack(spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text("FREEZER INVENTORY")
                        .font(.custom("AvenirNextCondensed-Heavy", size: 22))
                        .foregroundStyle(Color(red: 0.0, green: 0.56, blue: 0.52))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .layoutPriority(1)
                    Spacer()
                    HStack(spacing: 5) {
                        Text("28 CUBES TOTAL")
                        Image(systemName: "chevron.right")
                    }
                    .font(.custom("AvenirNextCondensed-Heavy", size: 14))
                    .foregroundStyle(Color(red: 0.0, green: 0.56, blue: 0.52))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }

                Rectangle()
                    .fill(Color.black.opacity(0.45))
                    .frame(height: 1)

                HStack(alignment: .top, spacing: 0) {
                    FreezerConsoleColumn(title: "2 TBSP", count: 8, caption: "cubes", imageName: "cube-trays", fill: 0.62)
                    ConsoleDivider()
                    FreezerConsoleColumn(title: "1/2 CUP", count: 7, caption: "cubes", imageName: "cube-trays", fill: 0.72)
                    ConsoleDivider()
                    FreezerConsoleColumn(title: "1 CUP", count: 9, caption: "cubes", imageName: "cube-trays", fill: 0.88)
                    ConsoleDivider()
                    FreezerConsoleColumn(title: "2 CUP", count: 4, caption: "cubes", imageName: "cube-trays", fill: 0.52)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open freezer inventory")
        .padding(10)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.82, green: 0.78, blue: 0.68),
                    Color(red: 0.57, green: 0.54, blue: 0.47),
                    Color(red: 0.77, green: 0.73, blue: 0.64)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .overlay(alignment: .topLeading) { ScrewDot().padding(8) }
        .overlay(alignment: .topTrailing) { ScrewDot().padding(8) }
        .overlay(alignment: .bottomLeading) { ScrewDot().padding(8) }
        .overlay(alignment: .bottomTrailing) { ScrewDot().padding(8) }
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.black.opacity(0.65), lineWidth: 2)
        )
    }

    private var nutritionPanel: some View {
        MetalBlackPanel {
            VStack(spacing: 12) {
                HStack {
                    Text("DAILY NUTRITION TARGETS")
                        .font(.custom("AvenirNextCondensed-Heavy", size: 25))
                        .foregroundStyle(Color(red: 0.0, green: 0.76, blue: 0.70))
                        .lineLimit(1)
                        .minimumScaleFactor(0.66)
                    Spacer()
                    Button {
                        activeSheet = .settings
                    } label: {
                        HStack(spacing: 4) {
                            Text("DETAILS")
                            Image(systemName: "chevron.right")
                        }
                        .font(.custom("AvenirNextCondensed-Heavy", size: 16))
                        .foregroundStyle(Color(red: 0.0, green: 0.76, blue: 0.70))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open nutrition target details")
                }

                HStack(spacing: 0) {
                    NutritionConsoleMetric(value: "2000", title: "CALORIES", progress: 0.78, current: "1,560 cals", color: .controlLime)
                    ConsoleDivider(color: .controlCream.opacity(0.28))
                    NutritionConsoleMetric(value: "150g", title: "PROTEIN", progress: 0.78, current: "117g", color: .controlLime)
                    ConsoleDivider(color: .controlCream.opacity(0.28))
                    NutritionConsoleMetric(value: "30g", title: "FIBER", progress: 0.73, current: "22g", color: .controlLime)
                    ConsoleDivider(color: .controlCream.opacity(0.28))
                    NutritionConsoleMetric(value: "<13g", title: "SAT FAT", progress: 0.69, current: "9g", color: .controlPaprika)
                }
            }
        }
    }

    private var nextUpGrid: some View {
        HStack(spacing: 8) {
            Button {
                openMealPlan()
            } label: {
                MetalBlackPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("NEXT UP")
                                .font(.custom("AvenirNextCondensed-Heavy", size: 25))
                                .foregroundStyle(Color(red: 0.0, green: 0.76, blue: 0.70))
                            Text("YOUR BOWL PLAN")
                                .font(.custom("AvenirNextCondensed-Heavy", size: 16))
                                .foregroundStyle(Color.controlCream)
                                .lineLimit(1)
                                .minimumScaleFactor(0.76)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.black))
                                .foregroundStyle(Color.controlCream.opacity(0.68))
                            Spacer(minLength: 0)
                        }

                        BowlPlanRow(label: "LUNCH", title: nextLunchTitle, cube: nextLunchCubeLabel, imageName: "bowl-plan")
                        Divider().overlay(Color.controlCream.opacity(0.22))
                        BowlPlanRow(label: "DINNER", title: nextDinnerTitle, cube: nextDinnerCubeLabel, imageName: "bowl-plan")
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open meal plan")
            .frame(maxWidth: .infinity)

            VStack(spacing: 8) {
                StreakCard()
                PhotoCalloutCard()
            }
            .frame(width: 142)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            DashboardActionCard(
                title: "PREP BATCH",
                subtitle: "Cook once.\nStock your freezer.",
                symbolName: "pot.fill",
                color: Color(red: 0.0, green: 0.46, blue: 0.41),
                action: { activeSheet = .addFreezerItem }
            )

            DashboardActionCard(
                title: "BUILD BOWL",
                subtitle: "Assemble fast.\nEat amazing.",
                symbolName: "takeoutbag.and.cup.and.straw.fill",
                color: Color(red: 0.78, green: 0.16, blue: 0.06),
                action: openMealPlan
            )
        }
    }

    private var readyRail: some View {
        MetalBlackPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("WHAT'S READY")
                        .font(.custom("AvenirNextCondensed-Heavy", size: 24))
                        .foregroundStyle(Color(red: 0.0, green: 0.76, blue: 0.70))
                    Text("GRAB. HEAT. EAT.")
                        .font(.custom("AvenirNextCondensed-Heavy", size: 13))
                        .foregroundStyle(Color.controlCream.opacity(0.8))
                    Spacer()
                    Button {
                        openFreezer()
                    } label: {
                        HStack(spacing: 4) {
                            Text("SEE ALL")
                            Image(systemName: "chevron.right")
                        }
                        .font(.custom("AvenirNextCondensed-Heavy", size: 14))
                        .foregroundStyle(Color(red: 0.0, green: 0.76, blue: 0.70))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("See all freezer items")
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ReadyPhotoTile(title: "TURKEY\nCHILI VERDE", cube: "1 CUP", imageName: "cube-trays")
                        ReadyPhotoTile(title: "THAI PEANUT\nCHICKEN", cube: "1/2 CUP", imageName: "cube-trays")
                        ReadyPhotoTile(title: "GREEK LEMON\nCHICKPEAS", cube: "1/2 CUP", imageName: "bowl-plan")
                        ReadyPhotoTile(title: "BLACK BEAN\n& CORN", cube: "1 CUP", imageName: "mealcube-hero")
                        ReadyPhotoTile(title: "LENTIL DAHL", cube: "1/2 CUP", imageName: "cube-trays")
                    }
                }
            }
        }
    }

    private func autoLoadStarterDataIfNeeded() {
        guard !didAutoLoadStarterData, shouldLoadStarterData else { return }
        didAutoLoadStarterData = true
        do {
            try StarterData.load(into: modelContext)
        } catch {
            message = "Could not load starter data: \(error.localizedDescription)"
        }
    }
}

private struct MetalBlackPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(12)
            .background(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.97),
                        Color.controlPanel.opacity(0.98),
                        Color.black.opacity(0.94)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.controlCream.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.55), radius: 12, x: 0, y: 8)
    }
}

private struct DailyGauge: View {
    let percent: Int

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.12, to: 0.88)
                .stroke(Color.controlLime.opacity(0.22), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(90))
            Circle()
                .trim(from: 0.12, to: 0.72)
                .stroke(Color.controlLime, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(90))
            VStack(spacing: 0) {
                Text("\(percent)%")
                    .font(.custom("AvenirNextCondensed-Heavy", size: 32))
                    .foregroundStyle(Color.controlCream)
                Text("DAILY TARGETS")
                    .font(.custom("AvenirNextCondensed-Heavy", size: 11))
                    .foregroundStyle(Color(red: 0.0, green: 0.76, blue: 0.70))
            }
        }
    }
}

private struct PrepMetric: View {
    let symbolName: String
    let value: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbolName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(red: 0.0, green: 0.76, blue: 0.70))
                .frame(width: 24, height: 25)
            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.custom("AvenirNextCondensed-Heavy", size: 22))
                        .foregroundStyle(Color.controlCream)
                    Text(title)
                        .font(.custom("AvenirNextCondensed-Heavy", size: 13))
                        .foregroundStyle(Color.controlCream)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.62)
                Text(subtitle)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color.controlCream.opacity(0.72))
            }
        }
    }
}

private struct FreezerConsoleColumn: View {
    let title: String
    let count: Int
    let caption: String
    let imageName: String
    let fill: Double

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.custom("AvenirNextCondensed-Heavy", size: 16))
                .foregroundStyle(Color(red: 0.0, green: 0.31, blue: 0.29))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            BundleImage(name: imageName)
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(red: 0.0, green: 0.52, blue: 0.48), lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 4)

            VStack(spacing: -3) {
                Text("\(count)")
                    .font(.custom("AvenirNextCondensed-Heavy", size: 28))
                    .foregroundStyle(Color.black.opacity(0.88))
                Text(caption)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.black.opacity(0.78))
            }

            Capsule()
                .fill(Color.black.opacity(0.75))
                .frame(height: 6)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color(red: 0.0, green: 0.76, blue: 0.70))
                        .frame(width: 52 * fill)
                }
                .frame(width: 52)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ConsoleDivider: View {
    var color: Color = .black.opacity(0.35)

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 1)
            .padding(.vertical, 8)
    }
}

private struct ScrewDot: View {
    var body: some View {
        Circle()
            .fill(Color.black.opacity(0.4))
            .frame(width: 6, height: 6)
            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1))
    }
}

private struct NutritionConsoleMetric: View {
    let value: String
    let title: String
    let progress: Double
    let current: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.custom("AvenirNextCondensed-Heavy", size: 31))
                .foregroundStyle(Color.controlCream)
            Text(title)
                .font(.custom("AvenirNextCondensed-Heavy", size: 14))
                .foregroundStyle(Color.controlCream.opacity(0.9))
            Capsule()
                .fill(Color.controlCream.opacity(0.24))
                .frame(height: 7)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(color)
                        .frame(width: 64 * progress)
                }
                .frame(width: 64)
            Text(current)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.controlCream.opacity(0.82))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct BowlPlanRow: View {
    let label: String
    let title: String
    let cube: String
    let imageName: String

    var body: some View {
        HStack(spacing: 10) {
            BundleImage(name: imageName)
                .scaledToFill()
                .frame(width: 62, height: 62)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.controlCream.opacity(0.5), lineWidth: 1))

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.custom("AvenirNextCondensed-Heavy", size: 14))
                    .foregroundStyle(Color(red: 0.0, green: 0.76, blue: 0.70))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(Color(red: 0.0, green: 0.76, blue: 0.70), lineWidth: 1)
                    )

                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.controlCream)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(cube)
                    .font(.custom("AvenirNextCondensed-Heavy", size: 19))
                    .foregroundStyle(Color(red: 0.0, green: 0.76, blue: 0.70))
                Text("1 cube")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.controlCream.opacity(0.82))
            }
        }
    }
}

private struct StreakCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("WEEKLY PREP STREAK")
                .font(.custom("AvenirNextCondensed-Heavy", size: 14))
                .foregroundStyle(Color.controlCream.opacity(0.9))
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("5")
                    .font(.custom("AvenirNextCondensed-Heavy", size: 47))
                    .foregroundStyle(Color.controlCream)
                Text("DAYS")
                    .font(.custom("AvenirNextCondensed-Heavy", size: 16))
                    .foregroundStyle(Color.controlCream.opacity(0.9))
            }
            Text("CONSISTENCY BUILDS RESULTS")
                .font(.caption2.weight(.black))
                .foregroundStyle(Color.controlCream.opacity(0.62))
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(red: 0.0, green: 0.45, blue: 0.39), Color(red: 0.0, green: 0.26, blue: 0.24)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.controlCream.opacity(0.35), lineWidth: 1)
        )
    }
}

private struct PhotoCalloutCard: View {
    var body: some View {
        ZStack(alignment: .leading) {
            BundleImage(name: "bowl-plan")
                .scaledToFill()
                .frame(height: 122)
                .clipped()
                .overlay(Color.black.opacity(0.56))

            VStack(alignment: .leading, spacing: 5) {
                Text("LDL-FRIENDLY\nHIGH PROTEIN")
                    .font(.custom("AvenirNextCondensed-Heavy", size: 16))
                    .foregroundStyle(Color(red: 0.0, green: 0.76, blue: 0.70))
                Text("Smart choices.\nBetter numbers.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.controlCream)
            }
            .padding(10)
        }
        .frame(maxWidth: .infinity, minHeight: 122)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.controlCream.opacity(0.3), lineWidth: 1)
        )
    }
}

private struct DashboardActionCard: View {
    let title: String
    let subtitle: String
    let symbolName: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    Image(systemName: symbolName)
                        .font(.system(size: 31, weight: .light))
                        .foregroundStyle(Color.controlCream.opacity(0.72))
                        .frame(width: 38, height: 38)

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right.circle")
                        .font(.title2.weight(.light))
                        .foregroundStyle(Color.controlCream.opacity(0.9))
                }

                Text(title.replacingOccurrences(of: " ", with: "\n"))
                    .font(.custom("AvenirNextCondensed-Heavy", size: 29))
                    .foregroundStyle(Color.controlCream)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.controlCream.opacity(0.9))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 146, alignment: .topLeading)
            .background(color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.controlCream.opacity(0.36), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ReadyPhotoTile: View {
    let title: String
    let cube: String
    let imageName: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            BundleImage(name: imageName)
                .scaledToFill()
                .frame(width: 126, height: 108)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.86)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("AvenirNextCondensed-Heavy", size: 15))
                    .foregroundStyle(Color.controlCream)
                    .lineLimit(2)
                Text(cube)
                    .font(.custom("AvenirNextCondensed-Heavy", size: 12))
                    .foregroundStyle(Color.controlCream)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.black.opacity(0.68), in: RoundedRectangle(cornerRadius: 3, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .stroke(Color.controlLime.opacity(0.8), lineWidth: 1)
                    )
            }
            .padding(8)
        }
        .frame(width: 126, height: 108)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.controlCream.opacity(0.4), lineWidth: 1)
        )
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
