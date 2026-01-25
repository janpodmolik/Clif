#if DEBUG
import SwiftUI
import FamilyControls
import DeviceActivity

struct DebugView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PetManager.self) private var petManager
    @StateObject private var manager = ScreenTimeManager.shared
    @State private var isPickerPresented = false
    @State private var extensionLog = ""

    @AppStorage(DefaultsKeys.monitoringLimitSeconds, store: UserDefaults(suiteName: AppConstants.appGroupIdentifier))
    private var monitoringLimitSeconds = AppConstants.defaultMonitoringLimitMinutes * 60

    @State private var limitSliderValue: Double = 1
    @State private var reportFilter: DeviceActivityFilter?
    @State private var reportId = UUID()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if !manager.isAuthorized {
                        authorizationSection
                    } else {
                        debugConfigSection
                        sharedDefaultsSection
                        screenTimeReportSection
                        limitSliderSection
                        appSelectionSection
                        progressSection
                        debugToolsSection
                        petAnimationSection
                        evolutionScaleSection
                        homeCardSection
                        petDetailSection
                        petHistoryRowSection
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
        }
    }

    // MARK: - Debug Config

    @State private var debugEnabled = DebugConfig.isEnabled
    @State private var minutesToBlowAway = DebugConfig.minutesToBlowAway
    @State private var minutesToRecover = DebugConfig.minutesToRecover

    private var debugConfigSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Debug Config")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $debugEnabled)
                    .labelsHidden()
                    .onChange(of: debugEnabled) { _, newValue in
                        DebugConfig.isEnabled = newValue
                    }
            }

            if debugEnabled {
                VStack(spacing: 8) {
                    HStack {
                        Text("Blow Away:")
                        Spacer()
                        Text("\(Int(minutesToBlowAway)) min")
                            .monospacedDigit()
                            .foregroundColor(.orange)
                    }
                    Slider(value: $minutesToBlowAway, in: 1...10, step: 1)
                        .onChange(of: minutesToBlowAway) { _, newValue in
                            DebugConfig.minutesToBlowAway = newValue
                            restartMonitoringIfNeeded()
                        }

                    HStack {
                        Text("Recovery:")
                        Spacer()
                        Text("\(Int(minutesToRecover)) min")
                            .monospacedDigit()
                            .foregroundColor(.green)
                    }
                    Slider(value: $minutesToRecover, in: 1...10, step: 1)
                        .onChange(of: minutesToRecover) { _, newValue in
                            DebugConfig.minutesToRecover = newValue
                            // Recovery rate doesn't affect monitoring thresholds, no restart needed
                        }

                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rise Rate")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", DebugConfig.riseRate)) pts/min")
                                .font(.caption)
                                .monospacedDigit()
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Fall Rate")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", DebugConfig.fallRate)) pts/min")
                                .font(.caption)
                                .monospacedDigit()
                        }
                    }
                }
                .font(.subheadline)
            } else {
                Text("Using production WindPreset values")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.15))
        .cornerRadius(12)
    }

    /// Restarts monitoring with new DebugConfig values if a pet exists.
    private func restartMonitoringIfNeeded() {
        guard let pet = petManager.currentPet else {
            print("[DebugConfig] No pet to restart monitoring for")
            return
        }

        let newLimit = Int(DebugConfig.minutesToBlowAway)
        let fallRate = DebugConfig.fallRate
        let limitSeconds = newLimit * 60
        let fallRatePerSecond = fallRate / 60.0

        // Update fallRate in SharedDefaults
        SharedDefaults.monitoredFallRate = fallRatePerSecond

        print("[DebugConfig] Restarting monitoring:")
        print("  - petId: \(pet.id)")
        print("  - limit: \(limitSeconds)s (\(newLimit) min)")
        print("  - fallRate: \(fallRatePerSecond) pts/sec")
        print("  - limitedSources count: \(pet.limitedSources.count)")

        ScreenTimeManager.shared.startMonitoring(
            petId: pet.id,
            limitSeconds: limitSeconds,
            limitedSources: pet.limitedSources
        )

        // Verify SharedDefaults were set
        print("[DebugConfig] After startMonitoring:")
        print("  - SharedDefaults.monitoredPetId: \(SharedDefaults.monitoredPetId?.uuidString ?? "nil")")
        print("  - SharedDefaults.monitoringLimitSeconds: \(SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds))")
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
            Text("Monitoring Limit: \(Int(limitSliderValue))m (\(Int(limitSliderValue) * 60)s)")
                .font(.headline)

            Slider(value: $limitSliderValue, in: 1...30, step: 1) {
                Text("Limit")
            } onEditingChanged: { isEditing in
                if !isEditing {
                    monitoringLimitSeconds = Int(limitSliderValue) * 60
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
            let minutes = monitoringLimitSeconds / 60
            limitSliderValue = Double(min(max(minutes, 1), 30))
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

            Text("\(windProgress)%")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(progressColor)

            Text(timeSpentText)
                .font(.subheadline)
                .foregroundColor(.orange)

            ProgressView(value: Double(min(windProgress, 100)), total: 100)
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

    // MARK: - SharedDefaults State

    private var sharedDefaultsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SharedDefaults State")
                .font(.headline)
                .foregroundColor(.purple)

            let limitSeconds = SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)
            let lastThresholdSec = SharedDefaults.monitoredLastThresholdSeconds
            let riseRate = SharedDefaults.monitoredRiseRate

            Group {
                Text("monitoredPetId: \(SharedDefaults.monitoredPetId?.uuidString ?? "nil")")
                Text("monitoredWindPoints: \(String(format: "%.1f", SharedDefaults.monitoredWindPoints))")
                Text("monitoredLastThreshold: \(lastThresholdSec)s (\(lastThresholdSec / 60)m \(lastThresholdSec % 60)s)")
                Text("monitoredRiseRate: \(String(format: "%.4f", riseRate)) pts/sec")
                Text("monitoringLimit: \(limitSeconds)s (\(limitSeconds / 60)m)")
            }
            .font(.system(size: 11, design: .monospaced))

            if let pet = petManager.currentPet {
                Divider()
                Text("Pet State")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("pet.windPoints: \(String(format: "%.1f", pet.windPoints))")
                Text("pet.lastThresholdSeconds: \(pet.lastThresholdSeconds)")
                    .font(.system(size: 11, design: .monospaced))
            }

            HStack(spacing: 8) {
                Button("Check Blow Away") {
                    petManager.currentPet?.checkBlowAwayState()
                }
                .buttonStyle(.bordered)
                .tint(.purple)

                Button("Simulate +interval") {
                    simulateThreshold()
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }

    /// Simulates what the extension does when a threshold is reached
    private func simulateThreshold() {
        let limitSeconds = SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)
        let maxThresholds = AppConstants.maxThresholds
        let minInterval = AppConstants.minimumThresholdSeconds
        let intervalSeconds = max(limitSeconds / maxThresholds, minInterval)

        let lastSeconds = SharedDefaults.monitoredLastThresholdSeconds
        let newSeconds = lastSeconds + intervalSeconds
        let riseRatePerSecond = SharedDefaults.monitoredRiseRate
        var windPoints = SharedDefaults.monitoredWindPoints

        windPoints += Double(intervalSeconds) * riseRatePerSecond
        windPoints = min(windPoints, 100)

        SharedDefaults.monitoredWindPoints = windPoints
        SharedDefaults.monitoredLastThresholdSeconds = newSeconds

        print("[SimulateThreshold] seconds \(lastSeconds) -> \(newSeconds), wind -> \(windPoints)")

        // Pet.windPoints is computed from SharedDefaults - no sync needed
        // Just check for blow-away state
        petManager.currentPet?.checkBlowAwayState()
    }

    // MARK: - Debug Tools

    private var debugToolsSection: some View {
        VStack(spacing: 12) {
            Text("Debug Tools")
                .font(.headline)
                .foregroundColor(.orange)

            HStack(spacing: 8) {
                Button("Restart Monitor") {
                    restartMonitoringIfNeeded()
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

    // MARK: - Evolution Scale Debug

    private var evolutionScaleSection: some View {
        NavigationLink(destination: EvolutionScaleDebugView()) {
            HStack {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                Text("Evolution Scale Debug")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.mint.opacity(0.2))
            .cornerRadius(12)
        }
    }

    // MARK: - HomeCard Debug

    private var homeCardSection: some View {
        NavigationLink(destination: HomeCardDebugView()) {
            HStack {
                Image(systemName: "rectangle.on.rectangle")
                Text("HomeCard Debug")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.2))
            .cornerRadius(12)
        }
    }

    // MARK: - Pet Detail Debug

    private var petDetailSection: some View {
        NavigationLink(destination: PetDetailScreenDebug()) {
            HStack {
                Image(systemName: "info.circle")
                Text("Pet Detail Debug")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.cyan.opacity(0.2))
            .cornerRadius(12)
        }
    }

    // MARK: - Pet History Row Debug

    private var petHistoryRowSection: some View {
        NavigationLink(destination: PetHistoryRowDebugView()) {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                Text("Pet History Row Debug")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.indigo.opacity(0.2))
            .cornerRadius(12)
        }
    }

    // MARK: - Extension Log

    private var extensionLogSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button("Refresh") {
                    loadExtensionLog()
                }
                .buttonStyle(.bordered)
                .tint(.gray)

                Button("Copy") {
                    UIPasteboard.general.string = extensionLog
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .disabled(extensionLog.isEmpty)

                Button("Clear") {
                    clearExtensionLog()
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

            if !extensionLog.isEmpty {
                ScrollView {
                    Text(extensionLog)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 200)
                .background(Color.black)
                .cornerRadius(8)
            } else {
                Text("No log data. Tap Refresh to load.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 50)
            }

            Text("Apps: \(manager.activitySelection.applicationTokens.count) | Categories: \(manager.activitySelection.categoryTokens.count)")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onAppear {
            loadExtensionLog()
        }
    }

    // MARK: - Helpers

    private var windProgress: Int {
        Int(SharedDefaults.monitoredWindPoints)
    }

    private var progressColor: Color {
        if windProgress >= 100 { return .red }
        if windProgress >= 80 { return .orange }
        return .blue
    }

    private var timeSpentText: String {
        let totalSeconds = SharedDefaults.monitoredLastThresholdSeconds
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let limitMinutes = monitoringLimitSeconds / 60
        return "\(minutes)m \(seconds)s / \(limitMinutes)m"
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
            extensionLog = ""
        }
    }

    private func clearExtensionLog() {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier) else {
            return
        }

        let logFileURL = containerURL.appendingPathComponent("extension_log.txt")
        try? FileManager.default.removeItem(at: logFileURL)
        extensionLog = ""
    }
}

#Preview {
    DebugView()
        .environment(PetManager.mock())
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
