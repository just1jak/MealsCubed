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

    private var activeItemCount: Int {
        freezerItems.filter { !$0.isArchived }.count
    }

    private var archivedCount: Int {
        freezerItems.filter(\.isArchived).count
    }

    var body: some View {
        ControlRoomScreen {
            ControlRoomHeader(
                eyebrow: "Cold Storage",
                title: "Freezer Inventory",
                subtitle: "Track what is ready, use cubes before they age out, and keep prep batches moving.",
                symbolName: "snowflake",
                accent: Color(red: 0.0, green: 0.76, blue: 0.70)
            )

            freezerStats

            ControlRoomActionButton(
                title: "Add Freezer Batch",
                subtitle: "Log cubes by size, macros, and use-by date.",
                symbolName: "plus.circle.fill",
                tint: Color(red: 0.0, green: 0.76, blue: 0.70)
            ) {
                activeSheet = .add
            }

            freezerFilters

            ControlRoomSectionHeader(
                title: "Inventory",
                detail: "\(filteredItems.count) visible",
                tint: Color(red: 0.0, green: 0.76, blue: 0.70)
            )

            if filteredItems.isEmpty {
                ControlRoomPanel(tint: Color(red: 0.0, green: 0.76, blue: 0.70)) {
                    EmptyStateView(title: "No Freezer Items", message: "Add freezer cubes or load starter data.", systemImage: "snowflake")
                        .foregroundStyle(Color.controlCream)
                }
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
        .navigationTitle("Freezer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.controlInk, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    activeSheet = .add
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.controlLime)
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

    private var freezerStats: some View {
        HStack(spacing: 10) {
            ControlRoomStatTile(value: activeCubeCount.compactString, title: "active cubes", symbolName: "square.grid.3x3.fill", tint: .controlLime)
            ControlRoomStatTile(value: "\(activeItemCount)", title: "batches", symbolName: "tray.full.fill", tint: Color(red: 0.0, green: 0.76, blue: 0.70))
            ControlRoomStatTile(value: "\(archivedCount)", title: "archived", symbolName: "archivebox.fill", tint: .controlSteel)
        }
    }

    private var freezerFilters: some View {
        ControlRoomPanel(tint: .controlLine) {
            HStack(spacing: 10) {
                Menu {
                    Button("Any Cube Size") { cubeFilter = nil }
                    ForEach(CubeSize.allCases) { cube in
                        Button(cube.title) { cubeFilter = cube }
                    }
                } label: {
                    ControlRoomPill(
                        text: cubeFilter?.title ?? "Any Cube",
                        symbolName: "line.3.horizontal.decrease.circle",
                        tint: Color(red: 0.0, green: 0.76, blue: 0.70),
                        isActive: cubeFilter != nil
                    )
                }

                Button {
                    showArchived.toggle()
                } label: {
                    ControlRoomPill(
                        text: showArchived ? "Archived On" : "Active Only",
                        symbolName: showArchived ? "archivebox.fill" : "snowflake",
                        tint: showArchived ? .controlSteel : .controlLime,
                        isActive: showArchived
                    )
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
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
        ControlRoomPanel(tint: item.isArchived ? .controlSteel : Color(red: 0.0, green: 0.76, blue: 0.70), padding: 11) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    CubeTrayDiagram(cubeSize: item.cubeSize, count: item.cubesFrozen, tint: item.isArchived ? .controlSteel : Color(red: 0.0, green: 0.76, blue: 0.70), compact: true)
                        .frame(width: 70)

                    VStack(alignment: .leading, spacing: 7) {
                        Text(item.recipeName)
                            .font(.headline.weight(.black))
                            .foregroundStyle(Color.controlCream)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 7) {
                            ControlRoomPill(text: item.cubeSize.title, tint: Color(red: 0.0, green: 0.76, blue: 0.70))
                            if item.isArchived {
                                ControlRoomPill(text: "Archived", symbolName: "archivebox.fill", tint: .controlSteel)
                            }
                        }
                    }

                    Spacer(minLength: 8)

                    Button {
                        edit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.controlCream.opacity(0.8))
                            .frame(width: 34, height: 34)
                            .background(Color.controlPanelSoft, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit \(item.recipeName)")
                }

                HStack(spacing: 10) {
                    freezerCountControls
                    Spacer(minLength: 6)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("USE BY")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(Color.controlCream.opacity(0.48))
                        Text(item.useByDate.shortMealDate)
                            .font(.caption.weight(.black))
                            .foregroundStyle(Color.controlCream)
                    }
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                    FreezerMetricPill(value: item.caloriesPerCube.compactString, title: "cal")
                    FreezerMetricPill(value: "\(item.proteinPerCube.compactString)g", title: "protein")
                    FreezerMetricPill(value: "\(item.fiberPerCube.compactString)g", title: "fiber")
                    FreezerMetricPill(value: "\(item.saturatedFatPerCube.compactString)g", title: "sat fat", tint: .controlPaprika)
                }
            }
        }
    }

    private var freezerCountControls: some View {
        HStack(spacing: 8) {
            Button {
                decrement()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.controlPaprika)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Use one cube")

            VStack(spacing: -3) {
                Text(item.cubesFrozen.compactString)
                    .font(.custom("AvenirNextCondensed-Heavy", size: 30))
                    .foregroundStyle(Color.controlCream)
                Text("CUBES")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(Color.controlCream.opacity(0.5))
            }
            .frame(width: 58)

            Button {
                increment()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.controlLime)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add one cube")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.controlPanelSoft, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct FreezerMetricPill: View {
    let value: String
    let title: String
    var tint: Color = .controlLime

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.caption.weight(.black))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.controlCream.opacity(0.5))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.controlPanelSoft, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
