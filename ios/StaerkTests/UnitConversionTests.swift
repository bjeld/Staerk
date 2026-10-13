import XCTest
@testable import Staerk

final class UnitConversionTests: XCTestCase {
    func testKilogramsToPoundsAndBack() {
        let kg = 80.0
        let lb = WeightUnit.pound.fromKilograms(kg)
        XCTAssertEqual(WeightUnit.pound.toKilograms(lb), kg, accuracy: 0.0001)
        XCTAssertEqual(WeightUnit.kilogram.fromKilograms(kg), 80)
    }

    func testCentimetersToInchesAndBack() {
        let cm = 90.0
        let inches = LengthUnit.inch.fromCentimeters(cm)
        XCTAssertEqual(LengthUnit.inch.toCentimeters(inches), cm, accuracy: 0.0001)
    }

    func testParseAcceptsCommaDecimal() {
        XCTAssertEqual(UnitConversion.parse("72,5"), 72.5)
        XCTAssertNil(UnitConversion.parse("  "))
        XCTAssertEqual(UnitConversion.format(40.0), "40")
    }

    func testWeekdaySetToggle() {
        var days: WeekdaySet = .trainingDefault
        XCTAssertTrue(days.contains(.monday))
        XCTAssertFalse(days.contains(.tuesday))
        days.toggle(index: 1)
        XCTAssertTrue(days.contains(.tuesday))
        XCTAssertEqual(days.mondayFirstIndices, [0, 1, 2, 4])
    }
}
