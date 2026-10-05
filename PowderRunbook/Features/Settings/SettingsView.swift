import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: WorkspaceStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                EyebrowHeader(
                    eyebrow: "settings.eyebrow",
                    title: "settings.title",
                    subtitle: "settings.subtitle"
                )

                RunbookCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("settings.units", systemImage: "ruler")
                            .font(.headline)
                        Picker("settings.temperature", selection: Binding(
                            get: { store.temperatureUnit },
                            set: { store.temperatureUnit = $0 }
                        )) {
                            Text("settings.celsius").tag(TemperatureUnit.celsius)
                            Text("settings.fahrenheit").tag(TemperatureUnit.fahrenheit)
                        }
                        .pickerStyle(.segmented)

                        Picker("settings.thickness", selection: Binding(
                            get: { store.thicknessUnit },
                            set: { store.thicknessUnit = $0 }
                        )) {
                            Text("settings.microns").tag(ThicknessUnit.microns)
                            Text("settings.mils").tag(ThicknessUnit.mils)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                RunbookCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("settings.privacy", systemImage: "hand.raised")
                            .font(.headline)
                        Text("settings.privacy_detail")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                RunbookCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("settings.process", systemImage: "exclamationmark.shield")
                            .font(.headline)
                        Text("settings.process_detail")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                RunbookCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("settings.about", systemImage: "info.circle")
                            .font(.headline)
                        Text("settings.about_detail")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Divider()
                        LabeledContent("settings.version", value: version)
                            .font(.subheadline)
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: 820)
            .frame(maxWidth: .infinity)
        }
        .background(PRTheme.canvas)
        .navigationTitle("nav.settings")
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
}
