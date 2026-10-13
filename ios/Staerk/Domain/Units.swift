import Foundation

enum WeightUnit: String, Codable, CaseIterable, Identifiable, Hashable {
    case kilogram
    case pound

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .kilogram: return String(localized: "unit.kg")
        case .pound: return String(localized: "unit.lb")
        }
    }

    func fromKilograms(_ kg: Double) -> Double {
        switch self {
        case .kilogram: return kg
        case .pound: return kg * UnitConversion.poundsPerKilogram
        }
    }

    func toKilograms(_ value: Double) -> Double {
        switch self {
        case .kilogram: return value
        case .pound: return value / UnitConversion.poundsPerKilogram
        }
    }
}

enum LengthUnit: String, Codable, CaseIterable, Identifiable, Hashable {
    case centimeter
    case inch

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .centimeter: return String(localized: "unit.cm")
        case .inch: return String(localized: "unit.in")
        }
    }

    func fromCentimeters(_ cm: Double) -> Double {
        switch self {
        case .centimeter: return cm
        case .inch: return cm / UnitConversion.centimetersPerInch
        }
    }

    func toCentimeters(_ value: Double) -> Double {
        switch self {
        case .centimeter: return value
        case .inch: return value * UnitConversion.centimetersPerInch
        }
    }
}

enum UnitConversion {
    static let poundsPerKilogram = 2.2046226218
    static let centimetersPerInch = 2.54

    static func format(_ value: Double, decimals: Int = 1) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        let factor = pow(10.0, Double(decimals))
        let rounded = (value * factor).rounded() / factor
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(rounded))
        }
        return String(format: "%g", rounded)
    }

    static func parse(_ text: String) -> Double? {
        let trimmed = text.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }
}
