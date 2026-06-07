import SwiftUI
import UIKit

extension Color {
    static let mealAccent = Color(red: 0.0, green: 0.52, blue: 0.43)
    static let mealAccentSoft = Color(red: 0.86, green: 0.96, blue: 0.93)
    static let mealBackground = Color(red: 0.96, green: 0.98, blue: 0.96)
    static let mealWarning = Color(red: 0.86, green: 0.38, blue: 0.18)
    static let controlInk = Color(red: 0.04, green: 0.05, blue: 0.05)
    static let controlPanel = Color(red: 0.08, green: 0.09, blue: 0.08)
    static let controlPanelSoft = Color(red: 0.12, green: 0.14, blue: 0.13)
    static let controlLine = Color(red: 0.24, green: 0.28, blue: 0.26)
    static let controlLime = Color(red: 0.64, green: 0.89, blue: 0.20)
    static let controlPaprika = Color(red: 0.86, green: 0.20, blue: 0.10)
    static let controlSteel = Color(red: 0.64, green: 0.62, blue: 0.55)
    static let controlCream = Color(red: 0.96, green: 0.92, blue: 0.84)
}

extension Double {
    var compactString: String {
        if rounded() == self {
            return String(Int(self))
        }
        return String(format: "%.1f", self)
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var doubleValue: Double? {
        Double(replacingOccurrences(of: ",", with: "").trimmed)
    }
}

extension Date {
    var shortMealDate: String {
        formatted(date: .abbreviated, time: .omitted)
    }
}

struct BundleImage: View {
    let name: String

    var body: some View {
        if let path = Bundle.main.path(forResource: name, ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            Image(uiImage: image)
                .resizable()
        } else {
            Color.controlPanel
        }
    }
}

struct AppCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

struct StatTile: View {
    let title: String
    let value: String
    let subtitle: String
    var symbolName: String? = nil

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                if let symbolName {
                    Image(systemName: symbolName)
                        .font(.headline)
                        .foregroundStyle(Color.mealAccent)
                }
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct Badge: View {
    let text: String
    var color: Color = .mealAccent

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(color)
            .background(color.opacity(0.12), in: Capsule())
            .lineLimit(1)
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(Color.mealAccent)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}

struct MacroGrid: View {
    let calories: Double
    let protein: Double
    let carbs: Double?
    let fat: Double?
    let fiber: Double
    let saturatedFat: Double
    let sodium: Double?

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
            MacroPill(title: "Calories", value: calories.compactString)
            MacroPill(title: "Protein", value: "\(protein.compactString)g")
            if let carbs {
                MacroPill(title: "Carbs", value: "\(carbs.compactString)g")
            }
            if let fat {
                MacroPill(title: "Fat", value: "\(fat.compactString)g")
            }
            MacroPill(title: "Fiber", value: "\(fiber.compactString)g")
            MacroPill(title: "Sat Fat", value: "\(saturatedFat.compactString)g")
            if let sodium {
                MacroPill(title: "Sodium", value: sodium > 0 ? "\(sodium.compactString)mg" : "Not set")
            }
        }
    }
}

struct MacroPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mealAccentSoft, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct TargetProgressRow: View {
    let title: String
    let value: Double
    let target: Double
    let unit: String
    var isMaximum: Bool = false

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(value / target, 1.2)
    }

    private var color: Color {
        if isMaximum {
            return value <= target ? Color.mealAccent : Color.mealWarning
        }
        return value >= target ? Color.mealAccent : Color.secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(value.compactString)\(unit) / \(target.compactString)\(unit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: min(progress, 1.0))
                .tint(color)
        }
    }
}

struct FormTextEditor: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            TextEditor(text: $text)
                .frame(minHeight: 110)
                .padding(8)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

struct DecimalTextField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        TextField(title, text: $text)
            .keyboardType(.decimalPad)
    }
}

struct RecipeTheme: Identifiable {
    let id: String
    let name: String
    let shortName: String
    let symbolName: String
    let color: Color

    static let all: [RecipeTheme] = [
        .init(id: "tex-mex", name: "Tex-Mex", shortName: "Tex-Mex", symbolName: "pepper.fill", color: .controlPaprika),
        .init(id: "mediterranean", name: "Mediterranean", shortName: "Med", symbolName: "leaf.fill", color: Color(red: 0.08, green: 0.48, blue: 0.66)),
        .init(id: "korean", name: "Korean", shortName: "Korean", symbolName: "flame.fill", color: Color(red: 0.38, green: 0.22, blue: 0.58)),
        .init(id: "indian", name: "Indian", shortName: "Indian", symbolName: "sun.max.fill", color: Color(red: 0.84, green: 0.56, blue: 0.02)),
        .init(id: "thai", name: "Thai", shortName: "Thai", symbolName: "drop.fill", color: Color(red: 0.44, green: 0.66, blue: 0.08)),
        .init(id: "japanese", name: "Japanese", shortName: "Japan", symbolName: "circle.grid.cross.fill", color: Color(red: 0.68, green: 0.16, blue: 0.14)),
        .init(id: "cozy-vegetarian", name: "Cozy Vegetarian", shortName: "Cozy", symbolName: "carrot.fill", color: Color(red: 0.68, green: 0.36, blue: 0.06)),
        .init(id: "lean-turkey", name: "Lean Turkey", shortName: "Turkey", symbolName: "takeoutbag.and.cup.and.straw.fill", color: Color(red: 0.47, green: 0.34, blue: 0.27)),
        .init(id: "chicken", name: "Chicken", shortName: "Chicken", symbolName: "fork.knife", color: Color(red: 0.76, green: 0.43, blue: 0.16)),
        .init(id: "tofu-beans", name: "Tofu + Beans", shortName: "Tofu", symbolName: "leaf.circle.fill", color: Color(red: 0.24, green: 0.55, blue: 0.30)),
        .init(id: "healthy-snacks", name: "Healthy Snacks", shortName: "Snacks", symbolName: "cart.fill", color: Color(red: 0.0, green: 0.58, blue: 0.54))
    ]

