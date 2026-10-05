import Foundation
import SwiftUI

enum JobStage: Int, CaseIterable, Codable, Identifiable, Hashable {
    case intake, prep, mask, coat, cure, qc, done
    var id: Int { rawValue }
    var symbol: String {
        switch self {
        case .intake: "tray.and.arrow.down"
        case .prep: "sparkles"
        case .mask: "shield.lefthalf.filled"
        case .coat: "paintbrush.pointed"
        case .cure: "thermometer.high"
        case .qc: "checkmark.seal"
        case .done: "shippingbox.and.arrow.backward"
        }
    }
    var title: LocalizedStringKey {
        switch self {
        case .intake: "stage.intake"
        case .prep: "stage.prep"
        case .mask: "stage.mask"
        case .coat: "stage.coat"
        case .cure: "stage.cure"
        case .qc: "stage.qc"
        case .done: "stage.done"
        }
    }
}

enum Substrate: String, CaseIterable, Codable, Identifiable {
    case steel, aluminum, galvanized, castIron, other
    var id: String { rawValue }
    var title: LocalizedStringKey {
        switch self {
        case .steel: "substrate.steel"
        case .aluminum: "substrate.aluminum"
        case .galvanized: "substrate.galvanized"
        case .castIron: "substrate.castiron"
        case .other: "substrate.other"
        }
    }
}

enum QCStatus: String, CaseIterable, Codable, Identifiable {
    case notChecked, accepted, rework
    var id: String { rawValue }
    var title: LocalizedStringKey {
        switch self {
        case .notChecked: "qc.not_checked"
        case .accepted: "qc.accepted"
        case .rework: "qc.rework"
        }
    }
}

enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius, fahrenheit
    var id: String { rawValue }
}

enum ThicknessUnit: String, CaseIterable, Identifiable {
    case microns, mils
    var id: String { rawValue }
}

struct PowderLot: Identifiable, Codable, Hashable {
    var id = UUID()
    var brand: String
    var colorName: String
    var colorCode: String
    var lotNumber: String
    var startingWeightGrams: Double
    var location: String
    var notes: String
    var createdAt = Date()

    var displayName: String {
        let code = colorCode.trimmingCharacters(in: .whitespacesAndNewlines)
        return code.isEmpty ? colorName : "\(colorName) \u{00B7} \(code)"
    }
}

struct CoatingJob: Identifiable, Codable, Hashable {
    var id = UUID()
    var jobNumber: String
    var customer: String
    var partName: String
    var quantity: Int
    var substrate: Substrate
    var powderLotID: UUID?
    var powderSnapshot: String
    var stage: JobStage = .intake
    var targetThicknessMicrons: Double? = nil
    var measuredThicknessMicrons: Double? = nil
    var cureTargetTempC: Double? = nil
    var cureTargetMinutes: Int? = nil
    var cureRecordedTempC: Double? = nil
    var cureRecordedMinutes: Int? = nil
    var powderUsedGrams: Double? = nil
    var prepNotes: String
    var notes: String
    var qcStatus: QCStatus = .notChecked
    var createdAt = Date()
    var updatedAt = Date()
    var completedAt: Date?

    var displayTitle: String { partName.isEmpty ? jobNumber : partName }
    var isActive: Bool { stage != .done }
}

struct WorkspaceSnapshot: Codable {
    var jobs: [CoatingJob]
    var powders: [PowderLot]
}

enum UnitMath {
    static func fahrenheit(fromCelsius value: Double) -> Double { value * 9 / 5 + 32 }
    static func celsius(fromFahrenheit value: Double) -> Double { (value - 32) * 5 / 9 }
    static func mils(fromMicrons value: Double) -> Double { value / 25.4 }
    static func microns(fromMils value: Double) -> Double { value * 25.4 }
}

