import SwiftUI

private enum JobScope: String, CaseIterable, Identifiable {
    case active, all
    var id: String { rawValue }
}

struct JobsView: View {
    @EnvironmentObject private var store: WorkspaceStore
    @State private var search = ""
    @State private var scope: JobScope = .active
    @State private var showNewJob = false

    private var filteredJobs: [CoatingJob] {
        let base = scope == .active ? store.activeJobs : store.jobs.sorted { $0.updatedAt > $1.updatedAt }
        guard !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return base }
        return base.filter {
            $0.jobNumber.localizedCaseInsensitiveContains(search) ||
            $0.customer.localizedCaseInsensitiveContains(search) ||
            $0.partName.localizedCaseInsensitiveContains(search) ||
            $0.powderSnapshot.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                EyebrowHeader(
                    eyebrow: "jobs.eyebrow",
                    title: "jobs.title",
                    subtitle: "jobs.subtitle"
                )

                HStack(spacing: 10) {
                    MetricTile(value: "\(store.activeJobs.count)", label: "jobs.active", symbol: "bolt")
                    MetricTile(value: "\(store.completedLast30Days)", label: "jobs.completed30", symbol: "checkmark.circle")
                }

                Picker("jobs.scope", selection: $scope) {
                    Text("jobs.scope.active").tag(JobScope.active)
                    Text("jobs.scope.all").tag(JobScope.all)
                }
                .pickerStyle(.segmented)

                if filteredJobs.isEmpty {
                    ContentUnavailableView(
                        "jobs.empty.title",
                        systemImage: "shippingbox",
                        description: Text("jobs.empty.detail")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 42)
                } else {
                    ForEach(filteredJobs) { job in
                        NavigationLink {
                            JobDetailView(jobID: job.id)
                        } label: {
                            JobCard(job: job)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: 920)
            .frame(maxWidth: .infinity)
        }
        .background(PRTheme.canvas)
        .navigationTitle("nav.jobs")
        .searchable(text: $search, prompt: "jobs.search")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showNewJob = true } label: {
                    Label("jobs.new", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewJob) {
            NavigationStack { JobEditorView() }
        }
    }
}

private struct JobCard: View {
    let job: CoatingJob

    var body: some View {
        RunbookCard {
            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(job.jobNumber)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(PRTheme.accent)
                        Text(job.displayTitle)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                        if !job.customer.isEmpty {
                            Text(job.customer)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 16)
                    StagePill(stage: job.stage, active: true)
                }

                HStack(spacing: 18) {
                    Label("\(job.quantity)", systemImage: "number")
                    if !job.powderSnapshot.isEmpty {
                        Label(job.powderSnapshot, systemImage: "paintpalette")
                            .lineLimit(1)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack {
                    Text(job.updatedAt, format: .dateTime.day().month(.abbreviated).hour().minute())
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}
