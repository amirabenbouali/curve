import SwiftUI

struct RootTabView: View {
    @State private var selection: CurveTab = .today

    var body: some View {
        ZStack(alignment: .bottom) {
            CurveBackground()

            Group {
                tabContent(.today) { NavigationStack { TodayView() } }
                tabContent(.log) { NavigationStack { WorkoutsListView() } }
                tabContent(.progress) { NavigationStack { ProgressDashboardView() } }
                tabContent(.settings) { NavigationStack { SettingsView() } }
            }

            CurveTabBar(selection: $selection)
                .padding(.bottom, 8)
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func tabContent<Content: View>(_ tab: CurveTab, @ViewBuilder content: () -> Content) -> some View {
        content()
            .opacity(selection == tab ? 1 : 0)
            .allowsHitTesting(selection == tab)
    }
}

#Preview {
    RootTabView()
        .modelContainer(PreviewData.container)
}
