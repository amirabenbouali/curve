import SwiftUI

struct SettingsView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("weeklyGoal") private var weeklyGoal = 4

    var body: some View {
        ZStack {
            CurveBackground()
            ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Settings")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(CurveTheme.textPrimary)
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 14) {
                    sectionLabel("PROFILE")
                    HStack {
                        Text("Name")
                            .foregroundStyle(.white)
                        Spacer()
                        TextField("Your name", text: $userName)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(CurveTheme.textSecondary)
                            .textInputAutocapitalization(.words)
                    }
                }
                .glassCard()

                VStack(alignment: .leading, spacing: 14) {
                    sectionLabel("WEEKLY GOAL")
                    Stepper(value: $weeklyGoal, in: 1...7) {
                        HStack {
                            Text("\(weeklyGoal) workout\(weeklyGoal == 1 ? "" : "s") / week")
                                .foregroundStyle(.white)
                        }
                    }
                    .tint(.white)
                    Text("Your week streak on Today counts consecutive weeks you hit this goal. Every 4 weeks in a row banks a streak freeze (up to 2) that automatically covers a missed week.")
                        .font(.curveEyebrow(12.5))
                        .foregroundStyle(CurveTheme.textSecondary)
                }
                .glassCard()

                NavigationLink {
                    BodyStatsView()
                } label: {
                    HStack {
                        ZStack {
                            Circle().fill(.white.opacity(0.16))
                            Image(systemName: "figure.stand").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                        }
                        .frame(width: 30, height: 30)
                        Text("Body Stats")
                            .foregroundStyle(.white)
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CurveTheme.textTertiary)
                    }
                    .glassCard(cornerRadius: 18, padding: 14)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    TemplatesListView()
                } label: {
                    HStack {
                        ZStack {
                            Circle().fill(.white.opacity(0.16))
                            Image(systemName: "square.stack.3d.up.fill").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                        }
                        .frame(width: 30, height: 30)
                        Text("Manage Templates")
                            .foregroundStyle(.white)
                            .font(.system(size: 15, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CurveTheme.textTertiary)
                    }
                    .glassCard(cornerRadius: 18, padding: 14)
                }
                .buttonStyle(.plain)

                Text("Curve · v1.0")
                    .font(.caption)
                    .foregroundStyle(CurveTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 110)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(CurveTheme.textTertiary)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(PreviewData.container)
}
