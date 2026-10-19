import Foundation

enum L10n {
    static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key))
    }

    static func format(_ key: String, _ args: CVarArg...) -> String {
        String(format: string(key), locale: .current, arguments: args)
    }
}

extension MuscleGroup {
    var localizedName: String { L10n.string(localizationKey) }
}

extension LogType {
    var localizedName: String { L10n.string(localizationKey) }
}

extension WorkoutKind {
    var localizedName: String { L10n.string(localizationKey) }
}

extension ThemeMode {
    var localizedName: String { L10n.string(localizationKey) }
}

extension HabitKind {
    var localizedName: String { L10n.string(localizationKey) }
}

extension WeightUnit {
    var localizedName: String {
        switch self {
        case .kilogram: return L10n.string("unit.kg.full")
        case .pound: return L10n.string("unit.lb.full")
        }
    }
}

extension LengthUnit {
    var localizedName: String {
        switch self {
        case .centimeter: return L10n.string("unit.cm.full")
        case .inch: return L10n.string("unit.in.full")
        }
    }
}

enum AdviceFormatter {
    static func text(_ advice: ProgressionAdvice, unit: WeightUnit) -> String {
        switch advice {
        case .startReps(let min, let max):
            return L10n.format("progress.start.reps", min, max)
        case .startSeconds(let min, let max):
            return L10n.format("progress.start.seconds", min, max)
        case .increaseWeight(let fromKg, let toKg, let repsMax):
            let from = UnitConversion.format(unit.fromKilograms(fromKg))
            let to = UnitConversion.format(unit.fromKilograms(toKg))
            return L10n.format("progress.increase", from, unit.symbol, repsMax, to, unit.symbol)
        case .holdForMaxReps(let weightKg, let maxReps):
            let w = UnitConversion.format(unit.fromKilograms(weightKg))
            return L10n.format("progress.hold.max", w, unit.symbol, maxReps)
        case .stayUntilMin(let weightKg, let minReps):
            let w = UnitConversion.format(unit.fromKilograms(weightKg))
            return L10n.format("progress.stay.min", w, unit.symbol, minReps)
        case .addSeconds:
            return L10n.string("progress.add.seconds")
        case .holdSeconds(let min, let max):
            return L10n.format("progress.hold.seconds", min, max)
        }
    }

    static func formatSet(logType: LogType, set: SetLog, unit: WeightUnit) -> String {
        if logType == .seconds {
            return L10n.format("set.seconds", set.reps)
        }
        let w = UnitConversion.format(unit.fromKilograms(set.weightKg))
        return L10n.format("set.reps", w, unit.symbol, set.reps)
    }
}
