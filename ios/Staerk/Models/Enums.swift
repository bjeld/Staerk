import SwiftUI

enum MuscleGroup: String, Codable, CaseIterable, Identifiable, Hashable {
    case legs
    case chest
    case back
    case shoulders
    case arms
    case core

    var id: String { rawValue }

    var label: String {
        switch self {
        case .legs: return "Ben"
        case .chest: return "Bryst"
        case .back: return "Ryg"
        case .shoulders: return "Skuldre"
        case .arms: return "Arme"
        case .core: return "Core"
        }
    }
}

enum WorkoutLetter: String, Codable, CaseIterable, Identifiable, Hashable {
    case A
    case B

    var id: String { rawValue }

    var opposite: WorkoutLetter {
        self == .A ? .B : .A
    }
}

enum ThemeMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var label: String {
        switch self {
        case .light: return "Lys"
        case .dark: return "Mørk"
        case .system: return "System"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

enum LogType: String, Codable, CaseIterable, Identifiable, Hashable {
    case reps
    case seconds

    var id: String { rawValue }

    var label: String {
        switch self {
        case .reps: return "Vægt og reps"
        case .seconds: return "Sekunder (planke)"
        }
    }
}

enum DayKind: String, Hashable {
    case gym
    case home
    case weekend

    var shortLabel: String {
        switch self {
        case .gym: return "Træning"
        case .home: return "Hjemmekontor"
        case .weekend: return "Weekend"
        }
    }

    var scheduleLabel: String {
        switch self {
        case .gym: return "Styrketræning på jobbet · før kl. 7"
        case .home: return "Hjemmearbejdsdag · gåtur, golf eller hvile"
        case .weekend: return "Weekend · golf, gåtur eller restitution"
        }
    }
}

enum WeekdayLabel {
    static let short = ["man", "tir", "ons", "tor", "fre", "lør", "søn"]
    static let long = ["mandag", "tirsdag", "onsdag", "torsdag", "fredag", "lørdag", "søndag"]
}

enum StaerkID {
    static func make(_ prefix: String) -> String {
        "\(prefix)_\(UUID().uuidString.lowercased())"
    }
}
