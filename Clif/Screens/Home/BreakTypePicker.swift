import SwiftUI

struct BreakTypePicker: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PetManager.self) private var petManager

    var onSelectFree: () -> Void
    var onConfirmCommitted: (Int) -> Void

    @State private var selection: BreakType = .free
    @State private var selectedMinutes: Int = 30
    @State private var isUntilEndOfDay = false
    @State private var showConfirmation = false

    private var currentPet: Pet? { petManager.currentPet }
    private var currentWind: Double { currentPet?.windPoints ?? 0 }
    private var preset: WindPreset { currentPet?.preset ?? .balanced }

    private let durationSteps = [5, 10, 15, 20, 30, 45, 60, 90, 120]

    var body: some View {
        VStack(spacing: 20) {
            segmentedPicker
                .padding(.horizontal)
                .padding(.top, 8)

            Spacer()
            
            if selection == .free {
                freeContent
            } else {
                committedContent
            }

            Spacer()

            confirmButton
        }
        .presentationDetents([.medium])
        .confirmationDialog(
            "Spustit Committed Break?",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Spustit") {
                let duration = isUntilEndOfDay ? -2 : selectedMinutes
                onConfirmCommitted(duration)
                dismiss()
            }
            Button("Zrušit", role: .cancel) {}
        } message: {
            Text("Předčasné ukončení tohoto breaku způsobí okamžitou ztrátu tvého peta.")
        }
    }

    // MARK: - Segmented Picker

    private var segmentedPicker: some View {
        HStack(spacing: 0) {
            ForEach(BreakType.selectableCases, id: \.self) { type in
                Button {
                    withAnimation(.snappy(duration: 0.25)) {
                        selection = type
                        isUntilEndOfDay = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: type.icon)
                        Text(type.displayName)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(selection == type ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(selection == type ? type.color : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(.secondarySystemBackground), in: Capsule())
    }

    // MARK: - Free Content

    private var freeContent: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: BreakType.free.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(BreakType.free.color)

                Text("Neomezená pauza")
                    .font(.title3.weight(.semibold))

                Text("Bez časového limitu, bez penalizace")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)
        }
    }

    // MARK: - Committed Content

    private var committedContent: some View {
        VStack(spacing: 16) {
            durationInfoLabel

            selectionInfo

            durationSlider

            untilEndOfDayButton
        }
    }

    private var selectionInfo: some View {
        let minutes = isUntilEndOfDay ? calculateMinutesToMidnight() : selectedMinutes
        return Text("\(minutes) min")
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundStyle(BreakType.committed.color)
            .contentTransition(.numericText())
    }

    private var durationSlider: some View {
        VStack(spacing: 12) {
            SnappingSlider(
                value: $selectedMinutes,
                steps: durationSteps,
                tintColor: BreakType.committed.color,
                onInteraction: {
                    withAnimation(.snappy) {
                        isUntilEndOfDay = false
                    }
                }
            )
            .padding(.horizontal)
        }
    }

    private var durationInfoLabel: some View {
        let minutes = isUntilEndOfDay ? calculateMinutesToMidnight() : selectedMinutes
        let reduction = calculateWindReduction(minutes: minutes)
        let resultWind = Int(max(currentWind - reduction, 0))

        return Text("→ \(resultWind)% wind")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private var untilEndOfDayButton: some View {
        Button {
            withAnimation(.snappy) {
                isUntilEndOfDay.toggle()
                if isUntilEndOfDay {
                    let minutes = calculateMinutesToMidnight()
                    let maxSliderValue = durationSteps.last ?? 120
                    if minutes <= maxSliderValue {
                        let closestStep = durationSteps.min(by: { abs($0 - minutes) < abs($1 - minutes) }) ?? minutes
                        selectedMinutes = closestStep
                    } else {
                        selectedMinutes = maxSliderValue
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "moon.fill")
                Text("Do konce dne")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(isUntilEndOfDay ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isUntilEndOfDay ? BreakType.committed.color : Color.clear)
            )
            .overlay(
                Capsule()
                    .strokeBorder(isUntilEndOfDay ? Color.clear : BreakType.committed.color.opacity(0.5), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        VStack(spacing: 8) {
            if selection == .committed {
                Text("Předčasné ukončení způsobí ztrátu peta")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                if selection == .free {
                    onSelectFree()
                    dismiss()
                } else {
                    showConfirmation = true
                }
            } label: {
                Text("Zahájit pauzu")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selection.color, in: RoundedRectangle(cornerRadius: DeviceMetrics.concentricCornerRadius(inset: 26)))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }

    // MARK: - Wind Calculations

    private func calculateWindReduction(minutes: Int) -> Double {
        Double(minutes) * preset.fallRate
    }

    private func calculateMinutesToMidnight() -> Int {
        let calendar = Calendar.current
        let now = Date()
        guard let midnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime) else {
            return 0
        }
        return Int(midnight.timeIntervalSince(now) / 60)
    }
}

// MARK: - Snapping Slider

private struct SnappingSlider: View {
    @Binding var value: Int
    let steps: [Int]
    let tintColor: Color
    var onInteraction: (() -> Void)? = nil

    @State private var lastStepIndex: Int = 0

    private var currentIndex: Int {
        steps.firstIndex(of: value) ?? 0
    }

    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width - 24
            let stepWidth = trackWidth / CGFloat(steps.count - 1)
            let thumbPosition = CGFloat(currentIndex) * stepWidth + 12

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.tertiarySystemBackground))
                    .frame(height: 8)

                Capsule()
                    .fill(tintColor)
                    .frame(width: thumbPosition, height: 8)

                HStack(spacing: 0) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(index <= currentIndex ? tintColor : Color(.quaternarySystemFill))
                            .frame(width: 6, height: 6)

                        if index < steps.count - 1 {
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 12)

                Circle()
                    .fill(.white)
                    .frame(width: 28, height: 28)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    .offset(x: thumbPosition - 14)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                handlePositionChange(gesture.location.x, stepWidth: stepWidth)
                            }
                    )
            }
            .frame(height: 28)
            .contentShape(Rectangle())
            .onTapGesture { location in
                handlePositionChange(location.x, stepWidth: stepWidth)
            }
        }
        .frame(height: 28)
        .onAppear {
            lastStepIndex = currentIndex
        }
    }

    private func handlePositionChange(_ xPosition: CGFloat, stepWidth: CGFloat) {
        onInteraction?()

        let newPosition = xPosition - 12
        let index = Int(round(newPosition / stepWidth))
        let clampedIndex = max(0, min(steps.count - 1, index))

        if clampedIndex != lastStepIndex {
            lastStepIndex = clampedIndex
            withAnimation(.snappy(duration: 0.15)) {
                value = steps[clampedIndex]
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

#Preview {
    BreakTypePicker(
        onSelectFree: { print("Free selected") },
        onConfirmCommitted: { duration in print("Committed: \(duration)") }
    )
    .environment(PetManager.mock())
}
