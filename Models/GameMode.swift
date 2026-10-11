import SwiftUI

enum GameMode: String, CaseIterable, Identifiable {
    case single = "Single Player"
    case twoPlayer = "Two Player"

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .single: "Single Player"
        case .twoPlayer: "Two Player"
        }
    }

    var subtitle: LocalizedStringResource {
        switch self {
        case .single: "Chase your best score"
        case .twoPlayer: "Take turns. Don't pop it!"
        }
    }

    var tint: Color {
        switch self {
        case .single: Palette.sky
        case .twoPlayer: Palette.pink
        }
    }
}
