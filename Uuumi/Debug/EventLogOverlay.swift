#if DEBUG
import SwiftUI
import Combine

/// Real-time event log overlay for debugging wind system on HomeScreen.
/// Displays the last ~30 lines from extension_log.txt with auto-refresh.
struct EventLogOverlay: View {
    @State private var logContent = ""
    @State private var fullLogContent = ""
    @State private var isExpanded = true
    @State private var isPaused = false
    @State private var filterText = ""
    @State private var totalLineCount = 0
    @State private var showCopiedFeedback = false

    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    private let quickFilters = ["wind", "shield", "threshold", "error", "break"]

    private var displayedContent: String {
        guard !filterText.isEmpty else { return logContent }
        let lines = logContent.components(separatedBy: .newlines)
        let filtered = lines.filter { $0.localizedCaseInsensitiveContains(filterText) }
        return filtered.isEmpty ? "No matches for '\(filterText)'" : filtered.joined(separator: "\n")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            if isExpanded {
                // Quick filters
                quickFilterBar

                // Log content
                logContentView

                // Bottom toolbar
                bottomToolbar
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .onAppear {
            loadLog()
        }
        .onReceive(timer) { _ in
            if !isPaused {
                loadLog()
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Event Log")
                        .font(.system(size: 14, weight: .semibold))
                    if totalLineCount > 0 {
                        Text("(\(totalLineCount))")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray)
                    }
                }
                .foregroundStyle(.white)
            }

            Spacer()

            if isExpanded {
                HStack(spacing: 8) {
                    // Pause/Resume button
                    Button {
                        isPaused.toggle()
                    } label: {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(isPaused ? .yellow : .white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Copy button
                    Button {
                        copyToClipboard()
                    } label: {
                        Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(showCopiedFeedback ? .green : .white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Clear button
                    Button {
                        clearLog()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.red)
                            .frame(width: 44, height: 44)
                            .background(Color.red.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.8))
    }

    // MARK: - Quick Filter Bar

    private var quickFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Clear filter
                if !filterText.isEmpty {
                    Button {
                        filterText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.gray)
                            .frame(width: 36, height: 36)
                    }
                }

                ForEach(quickFilters, id: \.self) { filter in
                    Button {
                        filterText = filterText == filter ? "" : filter
                    } label: {
                        Text(filter)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(filterText == filter ? Color.green.opacity(0.3) : Color.white.opacity(0.1))
                            .foregroundStyle(filterText == filter ? .green : .white)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color.black.opacity(0.7))
    }

    // MARK: - Log Content

    private var logContentView: some View {
        // TextEditor allows proper text selection and copy
        TextEditor(text: .constant(displayedContent.isEmpty ? "No log data..." : displayedContent))
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(contentColor)
            .scrollContentBackground(.hidden)
            .background(Color.black.opacity(0.85))
            .frame(height: 300)
            .disabled(false) // Keep enabled for selection
    }

    private var contentColor: Color {
        if displayedContent.isEmpty || displayedContent.starts(with: "No") {
            return .gray
        }
        if !filterText.isEmpty {
            return .cyan
        }
        return .green
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack {
            // Status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(isPaused ? .yellow : .green)
                    .frame(width: 8, height: 8)
                Text(isPaused ? "Paused" : "Live")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isPaused ? .yellow : .green)
            }

            Spacer()

            // Filter status
            if !filterText.isEmpty {
                Text("Filter: \(filterText)")
                    .font(.system(size: 12))
                    .foregroundStyle(.cyan)
            }

            Spacer()

            // Copy full log
            Button {
                copyFullLog()
            } label: {
                Text("Copy All")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.2))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.7))
    }

    // MARK: - Actions

    private func loadLog() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier
        ) else {
            logContent = "Cannot access App Group container"
            return
        }

        let logFileURL = containerURL.appendingPathComponent("extension_log.txt")

        guard FileManager.default.fileExists(atPath: logFileURL.path),
              let content = try? String(contentsOf: logFileURL, encoding: .utf8) else {
            logContent = ""
            fullLogContent = ""
            totalLineCount = 0
            return
        }

        fullLogContent = content

        let lines = content.components(separatedBy: .newlines)
        totalLineCount = lines.count

        // Get last ~30 lines for display
        let lastLines = lines.suffix(30)
        logContent = lastLines.joined(separator: "\n")
    }

    private func clearLog() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier
        ) else { return }

        let logFileURL = containerURL.appendingPathComponent("extension_log.txt")
        try? FileManager.default.removeItem(at: logFileURL)
        logContent = ""
        fullLogContent = ""
        totalLineCount = 0
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = displayedContent
        showCopiedFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showCopiedFeedback = false
        }
    }

    private func copyFullLog() {
        UIPasteboard.general.string = fullLogContent
        showCopiedFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showCopiedFeedback = false
        }
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        EventLogOverlay()
    }
}
#endif
