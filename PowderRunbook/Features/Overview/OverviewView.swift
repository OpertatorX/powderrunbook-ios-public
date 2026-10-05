import SwiftUI
import Charts

struct OverviewView: View {
    @EnvironmentObject private var store: WorkspaceStore

    private var stageCounts: [(JobStage, Int)] {
        JobStage.allCases.filter { $0 != .done }.map { stage in
            (stage, store.activeJobs.filter { $0.stage == stage }.count)
        }
    }

    private var recordedPowderGrams: Double {
        store.jobs.compactMap(\.powderUsedGrams).reduce(0, +)
    }

    private var lowStockCount: Int {
        store.powders.filter { lot in
            guard lot.startingWeightGrams > 0 else { return false }
            return store.remainingGrams(for: lot) / lot.startingWeightGrams < 0.2
        }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                EyebrowHeader(
                    eyebrow: "overview.eyebrow",
                    title: "overview.title",
                    subtitle: "overview.subtitle"
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    MetricTile(value: "\(store.activeJobs.count)", label: "overview.active", symbol: "bolt")
                    MetricTile(value: "\(store.completedLast30Days)", label: "overview.completed", symbol: "checkmark.seal")
                    MetricTile(value: String(format: "%.1f kg", recordedPowderGrams / 1000), label: "overview.powder_used", symbol: "scalemass")
                    MetricTile(value: "\(lowStockCount)", label: "overview.low_stock", symbol: "exclamationmark.triangle")
                }

                RunbookCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("overview.pipeline")
                            .font(.headline)
                        Chart(stageCounts, id: \.0) { item in
                            BarMark(
                                x: .value("Stage", stageName(item.0)),
                                y: .value("Jobs", item.1)
                            )
                            .foregroundStyle(PRTheme.accent.gradient)
                            .cornerRadius(5)
                        }
                        .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) }
                        .frame(height: 220)
                    }
                }

                RunbookCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("overview.recent")
                                .font(.headline)
                            Spacer()
                            Text("\(store.completedJobs.prefix(4).count)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(PRTheme.accent)
                        }
                        if store.completedJobs.isEmpty {
                            Text("overview.no_completed")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(Array(store.completedJobs.prefix(4).enumerated()), id: \.element.id) { index, job in
                                if index > 0 { Divider() }
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(job.displayTitle).font(.subheadline.weight(.semibold))
                                        Text(job.jobNumber).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if let completedAt = job.completedAt {
                                        Text(completedAt, format: .dateTime.day().month(.abbreviated))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: 920)
            .frame(maxWidth: .infinity)
        }
        .background(PRTheme.canvas)
        .navigationTitle("nav.overview")
    }

    private func stageName(_ stage: JobStage) -> String {
        switch stage {
        case .intake: String(localized: "stage.intake")
        case .prep: String(localized: "stage.prep")
        case .mask: String(localized: "stage.mask")
        case .coat: String(localized: "stage.coat")
        case .cure: String(localized: "stage.cure")
        case .qc: String(localized: "stage.qc")
        case .done: String(localized: "stage.done")
        }
    }
}
