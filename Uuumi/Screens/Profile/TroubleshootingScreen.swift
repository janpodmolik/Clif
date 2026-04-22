import SwiftUI

// PHANTOM_BURST_WORKAROUND — remove this screen and its ProfileDestination case
// once Apple ships the iOS 26.2 DeviceActivity fix (see DeviceActivityMonitorExtension
// for the full removal checklist).
struct TroubleshootingScreen: View {
    private var lastBurstDrop: Date? { SharedDefaults.lastBurstDropAt }
    private var burstCount: Int { SharedDefaults.burstDropCount }
    private var burstSecondsTotal: Int { SharedDefaults.burstDropSecondsTotal }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Wind went up without using the app?")
                        .font(.headline)
                    Text("iOS 26.2 has a confirmed bug where Apple's Screen Time system occasionally reports app usage that didn't actually happen. Apple acknowledged the bug and is working on a fix. Uuumi filters out impossible spikes so your pet isn't punished unfairly.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            } header: {
                Text("Known iOS Issue")
            }

            Section {
                if let last = lastBurstDrop {
                    LabeledContent("Last filtered") {
                        Text(last, style: .relative)
                    }
                    LabeledContent("Events blocked") {
                        Text("\(burstCount)")
                    }
                    LabeledContent("Seconds blocked") {
                        Text(formatSeconds(burstSecondsTotal))
                    }
                } else {
                    Text("No phantom events detected on this device yet.")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("What We Filtered Out")
            } footer: {
                Text("We ignore thresholds that claim more usage than real time elapsed. The first event in a batch can still slip through — we're still improving this defence.")
            }

            Section {
                Link(destination: URL(string: "https://developer.apple.com/forums/thread/811305")!) {
                    Label("Apple Developer Forum discussion", systemImage: "link")
                }
            } header: {
                Text("Learn More")
            }
        }
        .navigationTitle("Troubleshooting")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatSeconds(_ total: Int) -> String {
        let minutes = total / 60
        let seconds = total % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}
