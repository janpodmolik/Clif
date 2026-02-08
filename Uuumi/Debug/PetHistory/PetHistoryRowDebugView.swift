#if DEBUG
import SwiftUI

struct PetHistoryRowDebugView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: - Pet Identity State

    @State private var petName: String = "Fern"
    @State private var purpose: String = "Social Media"
    @State private var phase: Int = 4
    private let maxPhase = 4

    // MARK: - Status State

    @State private var archiveReason: ArchiveReason = .completed
    @State private var totalDays: Int = 21
    @State private var daysAgo: Int = 14

    // MARK: - Section Expansion

    @State private var isPetSectionExpanded: Bool = true
    @State private var isStatusSectionExpanded: Bool = true
    @State private var isPresetsSectionExpanded: Bool = true

    // MARK: - Computed Properties

    private var currentPet: ArchivedPetSummary {
        ArchivedPetSummary.mock(
            name: petName,
            phase: phase,
            archiveReason: archiveReason,
            totalDays: totalDays
        )
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                previewSection
                    .frame(maxHeight: .infinity)

                Divider()

                controlsPanel
            }
        }
        .navigationTitle("PetHistoryRow Debug")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        ZStack {
            LinearGradient(
                colors: [.indigo.opacity(0.2), .purple.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                ArchivedPetRow(pet: currentPet) {
                    print("Row tapped: \(currentPet.name)")
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Controls Panel

    private var controlsPanel: some View {
        ScrollView {
            VStack(spacing: 16) {
                petIdentitySection
                statusSection
                presetsSection
            }
            .padding()
        }
        .frame(height: 380)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Pet Identity Section

    private var petIdentitySection: some View {
        collapsibleSection(
            title: "Pet Identity",
            systemImage: "leaf.fill",
            isExpanded: $isPetSectionExpanded
        ) {
            VStack(spacing: 12) {
                HStack {
                    Text("Name")
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField("Pet name", text: $petName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 150)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Purpose")
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField("e.g. Social Media", text: $purpose)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 150)
                        .multilineTextAlignment(.trailing)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Phase")
                        .foregroundStyle(.secondary)

                    Picker("Phase", selection: $phase) {
                        ForEach(1...maxPhase, id: \.self) { p in
                            Text("\(p)").tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        collapsibleSection(
            title: "Status",
            systemImage: "chart.bar.fill",
            isExpanded: $isStatusSectionExpanded
        ) {
            VStack(spacing: 12) {
                Picker("Archive Reason", selection: $archiveReason) {
                    Text("Blown").tag(ArchiveReason.blown)
                    Text("Completed").tag(ArchiveReason.completed)
                    Text("Lost").tag(ArchiveReason.lost)
                    Text("Manual").tag(ArchiveReason.manual)
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("Total Days")
                        .foregroundStyle(.secondary)
                    Spacer()
                    HStack(spacing: 12) {
                        Button {
                            if totalDays > 1 { totalDays -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }

                        Text("\(totalDays)")
                            .font(.system(.body, design: .monospaced, weight: .semibold))
                            .frame(width: 40)

                        Button {
                            totalDays += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                HStack {
                    Text("Days Ago")
                        .foregroundStyle(.secondary)
                    Spacer()
                    HStack(spacing: 12) {
                        Button {
                            if daysAgo > 0 { daysAgo -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }

                        Text("\(daysAgo)")
                            .font(.system(.body, design: .monospaced, weight: .semibold))
                            .frame(width: 40)

                        Button {
                            daysAgo += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.purple)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Presets Section

    private var presetsSection: some View {
        collapsibleSection(
            title: "Quick Presets",
            systemImage: "sparkles.rectangle.stack",
            isExpanded: $isPresetsSectionExpanded
        ) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                presetButton("Completed", color: .green) { applyCompletedPreset() }
                presetButton("Blown Away", color: .red) { applyBlownAwayPreset() }
                presetButton("New Archived", color: .mint) { applyNewArchivedPreset() }
                presetButton("Long Journey", color: .purple) { applyLongJourneyPreset() }
                presetButton("Max Stats", color: .orange) { applyMaxStatsPreset() }
                presetButton("Early Fail", color: .gray) { applyEarlyFailPreset() }
            }
        }
    }

    private func presetButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preset Actions

    private func applyCompletedPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Elder Oak"
            purpose = "Social Media"
            phase = 4
            archiveReason = .completed
            totalDays = 35
            daysAgo = 7
        }
    }

    private func applyBlownAwayPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Sprout"
            purpose = "Gaming"
            phase = 2
            archiveReason = .blown
            totalDays = 3
            daysAgo = 2
        }
    }

    private func applyNewArchivedPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Seedling"
            purpose = "Work Apps"
            phase = 1
            archiveReason = .completed
            totalDays = 5
            daysAgo = 1
        }
    }

    private func applyLongJourneyPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Moss"
            purpose = "Entertainment"
            phase = 3
            archiveReason = .completed
            totalDays = 28
            daysAgo = 30
        }
    }

    private func applyMaxStatsPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Ancient Fern"
            purpose = "All Apps"
            phase = 4
            archiveReason = .completed
            totalDays = 90
            daysAgo = 3
        }
    }

    private func applyEarlyFailPreset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            petName = "Leaf"
            purpose = "Streaming"
            phase = 1
            archiveReason = .blown
            totalDays = 2
            daysAgo = 5
        }
    }

    // MARK: - Collapsible Section

    @ViewBuilder
    private func collapsibleSection<Content: View>(
        title: String,
        systemImage: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack {
                    Label(title, systemImage: systemImage)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded.wrappedValue {
                content()
                    .padding(.bottom, 12)
            }
        }
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        PetHistoryRowDebugView()
    }
}
#endif
