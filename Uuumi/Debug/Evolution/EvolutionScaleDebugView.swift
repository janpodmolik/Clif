#if DEBUG
import SwiftUI

struct EvolutionScaleDebugView: View {
    @State private var selectedWindLevel: WindLevel = .none
    @State private var showCopiedFeedback: Bool = false

    // Whether blob is selected (true) or an essence tree (false)
    @State private var isBlobSelected: Bool = true

    // Selected essence (only used when isBlobSelected = false)
    @State private var selectedEssence: Essence = .plant

    // Selected phase within the essence (1-indexed)
    @State private var selectedPhase: Int = 1

    // Scale values storage: [evolutionKey: scale]
    // Keys: "blob", "plant-1", "plant-2", etc.
    @State private var scales: [String: CGFloat] = [:]

    // MARK: - Computed Properties

    private var selectedPath: EvolutionPath {
        EvolutionPath.path(for: selectedEssence)
    }

    private var currentPet: any PetDisplayable {
        if isBlobSelected {
            return Blob.shared
        } else {
            return selectedPath.phase(at: selectedPhase) ?? Blob.shared
        }
    }

    private var currentKey: String {
        if isBlobSelected {
            return "blob"
        } else {
            return "\(selectedEssence.rawValue)-\(selectedPhase)"
        }
    }

    private var currentLabel: String {
        if isBlobSelected {
            return "blob"
        } else {
            return "\(selectedEssence.rawValue)-\(selectedPhase)"
        }
    }

    private var currentAssetName: String {
        currentPet.assetName(for: selectedWindLevel)
    }

    private var currentScale: CGFloat {
        scales[currentKey] ?? currentPet.displayScale
    }

