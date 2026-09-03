import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                WorkoutsListView()
            }
            .tabItem {
                Label("Workouts", systemImage: "list.bullet.rectangle")
            }

            NavigationStack {
                TemplatesListView()
            }
            .tabItem {
                Label("Templates", systemImage: "square.stack.3d.up")
            }

            NavigationStack {
                ProgressDashboardView()
            }
            .tabItem {
                Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
            }

            NavigationStack {
                BodyStatsView()
            }
            .tabItem {
                Label("Body", systemImage: "figure.stand")
            }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(PreviewData.container)
}
