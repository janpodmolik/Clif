import SwiftUI

struct CustomTabBar<Tab: RawRepresentable & CaseIterable & Hashable, TabItemView: View>: UIViewRepresentable
where Tab.RawValue == String, Tab.AllCases: RandomAccessCollection {
    var size: CGSize
    var activeTint: Color = .primary
    var inActiveTint: Color = .primary.opacity(0.45)
    var barTint: Color = .gray.opacity(0.3)
    @Binding var activeTab: Tab
    @ViewBuilder var tabItemView: (Tab) -> TabItemView

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UISegmentedControl {
        let items = Tab.allCases.map { $0.rawValue }
        let control = UISegmentedControl(items: Array(items))
        control.selectedSegmentIndex = Tab.allCases.firstIndex(of: activeTab).map { Tab.allCases.distance(from: Tab.allCases.startIndex, to: $0) } ?? 0

        for (index, tab) in Tab.allCases.enumerated() {
            let renderer = ImageRenderer(content: tabItemView(tab))
            renderer.scale = 2
            if let image = renderer.uiImage {
                control.setImage(image, forSegmentAt: index)
            }
        }

        DispatchQueue.main.async {
            for subview in control.subviews {
                if subview is UIImageView && subview != control.subviews.last {
                    subview.alpha = 0
                }
            }
        }

        control.selectedSegmentTintColor = UIColor(barTint)
        control.setTitleTextAttributes([
            .foregroundColor: UIColor(activeTint)
        ], for: .selected)
        control.setTitleTextAttributes([
            .foregroundColor: UIColor(inActiveTint)
        ], for: .normal)

        control.addTarget(context.coordinator, action: #selector(context.coordinator.tabSelected(_:)), for: .valueChanged)
        return control
    }

    func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        let currentIndex = Tab.allCases.firstIndex(of: activeTab).map { Tab.allCases.distance(from: Tab.allCases.startIndex, to: $0) } ?? 0
        if uiView.selectedSegmentIndex != currentIndex {
            uiView.selectedSegmentIndex = currentIndex
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UISegmentedControl, context: Context) -> CGSize? {
        return size
    }

    class Coordinator: NSObject {
        var parent: CustomTabBar
        init(parent: CustomTabBar) {
            self.parent = parent
        }

        @objc func tabSelected(_ control: UISegmentedControl) {
            let allCases = Array(Tab.allCases)
            if control.selectedSegmentIndex < allCases.count {
                parent.activeTab = allCases[control.selectedSegmentIndex]
            }
        }
    }
}
