import SwiftUI

struct TroubleshootingScreen: View {
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Wind went up without using the app?")
                        .font(.headline)
                    Text("iOS 26.2 has a confirmed bug where Apple's Screen Time system occasionally reports app usage that didn't actually happen — sometimes pushing wind up by a large amount in a single moment. Apple has acknowledged the bug and is working on a fix. Until they ship it, this affects every app built on Screen Time.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            } header: {
                Text("Known iOS Issue")
            }

            Section {
                Link(destination: URL(string: "https://developer.apple.com/forums/thread/811305")!) {
                    Label("Apple Developer Forum discussion", systemImage: "link")
                }
            } header: {
                Text("Learn More")
            } footer: {
                Text("If you'd like to help, file feedback with Apple referencing FB21450954 — more reports raise the priority.")
            }
        }
        .navigationTitle("Troubleshooting")
        .navigationBarTitleDisplayMode(.inline)
    }
}
