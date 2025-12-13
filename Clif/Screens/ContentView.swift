//
//  ContentView.swift
//  Clif
//
//  Created by Jan Podmolík on 07.12.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Útes", systemImage: "arrowtriangle.down.fill") {
                CliffView()
            }
            Tab("Přísný mód", systemImage: "lock.shield.fill") {
                StrictModeView()
            }
            Tab("Přehled", systemImage: "chart.bar.fill") {
                OverviewView()
            }
            Tab("Profil", systemImage: "person") {
                ProfileView()
            }
        }
        .modifier(TabBarMinimizeModifier())
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
