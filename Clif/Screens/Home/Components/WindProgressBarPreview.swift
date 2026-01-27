import SwiftUI

#if DEBUG

// MARK: - Preview

struct WindProgressBarPreview: View {
    @State private var progress: Double = 0.45
    @State private var isPulsing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Controls
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Progress: \(Int(progress * 100))%")
                            .font(.headline)
                        Slider(value: $progress, in: 0...1)
                    }

                    Toggle("Pulsing / Shield Active (flow ←)", isOn: $isPulsing)

                    Text(isPulsing ? "Wind decreasing ←" : "Wind increasing →")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                // Main preview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Wind Progress Bar")
                        .font(.title3.bold())

                    WindProgressBar(progress: progress, isPulsing: isPulsing)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                // Different states
                VStack(alignment: .leading, spacing: 20) {
                    Text("States Preview")
                        .font(.title3.bold())

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Low (green)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        WindProgressBar(progress: 0.3, isPulsing: false)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Medium (orange)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        WindProgressBar(progress: 0.7, isPulsing: false)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("High (red)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        WindProgressBar(progress: 0.9, isPulsing: false)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Shield Active (cyan, flow ←)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        WindProgressBar(progress: 0.5, isPulsing: true)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    WindProgressBarPreview()
}

#endif
