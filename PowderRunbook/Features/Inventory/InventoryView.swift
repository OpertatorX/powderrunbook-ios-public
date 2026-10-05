import SwiftUI

struct InventoryView: View {
    @EnvironmentObject private var store: WorkspaceStore
    @State private var showNewPowder = false
    @State private var editingLot: PowderLot?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                EyebrowHeader(
                    eyebrow: "inventory.eyebrow",
                    title: "inventory.title",
                    subtitle: "inventory.subtitle"
                )

                if store.powders.isEmpty {
                    ContentUnavailableView(
                        "inventory.empty.title",
                        systemImage: "paintpalette",
                        description: Text("inventory.empty.detail")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 44)
                } else {
                    ForEach(store.powders) { lot in
                        powderCard(lot)
                            .contextMenu {
                                Button("action.edit", systemImage: "pencil") { editingLot = lot }
                                Button("action.delete", systemImage: "trash", role: .destructive) { store.deletePowder(lot) }
                            }
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: 920)
            .frame(maxWidth: .infinity)
        }
        .background(PRTheme.canvas)
        .navigationTitle("nav.inventory")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showNewPowder = true } label: {
                    Label("inventory.new", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewPowder) {
            NavigationStack { PowderEditorView() }
        }
        .sheet(item: $editingLot) { lot in
            NavigationStack { PowderEditorView(lot: lot) }
        }
    }

    private func powderCard(_ lot: PowderLot) -> some View {
        let remaining = store.remainingGrams(for: lot)
        let progress = lot.startingWeightGrams > 0 ? remaining / lot.startingWeightGrams : 0
        return RunbookCard {
            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lot.brand.uppercased())
                            .font(.caption2.weight(.bold))
                            .tracking(1)
                            .foregroundStyle(PRTheme.accent)
                        Text(lot.displayName)
                            .font(.title3.weight(.semibold))
                        if !lot.lotNumber.isEmpty {
                            Text("Lot \(lot.lotNumber)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(String(format: "%.2f kg", remaining / 1000))
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .monospacedDigit()
                }
                ProgressView(value: progress)
                    .tint(progress < 0.2 ? Color.orange : PRTheme.accent)
                HStack {
                    Label(lot.location.isEmpty ? String(localized: "inventory.no_location") : lot.location, systemImage: "shippingbox")
                    Spacer()
                    Text(String(format: "%.2f kg", lot.startingWeightGrams / 1000))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        }
    }
}

struct PowderEditorView: View {
    @EnvironmentObject private var store: WorkspaceStore
    @Environment(\.dismiss) private var dismiss
    private let original: PowderLot?
    @State private var brand: String
    @State private var colorName: String
    @State private var colorCode: String
    @State private var lotNumber: String
    @State private var startingWeight: String
    @State private var location: String
    @State private var notes: String

    init(lot: PowderLot? = nil) {
        original = lot
        _brand = State(initialValue: lot?.brand ?? "")
        _colorName = State(initialValue: lot?.colorName ?? "")
        _colorCode = State(initialValue: lot?.colorCode ?? "")
        _lotNumber = State(initialValue: lot?.lotNumber ?? "")
        _startingWeight = State(initialValue: lot.map { String(format: "%.0f", $0.startingWeightGrams) } ?? "")
        _location = State(initialValue: lot?.location ?? "")
        _notes = State(initialValue: lot?.notes ?? "")
    }

    var body: some View {
        Form {
            Section("powder.identity") {
                TextField("powder.brand", text: $brand)
                TextField("powder.color_name", text: $colorName)
                TextField("powder.color_code", text: $colorCode)
                TextField("powder.lot_number", text: $lotNumber)
            }
            Section("powder.stock") {
                TextField("powder.starting_weight", text: $startingWeight)
                    .keyboardType(.decimalPad)
                TextField("powder.location", text: $location)
            }
            Section("powder.notes") {
                TextField("powder.notes", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
            }
        }
        .navigationTitle(original == nil ? "powder.new_title" : "powder.edit_title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("action.cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("action.save") { save() }
                    .fontWeight(.semibold)
                    .disabled(colorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || weight == nil)
            }
        }
    }

    private var weight: Double? { Double(startingWeight.replacingOccurrences(of: ",", with: ".")) }

    private func save() {
        guard let weight else { return }
        var value = original ?? PowderLot(
            brand: brand,
            colorName: colorName,
            colorCode: colorCode,
            lotNumber: lotNumber,
            startingWeightGrams: weight,
            location: location,
            notes: notes
        )
        value.brand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        value.colorName = colorName.trimmingCharacters(in: .whitespacesAndNewlines)
        value.colorCode = colorCode.trimmingCharacters(in: .whitespacesAndNewlines)
        value.lotNumber = lotNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        value.startingWeightGrams = weight
        value.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        value.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        store.savePowder(value)
        dismiss()
    }
}
