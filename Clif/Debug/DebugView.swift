#if DEBUG
import SwiftUI
import FamilyControls
import DeviceActivity

struct DebugView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = ScreenTimeManager.shared
    @State private var isPickerPresented = false
    @State private var extensionLog = ""

    @AppStorage(DefaultsKeys.currentProgress, store: UserDefaults(suiteName: AppConstants.appGroupIdentifier))
    private var currentProgress = 0

    @AppStorage(DefaultsKeys.dailyLimitMinutes, store: UserDefaults(suiteName: AppConstants.appGroupIdentifier))
    private var dailyLimitMinutes = AppConstants.defaultDailyLimitMinutes

    @State private var dailyLimit: Double = 1
    @State private var reportFilter: DeviceActivityFilter?
    @State private var reportId = UUID()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if !manager.isAuthorized {
                        authorizationSection
                    } else {
                        screenTimeReportSection
                        limitSliderSection
                        appSelectionSection
                        progressSection
                        debugToolsSection
                        petAnimationSection
                        statusCardSection
                        supabaseSection
                        extensionLogSection
                    }
                }
                .padding()
            }
            .navigationTitle("🛠 Debug")
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
            .familyActivityPicker(
                isPresented: $isPickerPresented,
                selection: $manager.activitySelection
            )
            .onChange(of: manager.activitySelection) { _, _ in
                manager.saveSelection()
            }
        }
    }

    // MARK: - Authorization

    private var authorizationSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "hourglass")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Screen Time Access Required")
                .font(.headline)

            Text("Authorize to use debug tools.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("Authorize Screen Time") {
                Task {
                    await manager.requestAuthorization()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
    }

    // MARK: - Screen Time Report

    private var screenTimeReportSection: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Screen Time Report", systemImage: "clock")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Button {
                    refreshReport()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            if let filter = reportFilter {
                DeviceActivityReport(.totalActivity, filter: filter)
                    .id(reportId)
                    .frame(minHeight: 180)
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(minHeight: 180)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .task {
            reportFilter = createFilter()
        }
    }

    // MARK: - Limit Slider (Debug range: 1-30 min)

    private var limitSliderSection: some View {
        VStack {
            Text("Daily Limit: \(Int(dailyLimit))m")
                .font(.headline)

            Slider(value: $dailyLimit, in: 1...30, step: 1) {
                Text("Limit")
            } onEditingChanged: { isEditing in
                if !isEditing {
                    dailyLimitMinutes = Int(dailyLimit)
                    refreshReport()
                }
            }

            Text("Debug range: 1-30 minutes")
                .font(.caption2)
                .foregroundColor(.orange)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onAppear {
            dailyLimit = Double(min(max(dailyLimitMinutes, 1), 30))
        }
    }

    // MARK: - App Selection

    private var appSelectionSection: some View {
        VStack(spacing: 12) {
            Button("Select Apps to Monitor") {
                isPickerPresented = true
            }
            .buttonStyle(.bordered)
            .tint(.orange)

            let appCount = manager.activitySelection.applicationTokens.count
            let catCount = manager.activitySelection.categoryTokens.count

            if appCount > 0 || catCount > 0 {
                Text("Monitoring \(appCount) apps, \(catCount) categories")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Progress Display

    private var progressSection: some View {
        VStack(spacing: 12) {
            Text("Current Progress")
                .font(.headline)

            Text("\(currentProgress)%")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(progressColor)

            Text(timeSpentText)
                .font(.subheadline)
                .foregroundColor(.orange)

            ProgressView(value: Double(min(currentProgress, 100)), total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .padding(.horizontal)

            if let lastUpdate = SharedDefaults.lastMonitorUpdate {
                Text("Updated: \(lastUpdate.formatted(date: .omitted, time: .standard))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Debug Tools

    private var debugToolsSection: some View {
        VStack(spacing: 12) {
            Text("Debug Tools")
                .font(.headline)
                .foregroundColor(.orange)

            HStack(spacing: 8) {
                Button("Restart Monitor") {
                    manager.startMonitoring()
                }
                .buttonStyle(.bordered)
                .tint(.blue)

                Button("Clear Shield") {
                    manager.clearShield()
                }
                .buttonStyle(.bordered)
                .tint(.green)

                Button("Apply Shield") {
                    manager.updateShield()
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .font(.caption)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Supabase

    private var supabaseSection: some View {
        NavigationLink(destination: SupabaseTestView()) {
            HStack {
                Image(systemName: "server.rack")
                Text("Supabase Test")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.purple.opacity(0.2))
            .cornerRadius(12)
        }
    }

    // MARK: - Pet Animation Debug

    private var petAnimationSection: some View {
        NavigationLink(destination: PetDebugView()) {
            HStack {
                Image(systemName: "figure.wave")
                Text("Pet Animation Debug")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green.opacity(0.2))
            .cornerRadius(12)
        }
    }

    // MARK: - StatusCard Debug

    private var statusCardSection: some View {
        NavigationLink(destination: StatusCardDebugView()) {
            HStack {
                Image(systemName: "rectangle.on.rectangle")
                Text("StatusCard Debug")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.2))
            .cornerRadius(12)
        }
    }

    // MARK: - Extension Log

    private var extensionLogSection: some View {
        VStack(spacing: 8) {
            Button("Show Extension Log") {
                loadExtensionLog()
            }
            .buttonStyle(.bordered)
            .tint(.gray)

            if !extensionLog.isEmpty {
                ScrollView {
                    Text(extensionLog)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 150)
                .background(Color.black)
                .cornerRadius(8)
            }

            Text("Apps: \(manager.activitySelection.applicationTokens.count) | Categories: \(manager.activitySelection.categoryTokens.count)")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private var progressColor: Color {
        if currentProgress >= 100 { return .red }
        if currentProgress >= 80 { return .orange }
        return .blue
    }

    private var timeSpentText: String {
        let totalSeconds = (dailyLimitMinutes * 60 * currentProgress) / 100
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "~\(minutes)m \(seconds)s / \(dailyLimitMinutes)m"
    }

    private func createFilter() -> DeviceActivityFilter {
        DeviceActivityFilter(
            segment: .hourly(
                during: Calendar.current.dateInterval(of: .day, for: .now)!
            ),
            users: .all,
            devices: .init([.iPhone]),
            applications: manager.activitySelection.applicationTokens,
            categories: manager.activitySelection.categoryTokens
        )
    }

    private func refreshReport() {
        reportFilter = nil
        reportId = UUID()
        reportFilter = createFilter()
    }

    private func loadExtensionLog() {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier) else {
            extensionLog = "Cannot access App Group container"
            return
        }

        let logFileURL = containerURL.appendingPathComponent("extension_log.txt")

        if FileManager.default.fileExists(atPath: logFileURL.path) {
            extensionLog = (try? String(contentsOf: logFileURL, encoding: .utf8)) ?? "Error reading log"
        } else {
            extensionLog = "No log file yet"
        }
    }
}

#Preview {
    DebugView()
}
#endif

// MARK: - Debug Overlay

extension View {
    @ViewBuilder
    func withDebugOverlay() -> some View {
        #if DEBUG
        modifier(DebugOverlayModifier())
        #else
        self
        #endif
    }
}
