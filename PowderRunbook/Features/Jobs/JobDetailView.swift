import SwiftUI

struct JobDetailView: View {
    @EnvironmentObject private var store: WorkspaceStore
    @Environment(\.dismiss) private var dismiss
    let jobID: UUID
    @State private var showEdit = false
    @State private var showDelete = false

    private var job: CoatingJob? { store.jobs.first { $0.id == jobID } }

    var body: some View {
        Group {
            if let job {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header(job)
                        stageRail(job)
                        processCard(job)
                        cureCard(job)
                        qcCard(job)
                        notesCard(job)
                        safetyNote
                    }
                    .padding(18)
                    .frame(maxWidth: 900)
                    .frame(maxWidth: .infinity)
                }
                .background(PRTheme.canvas)
                .navigationTitle(job.jobNumber)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbar(job) }
                .sheet(isPresented: $showEdit) {
                    NavigationStack { JobEditorView(job: job) }
                }
                .confirmationDialog("job.delete.title", isPresented: $showDelete, titleVisibility: .visible) {
                    Button("job.delete.action", role: .destructive) {
                        store.deleteJob(job)
                        dismiss()
                    }
                }
            } else {
                ContentUnavailableView("job.missing", systemImage: "questionmark.folder")
            }
        }
    }

    private func header(_ job: CoatingJob) -> some View {
        RunbookCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(job.displayTitle)
                            .font(.system(.title, design: .rounded, weight: .bold))
                        if !job.customer.isEmpty {
                            Text(job.customer).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    StagePill(stage: job.stage, active: true)
                }
                HStack(spacing: 18) {
                    Label("\(job.quantity)", systemImage: "number")
                    Label(String(localized: String.LocalizationValue(job.substrate.rawValue)), systemImage: "square.stack.3d.up")
                    if !job.powderSnapshot.isEmpty {
                        Label(job.powderSnapshot, systemImage: "paintpalette").lineLimit(1)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func stageRail(_ job: CoatingJob) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("job.workflow").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(JobStage.allCases) { stage in
                        StagePill(stage: stage, active: stage.rawValue <= job.stage.rawValue)
                    }
                }
            }
            if job.stage != .done {
                Button {
                    store.advance(job)
                } label: {
                    Label("job.advance", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    private func processCard(_ job: CoatingJob) -> some View {
        RunbookCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("job.process", systemImage: "slider.horizontal.3")
                    .font(.headline)
                LabeledContent("job.substrate", value: localizedSubstrate(job.substrate))
                LabeledContent("job.target_thickness", value: thickness(job.targetThicknessMicrons))
                LabeledContent("job.measured_thickness", value: thickness(job.measuredThicknessMicrons))
                LabeledContent("job.powder_used", value: grams(job.powderUsedGrams))
                if !job.prepNotes.isEmpty {
                    Divider()
                    Text(job.prepNotes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func cureCard(_ job: CoatingJob) -> some View {
        RunbookCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("job.cure_record", systemImage: "thermometer.high")
                    .font(.headline)
                LabeledContent("job.target_temperature", value: temperature(job.cureTargetTempC))
                LabeledContent("job.target_time", value: minutes(job.cureTargetMinutes))
                Divider()
                LabeledContent("job.recorded_temperature", value: temperature(job.cureRecordedTempC))
                LabeledContent("job.recorded_time", value: minutes(job.cureRecordedMinutes))
                Text("job.cure_disclaimer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func qcCard(_ job: CoatingJob) -> some View {
        RunbookCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("job.qc", systemImage: "checkmark.seal")
                    .font(.headline)
                HStack {
                    Text("job.qc_status")
                    Spacer()
                    Text(job.qcStatus.title)
                        .fontWeight(.semibold)
                        .foregroundStyle(job.qcStatus == .accepted ? Color.green : (job.qcStatus == .rework ? Color.orange : Color.secondary))
                }
                Text("job.qc_disclaimer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func notesCard(_ job: CoatingJob) -> some View {
        if !job.notes.isEmpty {
            RunbookCard {
                VStack(alignment: .leading, spacing: 10) {
                    Label("job.notes", systemImage: "note.text")
                        .font(.headline)
                    Text(job.notes).font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var safetyNote: some View {
        Label("job.safety", systemImage: "info.circle")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }

    @ToolbarContentBuilder
    private func toolbar(_ job: CoatingJob) -> some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            ShareLink(item: exportText(job)) {
                Image(systemName: "square.and.arrow.up")
            }
            Menu {
                Button("action.edit", systemImage: "pencil") { showEdit = true }
                Button("job.delete.action", systemImage: "trash", role: .destructive) { showDelete = true }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    private func localizedSubstrate(_ value: Substrate) -> String {
        String(localized: String.LocalizationValue("substrate.\(value.rawValue)"))
    }
    private func thickness(_ value: Double?) -> String {
        guard let value else { return "—" }
        if store.thicknessUnit == .mils { return String(format: "%.2f mil", UnitMath.mils(fromMicrons: value)) }
        return String(format: "%.0f µm", value)
    }
    private func temperature(_ value: Double?) -> String {
        guard let value else { return "—" }
        if store.temperatureUnit == .fahrenheit { return String(format: "%.0f °F", UnitMath.fahrenheit(fromCelsius: value)) }
        return String(format: "%.0f °C", value)
    }
    private func minutes(_ value: Int?) -> String { value.map { "\($0) min" } ?? "—" }
    private func grams(_ value: Double?) -> String { value.map { String(format: "%.0f g", $0) } ?? "—" }

    private func exportText(_ job: CoatingJob) -> String {
        [
            "PowderRunbook · \(job.jobNumber)",
            job.displayTitle,
            job.customer,
            "Stage: \(job.stage)",
            "Powder: \(job.powderSnapshot)",
            "Target thickness: \(thickness(job.targetThicknessMicrons))",
            "Measured thickness: \(thickness(job.measuredThicknessMicrons))",
            "Target cure: \(temperature(job.cureTargetTempC)) · \(minutes(job.cureTargetMinutes))",
            "Recorded cure: \(temperature(job.cureRecordedTempC)) · \(minutes(job.cureRecordedMinutes))",
            "QC: \(job.qcStatus.rawValue)",
            job.notes
        ].filter { !$0.isEmpty }.joined(separator: "\n")
    }
}
