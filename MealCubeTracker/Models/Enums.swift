import Foundation

enum FoodCategory: String, Codable, CaseIterable, Identifiable {
    case eatMore
    case limitAvoid

    var id: String { rawValue }

    var title: String {
        switch self {
        case .eatMore:
            "Eat More Often"
        case .limitAvoid:
            "Limit / Avoid"
        }
    }

    var symbolName: String {
        switch self {
        case .eatMore:
            "leaf.fill"
        case .limitAvoid:
            "exclamationmark.triangle.fill"
        }
    }
}

enum RecipeType: String, Codable, CaseIterable, Identifiable {
    case lunch
    case dinner
    case side
    case sauce
    case snack

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lunch:
            "Lunch"
        case .dinner:
            "Dinner"
        case .side:
            "Side"
        case .sauce:
            "Sauce"
        case .snack:
            "Snack"
        }
    }
}

enum RecipeStatus: String, Codable, CaseIterable, Identifiable {
    case wantToTry
    case prepped
    case like
    case favorite
    case tryAgain
    case remove

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wantToTry:
            "Want to Try"
        case .prepped:
            "Prepped"
        case .like:
            "Like"
        case .favorite:
            "Favorite"
        case .tryAgain:
            "Try Again"
        case .remove:
            "Remove"
        }
    }
}

enum CubeSize: String, Codable, CaseIterable, Identifiable {
    case twoTbsp
    case halfCup
    case oneCup
    case twoCup
    case none

    var id: String { rawValue }

    var title: String {
        switch self {
        case .twoTbsp:
            "2 Tbsp"
        case .halfCup:
            "1/2 Cup"
        case .oneCup:
            "1 Cup"
        case .twoCup:
            "2 Cup"
        case .none:
            "None"
        }
    }

    var freezerRole: String {
        switch self {
        case .twoTbsp:
            "Flavor booster"
        case .halfCup:
            "Sauce or topping"
        case .oneCup:
            "Carb or protein side"
        case .twoCup:
            "Main meal base"
        case .none:
            "Not portioned"
        }
    }

    var sortOrder: Int {
        switch self {
        case .twoTbsp:
            0
        case .halfCup:
            1
        case .oneCup:
            2
        case .twoCup:
            3
        case .none:
            4
        }
    }
}
