import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var allSessions: [WorkoutSession]

    @AppStorage("userName") private var userName = ""
    @AppStorage("weeklyGoal") private var weeklyGoal = 4
    @AppStorage("defaultRestSeconds") private var defaultRestSeconds = 90
    @AppStorage("weightUnit") private var weightUnitRaw = WeightUnit.lb.rawValue
    @AppStorage("workoutRemindersEnabled") private var remindersEnabled = true
    @AppStorage("streakRiskAlertsEnabled") private var streakRiskEnabled = true
    @AppStorage("weeklySummaryEnabled") private var weeklySummaryEnabled = false

    @State private var showingProfileSheet = false
    @State private var showingGoalSheet = false
    @State private var showingRestTimerSheet = false
    @State private var showingUnitsSheet = false
    @State private var showingHelpSheet = false
    @State private var showingPrivacySheet = false
    @State private var showingResetConfirmation = false
    @State private var showingPermissionDeniedAlert = false

    private var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .lb }

    private var streakResult: WeeklyStreakResult {
        StreakEngine.calculate(sessions: allSessions, weeklyGoal: weeklyGoal)
    }

    private var initials: String {
        let trimmed = userName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "?" }
        let parts = trimmed.split(separator: " ")
        return String(parts.prefix(2).compactMap { $0.first }).uppercased()
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        return "Curve · Version \(version)"
    }

    var body: some View {
        ZStack {
            CurveBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Settings")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.top, 8)

                    profileCard

                    sectionLabel("Training")
                    groupCard {
                        navRow(icon: "target", label: "Weekly goal", value: "\(weeklyGoal) workouts") { showingGoalSheet = true }
                        rowDivider
                        navRow(icon: "timer", label: "Default rest timer", value: TimeInterval(defaultRestSeconds).formattedRest()) { showingRestTimerSheet = true }
                        rowDivider
                        navRow(icon: "scalemass", label: "Units", value: weightUnit.label) { showingUnitsSheet = true }
                    }

                    sectionLabel("Streak")
                    groupCard {
                        HStack(spacing: 12) {
                            rowIcon("snowflake")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Streak freezes")
                                    .font(.system(size: 13.5, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text("\(streakResult.freezesAvailable) of 2 available · earn 1 every 4 weeks on goal")
                                    .font(.curveEyebrow(11.5))
                                    .foregroundStyle(CurveTheme.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                    }

                    sectionLabel("Notifications")
                    groupCard {
                        toggleRow(icon: "bell.fill", label: "Workout reminders", isOn: Binding(
                            get: { remindersEnabled },
                            set: { newValue in setReminders(newValue) }
                        ))
                        rowDivider
                        toggleRow(icon: "exclamationmark.triangle.fill", label: "Streak risk alerts", isOn: Binding(
                            get: { streakRiskEnabled },
                            set: { newValue in setStreakRisk(newValue) }
                        ))
                        rowDivider
                        toggleRow(icon: "chart.bar.fill", label: "Weekly summary", isOn: Binding(
                            get: { weeklySummaryEnabled },
                            set: { newValue in setWeeklySummary(newValue) }
                        ))
                    }

                    sectionLabel("About")
                    groupCard {
                        navRow(icon: "bubble.left.and.bubble.right.fill", label: "Help & Support") { showingHelpSheet = true }
                        rowDivider
                        navRow(icon: "lock.fill", label: "Privacy Policy") { showingPrivacySheet = true }
                    }

                    groupCard {
                        Button {
                            showingResetConfirmation = true
                        } label: {
                            HStack(spacing: 12) {
                                rowIcon("trash.fill")
                                Text("Reset All Data")
                                    .font(.system(size: 13.5, weight: .semibold))
                                    .foregroundStyle(Color(red: 0.941, green: 0.718, blue: 0.659))
                                Spacer()
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    Text(appVersion)
                        .font(.system(size: 11))
                        .foregroundStyle(CurveTheme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 110)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingProfileSheet) { ProfileEditSheet(userName: $userName) }
        .sheet(isPresented: $showingGoalSheet) { WeeklyGoalSheet(weeklyGoal: $weeklyGoal, onChange: { setWeeklyGoal($0) }) }
        .sheet(isPresented: $showingRestTimerSheet) { RestTimerSheet(seconds: $defaultRestSeconds) }
        .sheet(isPresented: $showingUnitsSheet) { UnitsSheet(weightUnitRaw: $weightUnitRaw) }
        .sheet(isPresented: $showingHelpSheet) { HelpSupportSheet() }
        .sheet(isPresented: $showingPrivacySheet) { PrivacyPolicySheet() }
        .confirmationDialog("Reset all data?", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
            Button("Reset All Data", role: .destructive) { resetAllData() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes all workouts, templates, body stats, and custom exercises. This can't be undone.")
        }
        .alert("Notifications Disabled", isPresented: $showingPermissionDeniedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Enable notifications for Curve in the Settings app to turn this on.")
        }
    }

    // MARK: - Notification toggle handlers

    private func setReminders(_ newValue: Bool) {
        remindersEnabled = newValue
        applyNotificationChange(turnedOn: newValue) { remindersEnabled = false }
    }

    private func setStreakRisk(_ newValue: Bool) {
        streakRiskEnabled = newValue
        applyNotificationChange(turnedOn: newValue) { streakRiskEnabled = false }
        if !newValue { NotificationManager.cancelStreakRiskAlert() }
    }

    private func setWeeklySummary(_ newValue: Bool) {
        weeklySummaryEnabled = newValue
        applyNotificationChange(turnedOn: newValue) { weeklySummaryEnabled = false }
    }

    private func setWeeklyGoal(_ newValue: Int) {
        weeklyGoal = newValue
        refreshNotifications()
    }

    private func applyNotificationChange(turnedOn: Bool, revert: @escaping () -> Void) {
        Task {
            if turnedOn {
                let granted = await NotificationManager.requestAuthorizationIfNeeded()
                if !granted {
                    await MainActor.run {
                        revert()
                        showingPermissionDeniedAlert = true
                    }
                    return
                }
            }
            refreshNotifications()
        }
    }

    private func refreshNotifications() {
        NotificationManager.refreshAll(
            sessions: allSessions,
            weeklyGoal: weeklyGoal,
            remindersEnabled: remindersEnabled,
            streakRiskEnabled: streakRiskEnabled,
            weeklySummaryEnabled: weeklySummaryEnabled
        )
    }

    // MARK: - Data reset

    private func resetAllData() {
        for session in allSessions { context.delete(session) }
        if let templates = try? context.fetch(FetchDescriptor<WorkoutTemplate>()) {
            templates.forEach { context.delete($0) }
        }
        if let entries = try? context.fetch(FetchDescriptor<BodyStatEntry>()) {
            entries.forEach { context.delete($0) }
        }
        let customPredicate = #Predicate<Exercise> { $0.isCustom }
        if let customExercises = try? context.fetch(FetchDescriptor(predicate: customPredicate)) {
            customExercises.forEach { context.delete($0) }
        }
        try? context.save()
        NotificationManager.refreshAll(sessions: [], weeklyGoal: weeklyGoal, remindersEnabled: remindersEnabled, streakRiskEnabled: streakRiskEnabled, weeklySummaryEnabled: weeklySummaryEnabled)
    }

    // MARK: - Building blocks

    private var profileCard: some View {
        Button {
            showingProfileSheet = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(CurveTheme.glossyIconFill)
                    Text(initials)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 56, height: 56)
                .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 1))

                VStack(alignment: .leading, spacing: 2) {
                    Text(userName.isEmpty ? "Add your name" : userName)
                        .font(.system(size: 16.5, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Tap to edit profile")
                        .font(.curveEyebrow(12.5))
                        .foregroundStyle(CurveTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .glassCard(padding: 20)
        }
        .buttonStyle(.plain)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11.5, weight: .bold))
            .tracking(1)
            .foregroundStyle(.white.opacity(0.55))
            .padding(.leading, 4)
    }

    private func groupCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0, content: content)
            .glassCard(cornerRadius: 20, padding: 0)
    }

    private var rowDivider: some View {
        Divider()
            .overlay(Color.white.opacity(0.14))
            .padding(.leading, 58)
    }

    private func rowIcon(_ systemName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous).fill(CurveTheme.glossyIconFill)
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 30, height: 30)
    }

    private func navRow(icon: String, label: String, value: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                rowIcon(icon)
                Text(label)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                if let value {
                    Text(value)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(CurveTheme.textSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(icon: String, label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            rowIcon(icon)
            Text(label)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color(red: 0.576, green: 0.659, blue: 0.612))
                .allowsHitTesting(false)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            isOn.wrappedValue.toggle()
        }
    }
}

// MARK: - Sheets

private struct ProfileEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var userName: String
    @State private var draft: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                CurveBackground()
                Form {
                    TextField("Your name", text: $draft)
                        .textInputAutocapitalization(.words)
                }
                .curveScrollBackground()
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        userName = draft.trimmingCharacters(in: .whitespaces)
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { draft = userName }
    }
}

private struct WeeklyGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var weeklyGoal: Int
    var onChange: (Int) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                CurveBackground()
                VStack(spacing: 24) {
                    Text("\(weeklyGoal)")
                        .font(.system(size: 56, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("workouts / week")
                        .font(.curveEyebrow(15))
                        .foregroundStyle(CurveTheme.textSecondary)
                    Stepper("", value: Binding(get: { weeklyGoal }, set: { onChange($0) }), in: 1...7)
                        .labelsHidden()
                        .tint(.white)
                }
                .padding(.top, 40)
            }
            .navigationTitle("Weekly Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct RestTimerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var seconds: Int

    var body: some View {
        NavigationStack {
            ZStack {
                CurveBackground()
                VStack(spacing: 24) {
                    Text(TimeInterval(seconds).formattedRest())
                        .font(.system(size: 56, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("default rest between sets")
                        .font(.curveEyebrow(15))
                        .foregroundStyle(CurveTheme.textSecondary)
                    Stepper("", value: $seconds, in: 15...300, step: 15)
                        .labelsHidden()
                        .tint(.white)
                }
                .padding(.top, 40)
            }
            .navigationTitle("Default Rest Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct UnitsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var weightUnitRaw: String

    var body: some View {
        NavigationStack {
            ZStack {
                CurveBackground()
                VStack(spacing: 20) {
                    Picker("Units", selection: $weightUnitRaw) {
                        ForEach(WeightUnit.allCases) { unit in
                            Text(unit.label == "lb" ? "Pounds (lb)" : "Kilograms (kg)").tag(unit.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)

                    Text("Applies to workout weights and body weight. Existing entries convert automatically for display.")
                        .font(.curveEyebrow(13))
                        .foregroundStyle(CurveTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 32)
            }
            .navigationTitle("Units")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct HelpSupportSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                CurveBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        helpItem(title: "Logging a workout", body: "Start a workout from Today or Log, then work through each exercise one set at a time. Tap any exercise in the order list to jump to it.")
                        helpItem(title: "Templates", body: "Save a routine as a template from Settings → Manage Templates so you can start it again with one tap.")
                        helpItem(title: "Streaks & freezes", body: "Hit your weekly workout goal to build a streak. Every 4 weeks on goal banks a streak freeze that automatically covers a missed week, up to 2 banked.")
                        helpItem(title: "Your data", body: "Everything in Curve is stored only on this device. Reset All Data in Settings permanently erases it.")
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func helpItem(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14.5, weight: .bold))
                .foregroundStyle(.white)
            Text(body)
                .font(.system(size: 13))
                .foregroundStyle(CurveTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 18, padding: 16)
    }
}

private struct PrivacyPolicySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                CurveBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("All your data — workouts, templates, body stats, and settings — is stored locally on this device using SwiftData. Curve has no backend server and no account system, so nothing is ever transmitted, synced, or shared.")
                        Text("If you enable notifications, reminders are scheduled locally by iOS. No workout data leaves your device to generate them.")
                        Text("Deleting Curve, or using Reset All Data in Settings, permanently erases everything.")
                    }
                    .font(.system(size: 13.5))
                    .foregroundStyle(CurveTheme.textSecondary)
                    .padding(20)
                    .glassCard()
                    .padding(20)
                }
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(PreviewData.container)
}
