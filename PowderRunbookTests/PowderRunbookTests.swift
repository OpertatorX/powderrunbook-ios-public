import XCTest
@testable import PowderRunbook

final class PowderRunbookTests: XCTestCase {
    func testTemperatureConversionsRoundTrip() {
        let c = 190.0
        let f = UnitMath.fahrenheit(fromCelsius: c)
        XCTAssertEqual(f, 374, accuracy: 0.001)
        XCTAssertEqual(UnitMath.celsius(fromFahrenheit: f), c, accuracy: 0.001)
    }

    func testThicknessConversionsRoundTrip() {
        let microns = 76.2
        let mils = UnitMath.mils(fromMicrons: microns)
        XCTAssertEqual(mils, 3.0, accuracy: 0.0001)
        XCTAssertEqual(UnitMath.microns(fromMils: mils), microns, accuracy: 0.0001)
    }

    func testJobStageOrderIsDeterministic() {
        XCTAssertEqual(JobStage.intake.rawValue, 0)
        XCTAssertEqual(JobStage.done.rawValue, JobStage.allCases.count - 1)
        XCTAssertTrue(JobStage.cure.rawValue < JobStage.qc.rawValue)
    }

    func testPowderDisplayNameUsesCodeWhenPresent() {
        let lot = PowderLot(brand: "Example", colorName: "Satin Black", colorCode: "RAL 9005", lotNumber: "A1", startingWeightGrams: 1000, location: "A", notes: "")
        XCTAssertEqual(lot.displayName, "Satin Black \u{00B7} RAL 9005")
    }
}
