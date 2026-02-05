import SwiftUI

struct SwiftUITabBar<Tab: RawRepresentable & CaseIterable & Hashable>: View
where Tab.RawValue == String, Tab.AllCases: RandomAccessCollection {

    @Binding var activeTab: Tab
    var onReselect: ((Tab) -> Void)?
    var tabSymbol: (Tab) -> String
    var pulsingTab: Tab?
    var coinsAnimator: CoinsRewardAnimator

    @Namespace private var tabIndicatorNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(Tab.allCases), id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func tabButton(for tab: Tab) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if activeTab == tab {
                onReselect?(tab)
            } else {
                withAnimation(.snappy(duration: 0.25)) {
                    activeTab = tab
                }
            }
        } label: {
            tabLabel(for: tab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    if activeTab == tab {
                        Capsule()
                            .fill(.gray.opacity(0.3))
                            .padding(.vertical, 4)
                            .matchedGeometryEffect(id: "tabIndicator", in: tabIndicatorNamespace)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func tabLabel(for tab: Tab) -> some View {
        let isPulsing = pulsingTab != nil && tab.rawValue == pulsingTab?.rawValue && coinsAnimator.isPulsingTab
        let isActive = activeTab == tab

        VStack(spacing: 3) {
            Image(systemName: tabSymbol(tab))
                .font(.title3)
            Text(tab.rawValue)
                .font(.system(size: 10))
                .fontWeight(.medium)
        }
        .symbolVariant(.fill)
        .opacity(isActive ? 1 : 0.45)
        .scaleEffect(isPulsing ? 1.15 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isPulsing)
    }
}
