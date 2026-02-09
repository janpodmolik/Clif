import SwiftUI

// MARK: - Status Filter Sheet

struct StatusFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: PetSearchFilter.StatusFilter

    var body: some View {
        NavigationStack {
            List {
                ForEach(PetSearchFilter.StatusFilter.allCases) { status in
                    Button {
                        selection = status
                        dismiss()
                    } label: {
                        HStack {
                            Label(status.rawValue, systemImage: status.icon)
                                .foregroundStyle(.primary)

                            Spacer()

                            if selection == status {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Stav")
            .navigationBarTitleDisplayMode(.inline)
            .dismissButton()
        }
        .tint(.primary)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Date Filter Sheet

struct DateFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var dateRange: PetSearchFilter.DateRange
    @Binding var customStart: Date?
    @Binding var customEnd: Date?

    private var isFiltered: Bool {
        dateRange != .all
    }

    private var selectableRanges: [PetSearchFilter.DateRange] {
        PetSearchFilter.DateRange.allCases.filter { $0 != .all }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(selectableRanges) { range in
                    Button {
                        dateRange = range
                        if range != .custom {
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Text(range.rawValue)
                                .foregroundStyle(.primary)

                            Spacer()

                            if dateRange == range {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }

                if dateRange == .custom {
                    DatePicker(
                        "Od",
                        selection: Binding(
                            get: { customStart ?? Date() },
                            set: {
                                customStart = $0
                                if let end = customEnd, $0 > end {
                                    customEnd = $0
                                }
                            }
                        ),
                        in: ...Date(),
                        displayedComponents: .date
                    )

                    DatePicker(
                        "Do",
                        selection: Binding(
                            get: { customEnd ?? Date() },
                            set: { customEnd = $0 }
                        ),
                        in: (customStart ?? .distantPast)...Date(),
                        displayedComponents: .date
                    )
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Období")
            .navigationBarTitleDisplayMode(.inline)
            .dismissButton()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if isFiltered {
                        Button("Reset") {
                            dateRange = .all
                            customStart = nil
                            customEnd = nil
                            dismiss()
                        }
                    }
                }
            }
        }
        .tint(.primary)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Duration Filter Sheet

struct DurationFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var minDuration: Int
    @Binding var maxDuration: Int

    private var isFiltered: Bool {
        minDuration > PetSearchFilter.durationRange.lowerBound ||
        maxDuration < PetSearchFilter.durationRange.upperBound
    }

    private var durationLabel: String {
        if minDuration == 0 && maxDuration >= 60 {
            return "Vše"
        } else if maxDuration >= 60 {
            return "\(minDuration)+ dní"
        } else if minDuration == 0 {
            return "do \(maxDuration) dní"
        } else {
            return "\(minDuration)-\(maxDuration) dní"
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Aktuální rozsah")
                            Spacer()
                            Text(durationLabel)
                                .foregroundStyle(.secondary)
                        }

                        VStack(spacing: 12) {
                            HStack {
                                Text("Min: \(minDuration) dní")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }

                            Slider(
                                value: Binding(
                                    get: { Double(minDuration) },
                                    set: { newValue in
                                        let intValue = Int(newValue)
                                        if intValue < maxDuration {
                                            minDuration = intValue
                                        }
                                    }
                                ),
                                in: Double(PetSearchFilter.durationRange.lowerBound)...Double(PetSearchFilter.durationRange.upperBound),
                                step: 1
                            )

                            HStack {
                                Text("Max: \(maxDuration >= 60 ? "60+" : "\(maxDuration)") dní")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }

                            Slider(
                                value: Binding(
                                    get: { Double(maxDuration) },
                                    set: { newValue in
                                        let intValue = Int(newValue)
                                        if intValue > minDuration {
                                            maxDuration = intValue
                                        }
                                    }
                                ),
                                in: Double(PetSearchFilter.durationRange.lowerBound)...Double(PetSearchFilter.durationRange.upperBound),
                                step: 1
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }

            }
            .listStyle(.insetGrouped)
            .navigationTitle("Délka života")
            .navigationBarTitleDisplayMode(.inline)
            .dismissButton()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if isFiltered {
                        Button("Reset") {
                            minDuration = PetSearchFilter.durationRange.lowerBound
                            maxDuration = PetSearchFilter.durationRange.upperBound
                            dismiss()
                        }
                    }
                }
            }
        }
        .tint(.primary)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Essence Filter Sheet

struct EssenceFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: Set<Essence>

    private var allSelected: Bool {
        selection == Set(Essence.allCases)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(Essence.allCases, id: \.self) { essence in
                    let path = EvolutionPath.path(for: essence)
                    Button {
                        if selection.contains(essence) {
                            selection.remove(essence)
                        } else {
                            selection.insert(essence)
                        }
                    } label: {
                        HStack {
                            Image(essence.assetName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)

                            Text(path.displayName)
                                .foregroundStyle(.primary)

                            Spacer()

                            if selection.contains(essence) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(path.themeColor)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Essence")
            .navigationBarTitleDisplayMode(.inline)
            .dismissButton()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(allSelected ? "Odvybrat vše" : "Vybrat vše") {
                        if allSelected {
                            selection = []
                        } else {
                            selection = Set(Essence.allCases)
                        }
                    }
                }
            }
        }
        .tint(.primary)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview("Status") {
    StatusFilterSheet(selection: .constant(.all))
}

#Preview("Date") {
    DateFilterSheet(
        dateRange: .constant(.all),
        customStart: .constant(nil),
        customEnd: .constant(nil)
    )
}

#Preview("Duration") {
    DurationFilterSheet(
        minDuration: .constant(0),
        maxDuration: .constant(60)
    )
}

#Preview("Essence") {
    EssenceFilterSheet(selection: .constant(Set(Essence.allCases)))
}
