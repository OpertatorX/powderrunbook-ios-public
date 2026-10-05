import SwiftUI
import UIKit

@MainActor
enum PRTheme {
    static let accent = Color(red: 0.96, green: 0.40, blue: 0.16)
    static let accentSoft = accent.opacity(0.14)
    static let success = Color.green
    static let warning = Color.orange
    static let line = Color.primary.opacity(0.11)

    static var canvas: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.055, green: 0.06, blue: 0.065, alpha: 1)
                : UIColor(red: 0.965, green: 0.96, blue: 0.945, alpha: 1)
        })
    }

    static var surface: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.095, green: 0.10, blue: 0.11, alpha: 1)
                : UIColor.white
        })
    }
}

struct RunbookCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(17)
            .background(PRTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(PRTheme.line, lineWidth: 1))
    }
}

struct EyebrowHeader: View {
    let eyebrow: LocalizedStringKey
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(eyebrow)
                .font(.caption.weight(.bold))
                .foregroundStyle(PRTheme.accent)
                .textCase(.uppercase)
                .tracking(1.1)
            Text(title)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MetricTile: View {
    let value: String
    let label: LocalizedStringKey
    let symbol: String
    var body: some View {
        RunbookCard {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: symbol)
                    .font(.headline)
                    .foregroundStyle(PRTheme.accent)
                Text(value)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .monospacedDigit()
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct StagePill: View {
    let stage: JobStage
    let active: Bool
    var body: some View {
        Label(stage.title, systemImage: stage.symbol)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .foregroundStyle(active ? Color.white : Color.secondary)
            .background(active ? PRTheme.accent : Color.primary.opacity(0.07), in: Capsule())
    }
}
