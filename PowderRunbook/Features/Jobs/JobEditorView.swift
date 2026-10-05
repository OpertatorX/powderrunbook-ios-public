import SwiftUI

struct JobEditorView: View {
    @EnvironmentObject private var store: WorkspaceStore
    @Environment(\.dismiss) private var dismiss

    private let original: CoatingJob?
    @State private var jobNumber: String
    @State private var customer: String
    @State private var partName: String
    @State private var quantity: Int
    @State private var substrate: Substrate
    @State private var selectedPowderID: UUID?
    @State private var powderName: String
    @State private var stage: JobStage
    @State private var targetThickness: String
    @State private var measuredThickness: String
    @State private var cureTargetTemp: String
    @State private var cureTargetMinutes: String
    @State private var cureRecordedTemp: String
    @State private var cureRecordedMinutes: String
    @State private var powderUsed: String
    @State private var prepNotes: String
    @State private var notes: String
    @State private var qcStatus: QCStatus

    init(job: CoatingJob? = nil) {
        original = job
        _jobNumber = State(initialValue: job?.jobNumber ?? Self.defaultJobNumber())
        _customer = State(initialValue: job?.customer ?? "")
        _partName = State(initialValue: job?.partName ?? "")
        _quantity = State(initialValue: job?.quantity ?? 1)
        _substrate = State(initialValue: job?.substrate ?? .steel)
        _selectedPowderID = State(initialValue: job?.powderLotID)
        _powderName = State(initialValue: job?.powderSnapshot ?? "")
        _stage = State(initialValue: job?.stage ?? .intake)
        _targetThickness = State(initialValue: Self.number(job?.targetThicknessMicrons))
        _measuredThickness = State(initialValue: Self.number(job?.measuredThicknessMicrons))
        _cureTargetTemp = State(initialValue: Self.number(job?.cureTargetTempC))
        _cureTargetMinutes = State(initialValue: Self.intNumber(job?.cureTargetMinutes))
        _cureRecordedTemp = State(initialValue: Self.number(job?.cureRecordedTempC))
        _cureRecordedMinutes = State(initialValue: Self.intNumber(job?.cureRecordedMinutes))
        _powderUsed = State(initialValue: Self.number(job?.powderUsedGrams))
        _prepNotes = State(initialValue: job?.prepNotes ?? "")
        _notes = State(initialValue: job?.notes ?? "")
        _qcStatus = State(initialValue: job?.qcStatus ?? .notChecked)
    }

    var body: some View {
        Form {
            Section("editor.job") {
                TextField("editor.job_number", text: $jobNumber)
                    .textInputAutocapitalization(.characters)
                TextField("editor.customer", text: $customer)
                TextField("editor.part", text: $partName)
                Stepper(value: $quantity, in: 1...9999) {
                    LabeledContent("editor.quantity", value: "\(quantity)")
                }
                Picker("editor.substrate", selection: $substrate) {
                    ForEach(Substrate.allCases) { value in Text(value.title).tag(value) }
                }
            }

            Section("editor.powder") {
                Picker("editor.powder_lot", selection: $selectedPowderID) {
                    Text("editor.no_lot").tag(UUID?.none)
                    ForEach(store.powders) { lot in
                        Text(lot.displayName).tag(Optional(lot.id))
                    }
                }
                TextField("editor.powder_freeform", text: $powderName)
                    .disabled(selectedPowderID != nil)
                TextField("editor.powder_used", text: $powderUsed)
                    .keyboardType(.decimalPad)
            }

            Section("editor.targets") {
                TextField("editor.target_thickness", text: $targetThickness)
                    .keyboardType(.decimalPad)
                TextField("editor.cure_target_temp", text: $cureTargetTemp)
                    .keyboardType(.decimalPad)
                TextField("editor.cure_target_minutes", text: $cureTargetMinutes)
                    .keyboardType(.numberPad)
            }

            Section("editor.recorded") {
                TextField("editor.measured_thickness", text: $measuredThickness)
                    .keyboardType(.decimalPad)
                TextField("editor.cure_recorded_temp", text: $cureRecordedTemp)
                    .keyboardType(.decimalPad)
                TextField("editor.cure_recorded_minutes", text: $cureRecordedMinutes)
                    .keyboardType(.numberPad)
                Picker("editor.qc", selection: $qcStatus) {
                    ForEach(QCStatus.allCases) { status in Text(status.title).tag(status) }
                }
                if original != nil {
                    Picker("editor.stage", selection: $stage) {
                        ForEach(JobStage.allCases) { value in Text(value.title).tag(value) }
                    }
                }
            }

            Section("editor.notes") {
                TextField("editor.prep_notes", text: $prepNotes, axis: .vertical)
                    .lineLimit(2...5)
                TextField("editor.job_notes", text: $notes, axis: .vertical)
                    .lineLimit(2...6)
            }

            Section {
                Text("editor.disclaimer")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(original == nil ? "editor.new_title" : "editor.edit_title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("action.cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("action.save") { save() }
                    .fontWeight(.semibold)
                    .disabled(jobNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || partName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func save() {
        let selectedLot = selectedPowderID.flatMap { id in store.powders.first { $0.id == id } }
        var value = original ?? CoatingJob(
            jobNumber: jobNumber,
            customer: customer,
            partName: partName,
            quantity: quantity,
            substrate: substrate,
            powderLotID: selectedPowderID,
            powderSnapshot: selectedLot?.displayName ?? powderName,
            prepNotes: prepNotes,
            notes: notes
        )
        value.jobNumber = jobNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        value.customer = customer.trimmingCharacters(in: .whitespacesAndNewlines)
        value.partName = partName.trimmingCharacters(in: .whitespacesAndNewlines)
        value.quantity = quantity
        value.substrate = substrate
        value.powderLotID = selectedPowderID
        value.powderSnapshot = selectedLot?.displayName ?? powderName.trimmingCharacters(in: .whitespacesAndNewlines)
        value.stage = stage
        value.targetThicknessMicrons = decimal(targetThickness)
        value.measuredThicknessMicrons = decimal(measuredThickness)
        value.cureTargetTempC = decimal(cureTargetTemp)
        value.cureTargetMinutes = Int(cureTargetMinutes)
        value.cureRecordedTempC = decimal(cureRecordedTemp)
        value.cureRecordedMinutes = Int(cureRecordedMinutes)
        value.powderUsedGrams = decimal(powderUsed)
        value.prepNotes = prepNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        value.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        value.qcStatus = qcStatus
        store.saveJob(value)
        dismiss()
    }

    private func decimal(_ text: String) -> Double? {
        guard let value = Double(text.replacingOccurrences(of: ",", with: ".")), value >= 0 else { return nil }
        return value
    }

    private static func defaultJobNumber() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMdd-HHmm"
        return "JOB-\(formatter.string(from: Date()))"
    }
    private static func number(_ value: Double?) -> String { value.map { String(format: "%.1f", $0) } ?? "" }
    private static func intNumber(_ value: Int?) -> String { value.map(String.init) ?? "" }
}
