import SwiftUI

struct AppearanceSettingsScreen: View {
    @Environment(StoreManager.self) private var storeManager
    @AppStorage(DefaultsKeys.appearanceMode) private var appearanceMode: AppearanceMode = .automatic
    @AppStorage(DefaultsKeys.useDynamicSky) private var useDynamicSky = false
    @AppStorage(DefaultsKeys.selectedDayTheme) private var dayTheme: DayTheme = .morningHaze
    @AppStorage(DefaultsKeys.selectedNightTheme) private var nightTheme: NightTheme = .deepNight
    @State private var showPremiumSheet = false

    var body: some View {
        Form {
            Section {
                Picker(selection: $appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Label(mode.label, systemImage: mode.icon).tag(mode)
                    }
                } label: {
                    Label("Mode", systemImage: "circle.lefthalf.filled")
                }
            } footer: {
                switch appearanceMode {
                case .automatic:
                    Text("Switches between light and dark theme based on time of day.")
                case .light:
                    Text("Always uses the light theme.")
                case .dark:
                    Text("Always uses the dark theme.")
                }
            }

            if appearanceMode == .automatic {
                Section {
                    dynamicSkyRow
                } footer: {
                    Text("Smooth sky gradient that transitions continuously throughout the day.")
                }
            }

            if showsThemePickers && appearanceMode != .dark {
                Section("Light Theme") {
                    ThemePicker(
                        themes: DayTheme.allCases,
                        selected: $dayTheme,
                        label: \.label,
                        gradient: \.gradient,
                        isPremium: \.isPremium
                    )
                }
            }

            if showsThemePickers && appearanceMode != .light {
                Section("Dark Theme") {
                    ThemePicker(
                        themes: NightTheme.allCases,
                        selected: $nightTheme,
                        label: \.label,
                        gradient: \.gradient,
                        isPremium: \.isPremium
                    )
                }
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPremiumSheet) {
            PremiumSheet(source: .appearanceTheme)
        }
    }

    // MARK: - Dynamic Sky Row

    @ViewBuilder
    private var dynamicSkyRow: some View {
        if storeManager.isPremium {
            Toggle(isOn: $useDynamicSky) {
                Label("Dynamic Sky", systemImage: "sparkles")
            }
        } else {
            Button {
                showPremiumSheet = true
            } label: {
                HStack {
                    Label("Dynamic Sky", systemImage: "sparkles")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private var showsThemePickers: Bool {
        appearanceMode != .automatic || !useDynamicSky
    }
}

// MARK: - Theme Picker

struct ThemePicker<T: Hashable & Identifiable>: View {
    let themes: [T]
    @Binding var selected: T
    let label: KeyPath<T, String>
    let gradient: KeyPath<T, [Color]>
    let isPremium: KeyPath<T, Bool>

    @Environment(StoreManager.self) private var storeManager
    @State private var showPremiumSheet = false

    var body: some View {
        HStack(spacing: 12) {
            ForEach(themes) { theme in
                let isSelected = theme.id == selected.id
                let isLocked = theme[keyPath: isPremium] && !storeManager.isPremium
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: theme[keyPath: gradient],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 60)
                        .opacity(isLocked ? 0.5 : 1.0)
                        .overlay {
                            if isLocked {
                                Image(systemName: "lock.fill")
                                    .font(.body)
                                    .foregroundStyle(.white)
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(.white, lineWidth: 2.5)
                                .opacity(isSelected ? 1 : 0)
                        )
                        .shadow(color: .black.opacity(isSelected ? 0.3 : 0), radius: 3, y: 1)

                    Text(theme[keyPath: label])
                        .font(.caption)
                        .foregroundStyle(isSelected ? .primary : .secondary)
                }
                .onTapGesture {
                    if isLocked {
                        showPremiumSheet = true
                    } else {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selected = theme
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showPremiumSheet) {
            PremiumSheet(source: .appearanceSky)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AppearanceSettingsScreen()
            .environment(StoreManager.mock())
    }
}
#endif
