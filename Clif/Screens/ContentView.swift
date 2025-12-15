import SwiftUI

struct ContentView: View {
    @AppStorage("isDarkModeEnabled")
    private var isDarkModeEnabled: Bool = false

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                HomeScreen()
            }
            Tab("Přísný mód", systemImage: "lock.shield.fill") {
                StrictModeScreen()
            }
            Tab("Přehled", systemImage: "chart.bar.fill") {
                OverviewScreen()
            }
            Tab("Profil", systemImage: "person") {
                ProfileScreen()
            }
        }
        .tint(.primary)
        .modifier(TabBarMinimizeModifier())
        .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
    }
}

struct TabBarMinimizeModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            content
        }
    }
}

#Preview {
    ContentView()
}
