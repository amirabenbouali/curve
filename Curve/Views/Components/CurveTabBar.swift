import SwiftUI

enum CurveTab: CaseIterable {
    case today, log, progress, settings

    var label: String {
        switch self {
        case .today: return "Today"
        case .log: return "Log"
        case .progress: return "Progress"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .today: return "house.fill"
        case .log: return "list.bullet.rectangle.fill"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .settings: return "gearshape.fill"
        }
    }
}

struct CurveTabBar: View {
    @Binding var selection: CurveTab

    var body: some View {
        HStack {
            ForEach(CurveTab.allCases, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 17))
                        Text(tab.label)
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundStyle(selection == tab ? .white : .white.opacity(0.45))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 64)
        .glassCard(cornerRadius: 28, padding: 0)
        .padding(.horizontal, 18)
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        CurveBackground()
        CurveTabBar(selection: .constant(.today))
            .padding(.bottom, 12)
    }
}
