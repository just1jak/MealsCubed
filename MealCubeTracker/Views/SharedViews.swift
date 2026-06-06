import SwiftUI

extension Color {
    static let mealAccent = Color(red: 0.0, green: 0.52, blue: 0.43)
    static let mealAccentSoft = Color(red: 0.86, green: 0.96, blue: 0.93)
    static let mealBackground = Color(red: 0.96, green: 0.98, blue: 0.96)
    static let mealWarning = Color(red: 0.86, green: 0.38, blue: 0.18)
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
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
        .background(Color.mealAccentSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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