    private var currentScaleBinding: Binding<CGFloat> {
        Binding(
            get: { scales[currentKey] ?? currentPet.displayScale },
            set: { scales[currentKey] = $0 }
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            previewSection
                .frame(maxHeight: .infinity)

            controlsSection
        }
        .navigationTitle("Evolution Scale")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    copyConfig()
                } label: {
                    Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                        .font(.body)
                }
                .tint(showCopiedFeedback ? .green : nil)
            }
        }
        .onAppear {
            initializeScales()
        }
        .onChange(of: selectedEssence) { _, _ in
            // Reset phase to 1 when switching essence
            selectedPhase = 1
        }
    }

    private func initializeScales() {
        // Blob
        if scales["blob"] == nil {
            scales["blob"] = Blob.shared.displayScale
        }

        // All essences
        for essence in Essence.allCases {
            let path = EvolutionPath.path(for: essence)
            for phase in 1...path.maxPhases {
                let key = "\(essence.rawValue)-\(phase)"
                if scales[key] == nil {
                    scales[key] = path.phase(at: phase)?.displayScale ?? 1.0
                }
            }
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(spacing: 16) {
                    HStack {
                        Text(currentLabel)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding()

                        Spacer()

                        Text("Scale: \(currentScale, specifier: "%.2f")")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding()
                    }

                    Spacer()

                    Image(currentAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: min(proxy.size.height * 0.6, 150))
                        .scaleEffect(currentScale, anchor: .bottom)
                        .padding(.bottom, 12)
                }
            }
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        VStack(spacing: 16) {
            // Blob button + Evolution dropdown
            HStack {
                // Blob button
                Button {
                    isBlobSelected = true
                } label: {
                    Text("Blob")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            isBlobSelected
                                ? Color.green.opacity(0.3)
                                : Color.secondary.opacity(0.1),
                            in: Capsule()
                        )
                        .foregroundStyle(isBlobSelected ? .primary : .secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                // Essence dropdown
                HStack(spacing: 8) {
                    Text("Evolution")
                        .foregroundStyle(.secondary)

                    Picker("Evolution", selection: Binding(
                        get: { selectedEssence },
                        set: { newValue in
                            selectedEssence = newValue
                            isBlobSelected = false
                        }
                    )) {
                        ForEach(Essence.allCases, id: \.self) { essence in
                            Text(EvolutionPath.path(for: essence).displayName).tag(essence)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .opacity(isBlobSelected ? 0.5 : 1.0)
            }

            // Phase picker (only for essence trees with multiple phases)
            HStack {
                Text("Phase")
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("Phase", selection: $selectedPhase) {
                    ForEach(1...selectedPath.maxPhases, id: \.self) { phase in
                        Text("\(phase)").tag(phase)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: CGFloat(selectedPath.maxPhases) * 50)
            }
            .disabled(isBlobSelected || selectedPath.maxPhases < 1)

            // Wind Level picker
            HStack {
                Text("Wind Level")
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("Wind Level", selection: $selectedWindLevel) {
                    ForEach(WindLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            Divider()

            // Scale slider
            VStack(spacing: 8) {
                HStack {
                    Text("Display Scale")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text("\(currentScale, specifier: "%.2f")")
                        .font(.subheadline.monospaced())
                        .foregroundStyle(.secondary)
                }

                Slider(value: currentScaleBinding, in: 0.5...2.0, step: 0.01)
                    .tint(.green)

                HStack {
                    Text("0.5")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text("2.0")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            // Quick navigation
            HStack(spacing: 12) {
                Button {
                    navigatePrevious()
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!canNavigatePrevious)

                Button {
                    navigateNext()
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!canNavigateNext)
            }

            // Quick preset buttons
            HStack(spacing: 8) {
                presetButton("0.8", value: 0.8)
                presetButton("0.9", value: 0.9)
                presetButton("1.0", value: 1.0)
                presetButton("1.1", value: 1.1)
                presetButton("1.2", value: 1.2)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - Navigation

    private var canNavigatePrevious: Bool {
        if isBlobSelected {
            return false
        }
        if selectedPhase > 1 {
            return true
        }
        // Can go to previous essence or blob
        if let currentIndex = Essence.allCases.firstIndex(of: selectedEssence) {
            return currentIndex > 0 || true // Can always go back to blob
        }
        return true
    }

    private var canNavigateNext: Bool {
        if isBlobSelected {
            return true // Can go to first essence
        }
        if selectedPhase < selectedPath.maxPhases {
            return true
        }
        // Can go to next essence
        if let currentIndex = Essence.allCases.firstIndex(of: selectedEssence) {
            return currentIndex < Essence.allCases.count - 1
        }
        return false
    }

    private func navigatePrevious() {
        if isBlobSelected {
            return
        }

        if selectedPhase > 1 {
            selectedPhase -= 1
        } else {
            // Go to previous essence's last phase or blob
            if let currentIndex = Essence.allCases.firstIndex(of: selectedEssence), currentIndex > 0 {
                selectedEssence = Essence.allCases[currentIndex - 1]
                selectedPhase = EvolutionPath.path(for: selectedEssence).maxPhases
            } else {
                // Go to blob
                isBlobSelected = true
            }
        }
    }

    private func navigateNext() {
        if isBlobSelected {
            // Go to first essence, phase 1
            isBlobSelected = false
            selectedEssence = Essence.allCases[0]
            selectedPhase = 1
            return
        }

        if selectedPhase < selectedPath.maxPhases {
            selectedPhase += 1
        } else {
            // Go to next essence's first phase
            if let currentIndex = Essence.allCases.firstIndex(of: selectedEssence),
               currentIndex < Essence.allCases.count - 1 {
                selectedEssence = Essence.allCases[currentIndex + 1]
                selectedPhase = 1
            }
        }
    }

    // MARK: - Preset Button

    private func presetButton(_ label: String, value: CGFloat) -> some View {
        Button {
            currentScaleBinding.wrappedValue = value
        } label: {
            Text(label)
                .font(.caption.monospaced())
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(abs(currentScale - value) < 0.01 ? .green : nil)
    }

    // MARK: - Copy Config

    private func copyConfig() {
        var lines: [String] = ["// === Evolution Scale Export ==="]

        // Blob
        let blobScale = scales["blob"] ?? Blob.shared.displayScale
        lines.append("")
        lines.append("// Blob displayScale:")
        lines.append("let displayScale: CGFloat = \(String(format: "%.2f", blobScale))")

        // Group by essence
        for essence in Essence.allCases {
            let path = EvolutionPath.path(for: essence)
            lines.append("")
            lines.append("// \(path.displayName) EvolutionPhase displayScale values:")

            for phase in 1...path.maxPhases {
                let key = "\(essence.rawValue)-\(phase)"
                let scale = scales[key] ?? path.phase(at: phase)?.displayScale ?? 1.0
                lines.append("// Phase \(phase): \(String(format: "%.2f", scale))")
            }
        }

        let export = lines.joined(separator: "\n")
        UIPasteboard.general.string = export

        withAnimation {
            showCopiedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCopiedFeedback = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        EvolutionScaleDebugView()
    }
}
#endif
