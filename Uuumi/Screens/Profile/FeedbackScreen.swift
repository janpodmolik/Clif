import SwiftUI
import Supabase

struct FeedbackScreen: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(AnalyticsManager.self) private var analytics
    @Environment(\.dismiss) private var dismiss
    @Binding var showSuccess: Bool
    @State private var message = ""
    @State private var isSending = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var editorFocused: Bool

    var body: some View {
        Form {
            Section {
                Text("Napiš nám, co ti chybí, co by šlo zlepšit, nebo na jaký problém jsi narazil/a.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section(header: Text("Tvoje zpráva")) {
                TextEditor(text: $message)
                    .focused($editorFocused)
                    .frame(minHeight: 150)
            }

            Section {
                Button {
                    Task { await submitFeedback() }
                } label: {
                    HStack {
                        Spacer()
                        if isSending {
                            ProgressView()
                        } else {
                            Text("Odeslat")
                        }
                        Spacer()
                    }
                }
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            }
        }
        .navigationTitle("Zpětná vazba")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Chyba", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func submitFeedback() async {
        isSending = true
        defer { isSending = false }

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"

        let dto = FeedbackDTO(
            userId: authManager.currentUser?.id,
            message: message.trimmingCharacters(in: .whitespacesAndNewlines),
            appVersion: "\(version) (\(build))"
        )

        do {
            try await SupabaseConfig.client
                .from("feedback")
                .insert(dto)
                .execute()
            analytics.send(.feedbackSubmitted)
            showSuccess = true
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            #if DEBUG
            print("[Feedback] Submit failed: \(error)")
            #endif
        }
    }
}

#Preview {
    NavigationStack {
        FeedbackScreen(showSuccess: .constant(false))
    }
    .environment(AuthManager.mock())
}
