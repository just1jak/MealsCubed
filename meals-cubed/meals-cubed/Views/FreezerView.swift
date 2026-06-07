import SwiftData
import SwiftUI

struct FreezerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FreezerItem.useByDate) private var freezerItems: [FreezerItem]

    @State private var cubeFilter: CubeSize?
    @State private var showArchived = false
    @State private var activeSheet: FreezerSheet?
    @State private var pendingArchive: FreezerItem?
    @State private var showArchiveConfirmation = false

    init() {}

    private var filteredItems: [FreezerItem] {
        freezerItems
            .filter { showArchived || !$0.isArchived }
            .filter { cubeFilter == nil || $0.cubeSize == cubeFilter }
            .sorted { lhs, rhs in
                if lhs.useByDate == rhs.useByDate {
                    return lhs.recipeName.localizedStandardCompare(rhs.recipeName) == .orderedAscending
                }
                return lhs.useByDate < rhs.useByDate
            }
    }

    private var activeCubeCount: Double {
        freezerItems.filter { !$0.isArchived }.reduce(0) { $0 + $1.cubesFrozen }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(activeCubeCount.compactString)
                            .font(.largeTitle.weight(.bold))
                        Text("active cubes")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    Text("Sorted by use-by date, then recipe name.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section {
                HStack {
                    Menu {
                        Button("Any Cube Size") { cubeFilter = nil }
                        ForEach(CubeSize.allCases) { cube in
                            Button(cube.title) { cubeFilter = cube }
                        }
                    } label: {
                        Label(cubeFilter?.title ?? "Cube Size", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    Spacer()
                    Toggle("Archived", isOn: $showArchived)
                        .labelsHidden()
                }
            }

            Section("Inventory") {
                if filteredItems.isEmpty {
                    EmptyStateView(title: "No Freezer Items", message: "Add freezer cubes or load starter data.", systemImage: "snowflake")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredItems) { item in
                        FreezerRow(
                            item: item,
                            decrement: { decrement(item) },
                            increment: { increment(item) },
                            edit: { activeSheet = .edit(item) }
                        )
                    }
                }
            }
        }
        .navigationTitle("Freezer")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    activeSheet = .add
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Freezer Item")
            }
        }
        .sheet(item: $activeSheet) { sheet in
            NavigationStack {
                switch sheet {
                case .add:
                    FreezerFormView()
                case .edit(let item):
                    FreezerFormView(item: item)
                }
            }
        }
        .confirmationDialog("Archive empty item?", isPresented: $showArchiveConfirmation, presenting: pendingArchive) { item in
            Button("Archive", role: .destructive) {
                item.isArchived = true
                try? modelContext.save()
                pendingArchive = nil
            }
            Button("Keep Active") {
                if item.cubesFrozen <= 0 {
                    item.cubesFrozen = 1
                }
                try? modelContext.save()
                pendingArchive = nil
            }
            Button("Cancel", role: .cancel) {
                if item.cubesFrozen <= 0 {
                    item.cubesFrozen = 1
                }
                pendingArchive = nil
            }
        } message: { item in
            Text("\(item.recipeName) has zero cubes remaining.")
        }
    }

    private func decrement(_ item: FreezerItem) {
        if item.cubesFrozen > 1 {
            item.cubesFrozen -= 1
            try? modelContext.save()
        } else {
            item.cubesFrozen = 0
            pendingArchive = item
            showArchiveConfirmation = true
        }
    }

    private func increment(_ item: FreezerItem) {
        item.cubesFrozen += 1
        if item.isArchived {
            item.isArchived = false
        }
        try? modelContext.save()
    }
}

private struct FreezerRow: View {
    let item: FreezerItem
    let decrement: () -> Void
    let increment: () -> Void
    let edit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.recipeName)
                        .font(.headline)
                    HStack {
                        Badge(text: item.cubeSize.title)
                        if item.isArchived {
                            Badge(text: "Archived", color: .secondary)
                        }
                    }
                }
                Spacer()
                Button {
                    edit()
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Edit \(item.recipeName)")
            }

            HStack {
                Button {
                    decrement()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Use one cube")

                Text("\(item.cubesFrozen.compactString)")
                    .font(.title3.weight(.bold))
                    .frame(width: 54)

                Button {
                    increment()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Add one cube")

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Use by")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(item.useByDate.shortMealDate)
                        .font(.caption.weight(.semibold))
                }
            }

            HStack(spacing: 12) {
                Text("\(item.caloriesPerCube.compactString) cal")
                Text("\(item.proteinPerCube.compactString)g protein")
                Text("\(item.fiberPerCube.compactString)g fiber")
                Text("\(item.saturatedFatPerCube.compactString)g sat fat")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

private enum FreezerSheet: Identifiable {
    case add
    case edit(FreezerItem)

    var id: String {
        switch self {
        case .add:
            "add"
        case .edit(let item):
            item.id.uuidString
        }
    }
}

#if DEBUG
@MainActor
private struct FreezerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FreezerView()
        }
        .modelContainer(PreviewData.container)
    }
}
#endif
