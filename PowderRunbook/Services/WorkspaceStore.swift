import Foundation
import SwiftUI
import UIKit

@MainActor
final class WorkspaceStore: ObservableObject {
    @Published var jobs: [CoatingJob] = []
    @Published var powders: [PowderLot] = []

    @AppStorage("temperatureUnit") private var storedTemperatureUnit = TemperatureUnit.celsius.rawValue
    @AppStorage("thicknessUnit") private var storedThicknessUnit = ThicknessUnit.microns.rawValue

    var temperatureUnit: TemperatureUnit {
        get { TemperatureUnit(rawValue: storedTemperatureUnit) ?? .celsius }
        set { storedTemperatureUnit = newValue.rawValue; objectWillChange.send() }
    }

    var thicknessUnit: ThicknessUnit {
        get { ThicknessUnit(rawValue: storedThicknessUnit) ?? .microns }
        set { storedThicknessUnit = newValue.rawValue; objectWillChange.send() }
    }

    init() {
        load()
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-store-demo") { seedScreenshotData() }
    }

    var activeJobs: [CoatingJob] {
        jobs.filter(\.isActive).sorted { $0.updatedAt > $1.updatedAt }
    }

    var completedJobs: [CoatingJob] {
        jobs.filter { !$0.isActive }.sorted { ($0.completedAt ?? $0.updatedAt) > ($1.completedAt ?? $1.updatedAt) }
    }

    var completedLast30Days: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? .distantPast
        return jobs.filter { ($0.completedAt ?? .distantPast) >= cutoff }.count
    }

    func powder(for job: CoatingJob) -> PowderLot? {
        guard let id = job.powderLotID else { return nil }
        return powders.first { $0.id == id }
    }

    func remainingGrams(for lot: PowderLot) -> Double {
        let used = jobs.filter { $0.powderLotID == lot.id }.compactMap(\.powderUsedGrams).reduce(0, +)
        return max(0, lot.startingWeightGrams - used)
    }

    func saveJob(_ job: CoatingJob) {
        var value = job
        value.updatedAt = Date()
        if value.stage == .done && value.completedAt == nil { value.completedAt = Date() }
        if value.stage != .done { value.completedAt = nil }
        if let index = jobs.firstIndex(where: { $0.id == value.id }) {
            jobs[index] = value
        } else {
            jobs.insert(value, at: 0)
        }
        persistAndTap()
    }

    func advance(_ job: CoatingJob) {
        guard let index = jobs.firstIndex(where: { $0.id == job.id }),
              let next = JobStage(rawValue: min(JobStage.done.rawValue, jobs[index].stage.rawValue + 1)) else { return }
        jobs[index].stage = next
        jobs[index].updatedAt = Date()
        if next == .done { jobs[index].completedAt = Date() }
        persistAndTap()
    }

    func deleteJob(_ job: CoatingJob) {
        jobs.removeAll { $0.id == job.id }
        persistAndTap()
    }

    func savePowder(_ lot: PowderLot) {
        if let index = powders.firstIndex(where: { $0.id == lot.id }) {
            powders[index] = lot
        } else {
            powders.insert(lot, at: 0)
        }
        persistAndTap()
    }

    func deletePowder(_ lot: PowderLot) {
        powders.removeAll { $0.id == lot.id }
        persistAndTap()
    }

    private var fileURL: URL {
        let manager = FileManager.default
        let base = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("PowderRunbook", isDirectory: true)
        try? manager.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("workspace.json")
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let snapshot = try? JSONDecoder.runbook.decode(WorkspaceSnapshot.self, from: data) else { return }
        jobs = snapshot.jobs
        powders = snapshot.powders
    }

    private func persistAndTap() {
        let snapshot = WorkspaceSnapshot(jobs: jobs, powders: powders)
        if let data = try? JSONEncoder.runbook.encode(snapshot) {
            try? data.write(to: fileURL, options: .atomic)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func seedScreenshotData() {
        let black = PowderLot(brand: "Prismatic", colorName: "Satin Black", colorCode: "RAL 9005", lotNumber: "SB-2408", startingWeightGrams: 5000, location: "Rack A3", notes: "")
        let bronze = PowderLot(brand: "IGP", colorName: "Bronze Fine Texture", colorCode: "BRZ-42", lotNumber: "IGP-7719", startingWeightGrams: 3500, location: "Rack B1", notes: "")
        powders = [black, bronze]
        jobs = [
            CoatingJob(jobNumber: "JOB-1048", customer: "Northline Fabrication", partName: "Stair brackets", quantity: 24, substrate: .steel, powderLotID: black.id, powderSnapshot: black.displayName, stage: .cure, targetThicknessMicrons: 80, measuredThicknessMicrons: nil, cureTargetTempC: 190, cureTargetMinutes: 12, cureRecordedTempC: 188, cureRecordedMinutes: 8, powderUsedGrams: 640, prepNotes: "Blast to clean profile · degrease", notes: "Rack 2 · hooks clear", qcStatus: .notChecked),
            CoatingJob(jobNumber: "JOB-1046", customer: "Atelier Rivet", partName: "Display frames", quantity: 8, substrate: .aluminum, powderLotID: bronze.id, powderSnapshot: bronze.displayName, stage: .qc, targetThicknessMicrons: 70, measuredThicknessMicrons: 74, cureTargetTempC: 180, cureTargetMinutes: 15, cureRecordedTempC: 181, cureRecordedMinutes: 16, powderUsedGrams: 410, prepNotes: "Clean + conversion coat", notes: "Check two inside corners", qcStatus: .accepted),
            CoatingJob(jobNumber: "JOB-1042", customer: "Studio Huit", partName: "Table bases", quantity: 6, substrate: .steel, powderLotID: black.id, powderSnapshot: black.displayName, stage: .done, targetThicknessMicrons: 80, measuredThicknessMicrons: 83, cureTargetTempC: 190, cureTargetMinutes: 12, cureRecordedTempC: 191, cureRecordedMinutes: 13, powderUsedGrams: 520, prepNotes: "Blast + phosphate wash", notes: "Packed in foam sleeves", qcStatus: .accepted, createdAt: Date().addingTimeInterval(-172800), updatedAt: Date().addingTimeInterval(-86400), completedAt: Date().addingTimeInterval(-86400))
        ]
    }
}

private extension JSONEncoder {
    static var runbook: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var runbook: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
