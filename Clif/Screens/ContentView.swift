import SwiftUI

enum AppTab: String, CaseIterable {
    case home = "Home"
    case overview = "Přehled"
    case profile = "Profil"

    var symbol: String {
        switch self {
        case .home: return "house"
        case .overview: return "chart.bar"
        case .profile: return "person"
        }
    }
}

struct ContentView: View {
    @AppStorage("isDarkModeEnabled")
    private var isDarkModeEnabled: Bool = false

    @State private var activeTab: AppTab = .home

    #if DEBUG
    @State private var showPetDebug = false
    #endif

    var body: some View {
        TabView(selection: $activeTab) {
            Tab(value: .home) {
                HomeScreen()
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            Tab(value: .overview) {
                OverviewScreen()
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            Tab(value: .profile) {
                ProfileScreen()
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .tint(.primary)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            customTabBar()
                .padding(.horizontal, 20)
        }
        .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
        #if DEBUG
        .fullScreenCover(isPresented: $showPetDebug) {
            PetDebugView()
        }
        #endif
    }

    @ViewBuilder
    private func customTabBar() -> some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 10) {
                tabBarContent()
            }
            .frame(height: 55)
        } else {
            HStack(spacing: 10) {
                tabBarContentFallback()
            }
            .frame(height: 55)
        }
    }

    @available(iOS 26.0, *)
    @ViewBuilder
    private func tabBarContent() -> some View {
        HStack(spacing: 10) {
            GeometryReader { geo in
                CustomTabBar(size: geo.size, activeTab: $activeTab) { tab in
                    VStack(spacing: 3) {
                        Image(systemName: tab.symbol)
                            .font(.title3)
                        Text(tab.rawValue)
                            .font(.system(size: 10))
                            .fontWeight(.medium)
                    }
                    .symbolVariant(.fill)
                    .frame(maxWidth: .infinity)
                }
                .glassEffect(.regular.interactive(), in: .capsule)
            }

            Button {
                #if DEBUG
                showPetDebug = true
                #endif
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 55, height: 55)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
        }
    }

    @ViewBuilder
    private func tabBarContentFallback() -> some View {
        GeometryReader { geo in
            CustomTabBar(size: geo.size, activeTab: $activeTab) { tab in
                VStack(spacing: 3) {
                    Image(systemName: tab.symbol)
                        .font(.title3)
                    Text(tab.rawValue)
                        .font(.system(size: 10))
                        .fontWeight(.medium)
                }
                .symbolVariant(.fill)
                .frame(maxWidth: .infinity)
            }
            .background(.ultraThinMaterial, in: Capsule())
        }

        Button {
            #if DEBUG
            showPetDebug = true
            #endif
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 55, height: 55)
        }
        .buttonStyle(.plain)
        .background(.ultraThinMaterial, in: Circle())
    }
}

#Preview {
    ContentView()
}
