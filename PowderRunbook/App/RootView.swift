import SwiftUI

enum AppDestination: String, CaseIterable, Identifiable, Hashable {
    case jobs, inventory, overview, settings
    var id: String { rawValue }
    var title: LocalizedStringKey {
        switch self {
        case .jobs: "nav.jobs"
        case .inventory: "nav.inventory"
        case .overview: "nav.overview"
        case .settings: "nav.settings"
        }
    }
    var symbol: String {
        switch self {
        case .jobs: "shippingbox"
        case .inventory: "paintpalette"
        case .overview: "chart.bar.xaxis"
        case .settings: "slider.horizontal.3"
        }
    }
}

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selection: AppDestination

    init() {
        let arg = ProcessInfo.processInfo.arguments
            .first(where: { $0.hasPrefix("-screen=") })?
            .replacingOccurrences(of: "-screen=", with: "")
        _selection = State(initialValue: AppDestination(rawValue: arg ?? "") ?? .jobs)
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .compact { compactTabs } else { splitView }
        }
        .background(PRTheme.canvas.ignoresSafeArea())
    }

    private var compactTabs: some View {
        TabView(selection: $selection) {
            NavigationStack { JobsView() }
                .tabItem { Label(AppDestination.jobs.title, systemImage: AppDestination.jobs.symbol) }
                .tag(AppDestination.jobs)
            NavigationStack { InventoryView() }
                .tabItem { Label(AppDestination.inventory.title, systemImage: AppDestination.inventory.symbol) }
                .tag(AppDestination.inventory)
            NavigationStack { OverviewView() }
                .tabItem { Label(AppDestination.overview.title, systemImage: AppDestination.overview.symbol) }
                .tag(AppDestination.overview)
            NavigationStack { SettingsView() }
                .tabItem { Label(AppDestination.settings.title, systemImage: AppDestination.settings.symbol) }
                .tag(AppDestination.settings)
        }
    }

    private var splitView: some View {
        NavigationSplitView {
            List(AppDestination.allCases, selection: $selection) { destination in
                NavigationLink(value: destination) {
                    Label(destination.title, systemImage: destination.symbol)
                }
            }
            .navigationTitle("PowderRunbook")
            .navigationSplitViewColumnWidth(min: 210, ideal: 240)
        } detail: {
            NavigationStack { destinationView(selection) }
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func destinationView(_ destination: AppDestination) -> some View {
        switch destination {
        case .jobs: JobsView()
        case .inventory: InventoryView()
        case .overview: OverviewView()
        case .settings: SettingsView()
        }
    }
}
