import SwiftData
import SwiftUI

struct FoodsView: View {
    @Query(sort: \FoodItem.name) private var foods: [FoodItem]
    @State private var searchText = ""
    @State private var activeSheet: FoodSheet?

    init() {}

    private var filteredFoods: [FoodItem] {
        guard !searchText.trimmed.isEmpty else { return foods }
        return foods.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.reason.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var eatMoreCount: Int {
        foods.filter { $0.category == .eatMore }.count
    }

    private var limitAvoidCount: Int {
        foods.filter { $0.category == .limitAvoid }.count
    }

    private var favoriteCount: Int {
        foods.filter(\.isFavorite).count
    }

    var body: some View {
        ControlRoomScreen {
            ControlRoomHeader(
                eyebrow: "Ingredient Intel",
                title: "Food Guide",
                subtitle: "Quick-reference foods for smarter bowl builds, snack choices, and LDL-friendly swaps.",
                symbolName: "leaf.fill",
                accent: .controlLime
            )

            foodStats

            ControlRoomActionButton(
                title: "Add Food Signal",
                subtitle: "Capture a go-to ingredient, snack, or limit item.",
                symbolName: "plus.circle.fill",
                tint: .controlLime
            ) {
                activeSheet = .add
            }

            foodSection(for: .eatMore)
            foodSection(for: .limitAvoid)
        }
        .navigationTitle("Foods")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.controlInk, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .searchable(text: $searchText, prompt: "Search foods")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    activeSheet = .add
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.controlLime)
                }
                .accessibilityLabel("Add Food")
            }
        }
        .sheet(item: $activeSheet) { sheet in
            NavigationStack {
                switch sheet {
                case .add:
                    FoodFormView()
                case .edit(let food):
                    FoodFormView(food: food)
                }
            }
        }
    }

    private var foodStats: some View {
        HStack(spacing: 10) {
            ControlRoomStatTile(value: "\(eatMoreCount)", title: "eat more", symbolName: "leaf.fill", tint: .controlLime)
            ControlRoomStatTile(value: "\(limitAvoidCount)", title: "limit", symbolName: "exclamationmark.triangle.fill", tint: .controlPaprika)
            ControlRoomStatTile(value: "\(favoriteCount)", title: "favorites", symbolName: "star.fill", tint: Color(red: 0.84, green: 0.56, blue: 0.02))
        }
    }

    private func foodSection(for category: FoodCategory) -> some View {
        let items = filteredFoods.filter { $0.category == category }
        let tint = category == .eatMore ? Color.controlLime : Color.controlPaprika

        return VStack(alignment: .leading, spacing: 10) {
            ControlRoomSectionHeader(
                title: category.title,
                detail: "\(items.count) items",
                tint: tint
            )

            if items.isEmpty {
                ControlRoomPanel(tint: tint.opacity(0.8)) {
                    EmptyStateView(
                        title: searchText.isEmpty ? "No Items Yet" : "No Matches",
                        message: searchText.isEmpty ? "Add foods or load the starter guide from Settings." : "Try a different food search.",
                        systemImage: category.symbolName
                    )
                    .foregroundStyle(Color.controlCream)
                }
            } else {
                ForEach(items) { food in
                    Button {
                        activeSheet = .edit(food)
                    } label: {
                        FoodRow(food: food, tint: tint)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct FoodRow: View {
    let food: FoodItem
    let tint: Color

    var body: some View {
        ControlRoomPanel(tint: tint.opacity(0.75), padding: 11) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: food.category.symbolName)
                    .font(.headline.weight(.black))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(food.name)
                            .font(.headline.weight(.black))
                            .foregroundStyle(Color.controlCream)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 6)
                        if food.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption.weight(.black))
                                .foregroundStyle(Color(red: 0.84, green: 0.56, blue: 0.02))
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.black))
                            .foregroundStyle(Color.controlCream.opacity(0.32))
                    }

                    Text(food.reason)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.controlCream.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)

                    if !food.notes.trimmed.isEmpty {
                        Text(food.notes)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.controlCream.opacity(0.52))
                            .lineLimit(2)
                    }
                }
            }
        }
    }
}

private enum FoodSheet: Identifiable {
    case add
    case edit(FoodItem)

    var id: String {
        switch self {
        case .add:
            "add"
        case .edit(let food):
            food.id.uuidString
        }
    }
}

#if DEBUG
@MainActor
private struct FoodsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FoodsView()
        }
        .modelContainer(PreviewData.container)
    }
}
#endif
