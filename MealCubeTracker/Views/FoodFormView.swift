import SwiftData
import SwiftUI

struct FoodFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let food: FoodItem?

    @State private var name: String
    @State private var category: FoodCategory
    @State private var reason: String
    @State private var notes: String
    @State private var isFavorite: Bool
    @State private var validationMessage: String?

    init(food: FoodItem? = nil) {
        self.food = food
        _name = State(initialValue: food?.name ?? "")
        _category = State(initialValue: food?.category ?? .eatMore)
        _reason = State(initialValue: food?.reason ?? "")
        _notes = State(initialValue: food?.notes ?? "")
        _isFavorite = State(initialValue: food?.isFavorite ?? false)
    }

    var body: some View {
        Form {
            Section("Food") {
                TextField("Name", text: $name)
                Picker("Category", selection: $category) {
                    ForEach(FoodCategory.allCases) { category in
                        Text(category.title).tag(category)
                    }
                }
                Toggle("Favorite", isOn: $isFavorite)
            }

            Section("Reason") {
                TextField("Why it matters", text: $reason, axis: .vertical)
                    .lineLimit(2...4)
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
        .navigationTitle(food == nil ? "Add Food" : "Edit Food")
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
        guard !name.trimmed.isEmpty else {
            validationMessage = "Name is required."
            return
        }
        guard !reason.trimmed.isEmpty else {
            validationMessage = "Reason is required."
            return
        }

        if let food {
            food.name = name.trimmed
            food.category = category
            food.reason = reason.trimmed
            food.notes = notes.trimmed
            food.isFavorite = isFavorite
        } else {
            modelContext.insert(FoodItem(
                name: name.trimmed,
                category: category,
                notes: notes.trimmed,
                reason: reason.trimmed,
                isFavorite: isFavorite
            ))
        }

        try? modelContext.save()
        dismiss()
    }
}

#if DEBUG
@MainActor
private struct FoodFormView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FoodFormView()
        }
        .modelContainer(PreviewData.container)
    }
}
#endif
