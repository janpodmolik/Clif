#if DEBUG
import SwiftUI
import FamilyControls
import DeviceActivity

struct DebugView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PetManager.self) private var petManager
    @Environment(StoreManager.self) private var storeManager
    @Environment(EssenceCatalogManager.self) private var catalogManager
    @StateObject private var manager = ScreenTimeManager.shared
    @State private var isPickerPresented = false
    @State private var extensionLog = ""
    @State private var showNotificationRequest = false

    @State private var reportFilter: DeviceActivityFilter?
    @State private var reportId = UUID()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    petEvolutionSection
                    premiumSection
                    coinsAndEssencesSection

                    if !manager.isAuthorized {
                        authorizationSection
                    }

                    if manager.isAuthorized {
                        progressSection
                        sharedDefaultsSection
                        monitoringSection
                        screenTimeReportSection
                    }

                    deepLinkSection
                    navigationLinksSection

                    if manager.isAuthorized {
                        extensionLogSection
                    }
                }
                .padding()
            }
            .navigationTitle("Debug")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
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
            .sheet(isPresented: $showNotificationRequest) {
                NotificationRequestSheet()
            }
        }
    }

    // MARK: - Section Card

    private func sectionCard<Content: View>(
        _ title: String,
        icon: String,
        tint: Color = .secondary,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)

            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Pet Evolution

    private var petEvolutionSection: some View {
        sectionCard("Pet Evolution", icon: "leaf.fill", tint: .green) {
            if let pet = petManager.currentPet {
                VStack(alignment: .leading, spacing: 4) {
                    debugRow("Phase", "\(pet.currentPhase) / \(pet.evolutionHistory.maxPhase)")
                    debugRow("Days alive", "\(pet.daysSinceCreation)")
                    debugRow("Essence", pet.essence?.name ?? "none")
                    debugRow("Created", pet.evolutionHistory.createdAt.formatted(date: .abbreviated, time: .shortened))

                    debugRow("Progressed today", pet.evolutionHistory.hasProgressedToday ? "Yes" : "No")

                    if let unlockDate = pet.evolutionHistory.nextEvolutionUnlockDate {
                        debugRow("Unlock time", unlockDate.formatted(date: .abbreviated, time: .shortened))
                        debugRow("Unlock passed", pet.evolutionHistory.isUnlockTimePassed ? "Yes" : "No")
                    }

                    if pet.isBlob {
                        debugRow("Can use essence", pet.canUseEssence ? "Yes" : "No")
                        if let days = pet.daysUntilEssence {
                            debugRow("Days until essence", "\(days)")
                        }
                    } else {
                        debugRow("Can evolve", pet.canEvolve ? "Yes" : "No")
                        if let days = pet.daysUntilEvolution {
                            debugRow("Days until evolution", "\(days)")
                        }
                    }
                }

                Divider()

                FlowLayout(spacing: 8) {
                    Button("+1 Day") {
                        pet.debugBumpDay()
                        petManager.savePet()
                    }
                    .tint(.green)

                    if !pet.isBlob {
                        Button("Unlock Now") {
                            pet.debugSetUnlockIn(minutes: 0)
                            petManager.savePet()
                            ScheduledNotificationManager.refresh(
                                isEvolutionAvailable: true,
                                hasPet: true,
                                nextEvolutionUnlockDate: pet.evolutionHistory.nextEvolutionUnlockDate
                            )
                        }
                        .tint(.mint)

                        Button("Unlock in 1 min") {
                            pet.debugSetUnlockIn(minutes: 1)
                            petManager.savePet()
                            ScheduledNotificationManager.refresh(
                                isEvolutionAvailable: false,
                                hasPet: true,
                                nextEvolutionUnlockDate: pet.evolutionHistory.nextEvolutionUnlockDate
                            )
                        }
                        .tint(.indigo)
                    }

                    if !pet.isBlob {
                        Button("Evolve Now") {
                            pet.debugUnlockEvolution()
                            pet.evolve()
                            petManager.savePet()
                        }
                        .tint(.orange)
                    }

                    Button("Unknown Essence") {
                        pet.debugSetUnknownEssence()
                        petManager.savePet()
                    }
                    .tint(.orange)

                    Button("Reset to Blob") {
                        pet.debugResetToBlob()
                        petManager.savePet()
                    }
                    .tint(.red)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Text("No active pet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Premium

    private var premiumSection: some View {
        sectionCard("Premium", icon: "crown.fill", tint: Color("PremiumGold")) {
            VStack(alignment: .leading, spacing: 3) {
                debugRow("isPremium", storeManager.isPremium ? "Yes" : "No")
                debugRow("productId", storeManager.activeProductId ?? "nil")
                if let exp = storeManager.expirationDate {
                    debugRow("Expires", exp.formatted(.dateTime.day().month().year().hour().minute()))
                }
                debugRow("Products loaded", "\(storeManager.products.count)")
            }

            Divider()

            FlowLayout(spacing: 8) {
                Button(storeManager.isPremium ? "Deactivate" : "Activate") {
                    if storeManager.isPremium {
                        storeManager.debugSetPremium(false)
                    } else {
                        storeManager.debugSetPremium(true)
                    }
                }
                .tint(storeManager.isPremium ? .red : .green)

                Button("Refresh Entitlements") {
                    Task { await storeManager.checkCurrentEntitlements() }
                }
                .tint(.blue)

                Button("Load Products") {
                    Task { await storeManager.forceLoadProducts() }
                }
                .tint(.purple)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    // MARK: - Coins & Essences

    @State private var debugCoinBalance = SharedDefaults.coinsBalance

    private var coinsAndEssencesSection: some View {
        sectionCard("Coins & Essences", icon: "dollarsign.circle.fill", tint: Color("PremiumGold")) {
            VStack(alignment: .leading, spacing: 3) {
                debugRow("Coins", "\(debugCoinBalance)")
                debugRow("Unlocked essences", "\(catalogManager.allUnlocked.count)/\(Essence.allCases.count)")
            }

            Divider()

            FlowLayout(spacing: 8) {
                Button("+100 Coins") {
                    SharedDefaults.addCoins(100)
                    debugCoinBalance = SharedDefaults.coinsBalance
                }
                .tint(.green)

                Button("+1000 Coins") {
                    SharedDefaults.addCoins(1000)
                    debugCoinBalance = SharedDefaults.coinsBalance
                }
                .tint(.green)

                Button("Reset Coins") {
                    SharedDefaults.coinsBalance = 0
                    debugCoinBalance = 0
                }
                .tint(.red)

                Button("Lock All Essences") {
                    catalogManager.clearOnSignOut()
                }
                .tint(.red)

                Button("Unlock All Essences") {
                    Essence.allCases.forEach { catalogManager.unlock($0) }
                }
                .tint(.blue)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    // MARK: - Authorization

    private var authorizationSection: some View {
        sectionCard("Screen Time Access", icon: "hourglass", tint: .orange) {
            Text("Authorize to use Screen Time debug tools.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Authorize Screen Time") {
                Task {
                    await manager.requestAuthorization()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .controlSize(.regular)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Progress Display

    private var progressSection: some View {
        sectionCard("Wind Progress", icon: "wind", tint: progressColor) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(windProgress)%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(progressColor)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(timeSpentText)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)

                    if let lastUpdate = SharedDefaults.lastMonitorUpdate {
                        Text(lastUpdate.formatted(date: .omitted, time: .standard))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            ProgressView(value: Double(min(windProgress, 100)), total: 100)
                .tint(progressColor)
        }
    }

    // MARK: - SharedDefaults State

    private var sharedDefaultsSection: some View {
        sectionCard("SharedDefaults", icon: "externaldrive.fill", tint: .purple) {
            let limitSeconds = SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)
            let lastThresholdSec = SharedDefaults.monitoredLastThresholdSeconds
            let riseRate = SharedDefaults.monitoredRiseRate

            VStack(alignment: .leading, spacing: 3) {
                debugRow("petId", SharedDefaults.monitoredPetId.map { String($0.uuidString.prefix(8)) + "..." } ?? "nil")
                debugRow("windPoints", String(format: "%.1f", SharedDefaults.monitoredWindPoints))
                debugRow("lastThreshold", "\(lastThresholdSec)s (\(lastThresholdSec / 60)m \(lastThresholdSec % 60)s)")
                debugRow("riseRate", String(format: "%.4f pts/sec", riseRate))
                debugRow("limit", "\(limitSeconds)s (\(limitSeconds / 60)m)")
            }

            if let pet = petManager.currentPet {
                Divider()
                VStack(alignment: .leading, spacing: 3) {
                    debugRow("pet.windPoints", String(format: "%.1f", pet.windPoints))
                    debugRow("pet.lastThreshold", "\(pet.lastThresholdSeconds)s")
                }
            }
        }
    }

    // MARK: - Monitoring Controls (merged: debug tools + limit slider + app selection)

    private var monitoringSection: some View {
        sectionCard("Monitoring", icon: "antenna.radiowaves.left.and.right", tint: .orange) {
            // App selection
            let appCount = manager.activitySelection.applicationTokens.count
            let catCount = manager.activitySelection.categoryTokens.count

            Button {
                isPickerPresented = true
            } label: {
                HStack {
                    Label("Select Apps", systemImage: "app.badge")
                    Spacer()
                    Text("\(appCount) apps, \(catCount) cat.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .tint(.primary)

            Divider()

            // Actions
            FlowLayout(spacing: 8) {
                Button("Clear Shield") {
                    manager.clearShield()
                    SharedDefaults.isDayStartShieldActive = false
                }
                .tint(.green)

                Button("Apply Shield") {
                    manager.updateShield()
                }
                .tint(.red)

                Button("Day Start Shield") {
                    // Clear any active break first (e.g. safety shield)
                    SharedDefaults.resetShieldFlags()
                    ShieldManager.shared.clear()

                    SharedDefaults.lastDayResetDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
                    SharedDefaults.todaySelectedPreset = nil
                    SharedDefaults.isDayStartShieldActive = true
                    ShieldManager.shared.activateStoreFromStoredTokens()
                    ShieldState.shared.refresh()
                }
                .tint(.orange)

                Button("Simulate New Day") {
                    SharedDefaults.resetShieldFlags()
                    ShieldManager.shared.clear()

                    SharedDefaults.lastDayResetDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
                    SharedDefaults.isDayStartShieldActive = false
                    SharedDefaults.synchronize()
                }
                .tint(.mint)

                Button("Safety Shield") {
                    simulateSafetyShield()
                }
                .tint(.purple)

                Button("Expire Break") {
                    simulateExpireBreak()
                }
                .tint(.orange)

                Button("Overnight Break") {
                    simulateOvernightBreak()
                }
                .tint(.pink)

                Button("Zombie Break") {
                    simulateZombieCommittedBreak()
                }
                .tint(.red)

                Button("Wind Coin Bug") {
                    simulateUntilZeroWindCoinBug()
                }
                .tint(.cyan)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    /// Simulates expiring any active break (as if it expired naturally).
    private func simulateExpireBreak() {
        func log(_ message: String) {
            ExtensionLogger.log(message, prefix: "[DebugExpire]")
            print(message)
        }

        guard SharedDefaults.activeBreakType != nil else {
            log("No active break — start a break first")
            return
        }

        let coinsBefore = SharedDefaults.coinsBalance
        ShieldManager.shared.endExpiredBreakIfNeeded()

        // If endExpiredBreakIfNeeded didn't expire it (not yet expired), force it
        if SharedDefaults.activeBreakType != nil {
            ShieldManager.shared.turnOff(success: true)
            log("Force-ended active break")
        }

        ShieldManager.shared.resumeBreakMonitoringIfNeeded()
        let coinsAwarded = SharedDefaults.coinsBalance - coinsBefore
        log("Break expired. Coins awarded: \(coinsAwarded)")
    }

    /// Simulates opening the app after an overnight committed break.
    /// Sets day state to "yesterday" so the next foreground triggers the daily preset picker.
    private func simulateOvernightBreak() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!

        SharedDefaults.lastDayResetDate = yesterday
        SharedDefaults.todaySelectedPreset = nil

        // Clear any active break (as if committed break ended overnight)
        SharedDefaults.resetShieldFlags()
        ShieldManager.shared.clear()

        SharedDefaults.synchronize()

        print("[DebugTools] Simulated overnight break state — backgrounding and foregrounding should trigger daily preset picker")
    }

    /// Simulates a committed break that started 9 hours ago but never completed.
    /// Tests that endExpiredBreakIfNeeded awards coins capped to planned duration.
    private func simulateZombieCommittedBreak() {
        func log(_ message: String) {
            ExtensionLogger.log(message, prefix: "[DebugZombie]")
            print(message)
        }

        let nineHoursAgo = Date().addingTimeInterval(-9 * 3600)
        SharedDefaults.shieldActivatedAt = nineHoursAgo
        SharedDefaults.breakStartedAt = nineHoursAgo
        SharedDefaults.activeBreakType = .committed
        SharedDefaults.committedBreakMode = .timed(minutes: 15)
        SharedDefaults.monitoredWindPoints = 50
        SharedDefaults.synchronize()

        let coinsBefore = SharedDefaults.coinsBalance

        ShieldManager.shared.endExpiredBreakIfNeeded()
        ShieldManager.shared.resumeBreakMonitoringIfNeeded()

        let coinsAwarded = SharedDefaults.coinsBalance - coinsBefore
        log("Coins awarded: \(coinsAwarded) (expected: 1 for 15-minute break)")
    }

    /// Simulates an untilZeroWind committed break that started 1 hour ago with wind that
    /// would reach zero in ~6 minutes. Verifies coins are based on actual wind-to-zero time
    /// (0 coins for 6 min), not wall-clock elapsed time (4 coins for 60 min).
    private func simulateUntilZeroWindCoinBug() {
        func log(_ message: String) {
            ExtensionLogger.log(message, prefix: "[DebugWindCoin]")
            print(message)
        }

        let oneHourAgo = Date().addingTimeInterval(-3600)
        let windAtStart: Double = 30
        let fallRatePerSecond: Double = 5.0 / 60.0 // balanced preset: 5 pts/min

        // Wind reaches zero in: 30 / (5/60) = 360 seconds = 6 minutes → 0 coins
        let expectedMinutes = Int(windAtStart / fallRatePerSecond / 60) // 6
        let expectedCoins = CoinRewards.forBreak(minutes: expectedMinutes) // 0

        SharedDefaults.shieldActivatedAt = oneHourAgo
        SharedDefaults.breakStartedAt = oneHourAgo
        SharedDefaults.activeBreakType = .committed
        SharedDefaults.committedBreakMode = .untilZeroWind
        SharedDefaults.monitoredWindPoints = windAtStart
        SharedDefaults.monitoredFallRate = fallRatePerSecond
        SharedDefaults.synchronize()

        let coinsBefore = SharedDefaults.coinsBalance

        // This calls checkBreakCompletion() → turnOff(success: true) since effectiveWind <= 0
        ShieldManager.shared.resumeBreakMonitoringIfNeeded()

        let coinsAwarded = SharedDefaults.coinsBalance - coinsBefore
        let passed = coinsAwarded == expectedCoins
        log("Break duration: \(expectedMinutes) min, coins: \(coinsAwarded) (expected: \(expectedCoins), bug would show: 4) — \(passed ? "PASS ✅" : "FAIL ❌")")
    }

    /// Simulates what the extension does when wind reaches 100%:
    /// sets safety break flags in SharedDefaults and posts Darwin notification.
    private func simulateSafetyShield() {
        SharedDefaults.monitoredWindPoints = 100
        SharedDefaults.shieldActivatedAt = Date()
        SharedDefaults.activeBreakType = .safety
        SharedDefaults.synchronize()

        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName(DarwinNotifications.safetyShieldActivated as CFString), nil, nil, true)

        print("[DebugTools] Simulated safety shield activation + Darwin notification")
    }

    // MARK: - Screen Time Report

    private var screenTimeReportSection: some View {
        sectionCard("Screen Time Report", icon: "chart.bar.fill", tint: .blue) {
            if let filter = reportFilter {
                DeviceActivityReport(.totalActivity, filter: filter)
                    .id(reportId)
                    .frame(minHeight: 180)
            } else {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Loading...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(minHeight: 120)
                .frame(maxWidth: .infinity)
            }

            Button {
                refreshReport()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh Report")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(.blue)
        }
        .task {
            reportFilter = createFilter()
        }
    }

    // MARK: - Deep Links

    private var deepLinkSection: some View {
        sectionCard("Deep Links", icon: "link", tint: .cyan) {
            FlowLayout(spacing: 8) {
                Button("Reset Onboarding") {
                    UserDefaults.standard.set(false, forKey: DefaultsKeys.hasCompletedOnboarding)
                }
                .tint(.pink)
                Button("Home") { openDeepLink("uuumi://home") }
                    .tint(.blue)
                Button("Preset Picker") { openDeepLink("uuumi://preset-picker") }
                    .tint(.green)
                Button("Summary (today)") {
                    let ts = Date().timeIntervalSince1970
                    openDeepLink("uuumi://dailySummary?date=\(ts)")
                }
                .tint(.orange)
                Button("Summary (yesterday)") {
                    let ts = Date().addingTimeInterval(-86400).timeIntervalSince1970
                    openDeepLink("uuumi://dailySummary?date=\(ts)")
                }
                .tint(.yellow)
                Button("Essence Catalog") { openDeepLink("uuumi://essenceCatalog") }
                    .tint(.purple)
                Button("Shield") { openDeepLink("uuumi://shield") }
                    .tint(.red)
                Button("Notification Request") { showNotificationRequest = true }
                    .tint(.indigo)
                if let petId = petManager.currentPet?.id {
                    Button("Select Pet") { openDeepLink("uuumi://pet/\(petId)") }
                        .tint(.mint)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private func openDeepLink(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Navigation Links

    private var navigationLinksSection: some View {
        sectionCard("Debug Screens", icon: "rectangle.stack.fill", tint: .indigo) {
            VStack(spacing: 0) {
                debugNavigationRow("Pet Animation", icon: "figure.wave", color: .green) {
                    PetDebugView()
                }

                Divider()

                debugNavigationRow("Evolution Scale", icon: "arrow.up.left.and.arrow.down.right", color: .mint) {
                    EvolutionScaleDebugView()
                }

                Divider()

                debugNavigationRow("HomeCard", icon: "rectangle.on.rectangle", color: .blue) {
                    HomeCardDebugView()
                }

                Divider()

                debugNavigationRow("Pet Detail", icon: "info.circle", color: .cyan) {
                    PetDetailScreenDebug()
                }

                Divider()

                debugNavigationRow("Pet History Row", icon: "list.bullet.rectangle", color: .indigo) {
                    PetHistoryRowDebugView()
                }

                Divider()

                debugNavigationRow("Onboarding", icon: "hand.wave", color: .pink) {
                    OnboardingView()
                }
            }
        }
    }

    private func debugNavigationRow<Destination: View>(
        _ title: String,
        icon: String,
        color: Color,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
                    .frame(width: 24)

                Text(title)
                    .font(.subheadline)

                Spacer()
            }
            .padding(.vertical, 10)
        }
    }

    // MARK: - Extension Log

    private var extensionLogSection: some View {
        sectionCard("Extension Log", icon: "doc.text.fill", tint: .gray) {
            if !extensionLog.isEmpty {
                ScrollView {
                    Text(extensionLog)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .frame(height: 200)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Text("No log data. Tap Refresh to load.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }

            let appCount = manager.activitySelection.applicationTokens.count
            let catCount = manager.activitySelection.categoryTokens.count
            Text("Apps: \(appCount) | Categories: \(catCount)")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            HStack(spacing: 8) {
                Button("Refresh") {
                    loadExtensionLog()
                }
                .tint(.gray)

                Button("Copy") {
                    UIPasteboard.general.string = extensionLog
                }
                .tint(.blue)
                .disabled(extensionLog.isEmpty)

                Button("Clear") {
                    clearExtensionLog()
                }
                .tint(.red)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
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
        let limitSeconds = SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)
        return "\(minutes)m \(seconds)s / \(limitSeconds / 60)m"
    }

    private func debugRow(_ label: String, _ value: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.system(size: 11, design: .monospaced))
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

// MARK: - FlowLayout

/// Simple horizontal flow layout that wraps items to next line when they don't fit.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            let point = CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            )
            subview.place(at: point, anchor: .topLeading, proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}

#Preview {
    DebugView()
        .environment(PetManager.mock())
        .environment(StoreManager.mock())
        .environment(EssenceCatalogManager.mock())
}

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
#endif