    static func theme(named name: String) -> RecipeTheme {
        all.first { $0.name.caseInsensitiveCompare(name) == .orderedSame } ?? .init(
            id: name.lowercased().replacingOccurrences(of: " ", with: "-"),
            name: name,
            shortName: name,
            symbolName: "circle.fill",
            color: .mealAccent
        )
    }
}

extension Recipe {
    var themeName: String {
        metadataValue("Theme") ?? inferredThemeName
    }

    var theme: RecipeTheme {
        RecipeTheme.theme(named: themeName)
    }

    var prepMinutes: Int? {
        guard let value = metadataValue("Prep") else { return nil }
        return Int(value.filter(\.isNumber))
    }

    var isBowlIdea: Bool {
        notes.localizedCaseInsensitiveContains("Bowl Idea") ||
            name.localizedCaseInsensitiveContains("Bowl")
    }

    var recipeSummary: String {
        if let summary = metadataValue("Summary") {
            return summary
        }
        let ingredients = ingredientsText
            .split(separator: "\n")
            .prefix(3)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: ", ")
        return ingredients.isEmpty ? "Freezer-friendly batch meal." : ingredients
    }

    private func metadataValue(_ key: String) -> String? {
        let prefix = "\(key):"
        return notes
            .split(separator: "\n")
            .first { $0.trimmingCharacters(in: .whitespaces).hasPrefix(prefix) }
            .map { String($0).replacingOccurrences(of: prefix, with: "").trimmed }
    }

    private var inferredThemeName: String {
        let lowercasedName = name.lowercased()
        if recipeType == .snack { return "Healthy Snacks" }
        if lowercasedName.contains("taco") || lowercasedName.contains("burrito") || lowercasedName.contains("chipotle") || lowercasedName.contains("fajita") || lowercasedName.contains("enchilada") { return "Tex-Mex" }
        if lowercasedName.contains("greek") || lowercasedName.contains("mediterranean") || lowercasedName.contains("tzatziki") || lowercasedName.contains("harissa") || lowercasedName.contains("za'atar") { return "Mediterranean" }
        if lowercasedName.contains("gochujang") || lowercasedName.contains("bibimbap") || lowercasedName.contains("kimchi") || lowercasedName.contains("korean") { return "Korean" }
        if lowercasedName.contains("dal") || lowercasedName.contains("tikka") || lowercasedName.contains("saag") || lowercasedName.contains("keema") || lowercasedName.contains("rajma") { return "Indian" }
        if lowercasedName.contains("thai") || lowercasedName.contains("peanut") || lowercasedName.contains("curry") { return "Thai" }
        if lowercasedName.contains("miso") || lowercasedName.contains("teriyaki") || lowercasedName.contains("sushi") || lowercasedName.contains("soba") { return "Japanese" }
        if lowercasedName.contains("turkey") { return "Lean Turkey" }
        if lowercasedName.contains("chicken") { return "Chicken" }
        if lowercasedName.contains("tofu") || lowercasedName.contains("bean") || lowercasedName.contains("chickpea") { return "Tofu + Beans" }
        return "Cozy Vegetarian"
    }
}

struct CubeTrayDiagram: View {
    let cubeSize: CubeSize
    let count: Double
    var tint: Color = .mealAccent
    var compact: Bool = false

    private var filledCount: Int {
        max(0, min(Int(count.rounded()), cellCount))
    }

    private var cellCount: Int {
        switch cubeSize {
        case .twoTbsp:
            9
        case .halfCup:
            6
        case .oneCup:
            4
        case .twoCup:
            2
        case .none:
            1
        }
    }

    private var columns: [GridItem] {
        let columnCount = cubeSize == .twoCup ? 2 : 3
        return Array(repeating: GridItem(.flexible(), spacing: compact ? 3 : 5), count: columnCount)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: compact ? 3 : 5) {
            ForEach(0..<cellCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: compact ? 4 : 6, style: .continuous)
                    .fill(index < filledCount ? tint : tint.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: compact ? 4 : 6, style: .continuous)
                            .stroke(tint.opacity(index < filledCount ? 0.75 : 0.25), lineWidth: 1)
                    )
                    .aspectRatio(cubeSize == .twoCup ? 1.35 : 1.0, contentMode: .fit)
            }
        }
        .padding(compact ? 5 : 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(tint.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(tint.opacity(0.45), lineWidth: 1)
                )
        )
    }
}
