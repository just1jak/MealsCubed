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

    var body: some View {
        List {
            foodSection(for: .eatMore)
            foodSection(for: .limitAvoid)
        }
        .navigationTitle("Foods")
        .searchable(text: $searchText, prompt: "Search foods")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    activeSheet = .add
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Food")
            }
        }
        .overlay {
            if filteredFoods.isEmpty {
                EmptyStateView(title: "No Foods", message: "Add foods or load the starter guide from Settings.", systemImage: "leaf")
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

    @ViewBuilder
    private func foodSection(for category: FoodCategory) -> some View {
        let items = filteredFoods.filter { $0.category == category }
        Section {
            if items.isEmpty {
                Text(searchText.isEmpty ? "No items yet." : "No matches.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items) { food in
                    Button {
                        activeSheet = .edit(food)
                    } label: {
                        FoodRow(food: food)
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            Label(category.title, systemImage: category.symbolName)
        }
    }
}

private struct FoodRow: View {
    let food: FoodItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: food.category.symbolName)
                .foregroundStyle(food.category == .eatMore ? Color.mealAccent : Color.mealWarning)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(food.name)
                        .font(.headline)
                    if food.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
                Text(food.reason)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !food.notes.trimmed.isEmpty {
                    Text(food.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
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
