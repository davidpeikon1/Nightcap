import SwiftUI
import UserNotifications

struct SettingsSheet: View {
    @EnvironmentObject var store: FastingStore
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var selectedGoal: UserGoal?
    @State private var notificationsOn: Bool = false
    @State private var notifStatus: UNAuthorizationStatus = .notDetermined
    @State private var notifStatusLoaded = false
    @State private var showResetConfirm = false
    @State private var showResetOnboarding = false
    @State private var showExportSheet = false
    @State private var exportText: String = ""
    @State private var morningTime: Date = NotificationManager.shared.morningHour.asTime
    @State private var eveningTime: Date = NotificationManager.shared.eveningHour.asTime

    var body: some View {
        NavigationStack {
            ZStack {
                Color("NCBackground").ignoresSafeArea()

                List {
                    // MARK: Goal
                    Section {
                        ForEach(UserGoal.allCases) { goal in
                            goalRow(goal)
                        }
                    } header: {
                        sectionHeader("Your goal")
                    }
                    .listRowBackground(Color("NCSurface"))
                    .listRowSeparatorTint(Color("NCTextTertiary").opacity(0.3))

                    // MARK: Notifications
                    Section {
                        notificationRow
                        if notifStatus == .authorized {
                            timePicker("Morning", selection: $morningTime, enabled: notificationsOn) { h in
                                NotificationManager.shared.updateMorningHour(h)
                            }
                            timePicker("Evening", selection: $eveningTime, enabled: notificationsOn) { h in
                                NotificationManager.shared.updateEveningHour(h)
                            }
                        }
                    } header: {
                        sectionHeader("Reminders")
                    }
                    .listRowBackground(Color("NCSurface"))
                    .listRowSeparatorTint(Color("NCTextTertiary").opacity(0.3))

                    // MARK: App info
                    Section {
                        infoRow("Version", value: appVersion)
                        infoRow("Build", value: buildNumber)
                    } header: {
                        sectionHeader("About")
                    }
                    .listRowBackground(Color("NCSurface"))
                    .listRowSeparatorTint(Color("NCTextTertiary").opacity(0.3))

                    // MARK: Danger zone
                    Section {
                        Button {
                            exportText = buildExport()
                            showExportSheet = true
                        } label: {
                            Text("Export my data")
                                .font(.system(size: 15))
                                .foregroundStyle(Color("NCTextSecondary"))
                        }

                        Button {
                            showResetOnboarding = true
                        } label: {
                            Text("Replay intro")
                                .font(.system(size: 15))
                                .foregroundStyle(Color("NCTextSecondary"))
                        }

                        Button(role: .destructive) {
                            showResetConfirm = true
                        } label: {
                            Text("Clear all data")
                                .font(.system(size: 15))
                        }
                    } header: {
                        sectionHeader("Data")
                    }
                    .listRowBackground(Color("NCSurface"))
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color("NCAccent"))
                        .fontWeight(.medium)
                }
            }
        }
        .onAppear {
            selectedGoal = appState.userGoal
            checkNotificationStatus()
        }
        .confirmationDialog(
            "Clear all data?",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear everything", role: .destructive) {
                store.resetAllData()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete your fast history, badges, and craving logs. It cannot be undone.")
        }
        .confirmationDialog(
            "Replay the intro?",
            isPresented: $showResetOnboarding,
            titleVisibility: .visible
        ) {
            Button("Replay intro") {
                appState.advance(to: .hook)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showExportSheet) {
            ShareSheet(items: [exportText])
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Row builders

    private func goalRow(_ goal: UserGoal) -> some View {
        let isSelected = selectedGoal == goal
        return Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation(.spring(duration: 0.2)) {
                selectedGoal = goal
                appState.setGoal(goal)
            }
        } label: {
            HStack {
                Text(goal.rawValue)
                    .font(.system(size: 15))
                    .foregroundStyle(Color("NCTextPrimary"))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color("NCSuccess"))
                }
            }
        }
    }

    private var notificationRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Daily reminders")
                    .font(.system(size: 15))
                    .foregroundStyle(Color("NCTextPrimary"))
                Text(dailyNotifSubtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color("NCTextTertiary"))
            }

            Spacer()

            switch notifStatusLoaded ? notifStatus : nil {
            case .none:
                Color.clear.frame(width: 44, height: 31) // placeholder while status loads
            case .authorized:
                Toggle("", isOn: $notificationsOn)
                    .tint(Color("NCAccent"))
                    .labelsHidden()
                    .accessibilityLabel("Daily reminders")
                    .onChange(of: notificationsOn) { _, on in
                        if on {
                            NotificationManager.shared.scheduleDailyNotifications()
                        } else {
                            // Remove all daily check-in variants (legacy, weekday, and day-offset),
                            // but not proactive milestone notifications.
                            var ids = ["nightcap.morning", "nightcap.evening"]
                            for wd in 1...7 {
                                ids.append("nightcap.morning.wd\(wd)")
                                ids.append("nightcap.evening.wd\(wd)")
                            }
                            for d in 0..<14 {
                                ids.append("nightcap.morning.d\(d)")
                                ids.append("nightcap.evening.d\(d)")
                            }
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
                        }
                    }
            case .denied:
                Button("Open Settings") {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.system(size: 13))
                .foregroundStyle(Color("NCWarning"))
            default:
                Button("Enable") {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    NotificationManager.shared.requestPermission { granted in
                        notificationsOn = granted
                        checkNotificationStatus()
                    }
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color("NCAccent"))
            }
        }
    }

    private func timePicker(
        _ label: String,
        selection: Binding<Date>,
        enabled: Bool,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(enabled ? Color("NCTextPrimary") : Color("NCTextTertiary"))
            Spacer()
            DatePicker("", selection: selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .disabled(!enabled)
                .opacity(enabled ? 1 : 0.4)
                .onChange(of: selection.wrappedValue) { _, date in
                    onChange(Calendar.current.component(.hour, from: date))
                }
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(Color("NCTextPrimary"))
            Spacer()
            Text(value)
                .font(.system(size: 15))
                .foregroundStyle(Color("NCTextSecondary"))
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .medium))
            .tracking(1.5)
            .foregroundStyle(Color("NCTextSecondary"))
            .textCase(nil)
    }

    // MARK: - Helpers

    private func buildExport() -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short

        var lines: [String] = []
        lines.append("NIGHTCAP DATA EXPORT")
        lines.append("Exported: \(df.string(from: Date()))")
        if let goal = appState.userGoal {
            lines.append("Goal: \(goal.rawValue)")
        }
        lines.append("")

        // Current fast
        if let start = store.lastSugarDate {
            lines.append("CURRENT FAST")
            lines.append("Started: \(df.string(from: start))")
            lines.append("Elapsed: \(store.formattedElapsed)")
            lines.append("Phase: \(store.fastingPhase.rawValue)")
            lines.append("Streak: \(store.streakDays) day\(store.streakDays == 1 ? "" : "s")")
            lines.append("")
        }

        // All-time stats
        let totalSecs = store.totalSugarFreeTime
        if totalSecs > 0 {
            let td = Int(totalSecs) / 86400
            let th = (Int(totalSecs) % 86400) / 3600
            let totalStr = td > 0 ? (th > 0 ? "\(td)d \(th)h" : "\(td)d") : "\(th)h"
            lines.append("ALL-TIME STATS")
            lines.append("Total clean time: \(totalStr)")
            lines.append("Total fasts: \(store.resetEvents.count + (store.isTracking ? 1 : 0))")
            if store.bestStreakDays > 0 {
                lines.append("Best streak: \(store.bestStreakDays) day\(store.bestStreakDays == 1 ? "" : "s")")
            }
            lines.append("")
        }

        // Badges
        if !store.earnedBadges.isEmpty {
            lines.append("EARNED BADGES")
            for badge in BadgeID.allCases where store.earnedBadges.contains(badge) {
                lines.append("- \(badge.label)")
            }
            lines.append("")
        }

        // Reset history
        if !store.resetEvents.isEmpty {
            lines.append("RESET HISTORY")
            let df2 = DateFormatter()
            df2.dateStyle = .short
            df2.timeStyle = .none
            for event in store.resetEvents {
                let h = Int(event.fastDuration) / 3600
                let d = h / 24
                let duration = d > 0 ? "\(d)d \(h % 24)h fast" : "\(h)h fast"
                var line = "\(df2.string(from: event.date)): \(duration)"
                if let note = event.note, !note.isEmpty { line += "  (\(note))" }
                lines.append(line)
            }
            lines.append("")
        }

        // Craving log
        if !store.cravingLogs.isEmpty {
            lines.append("CRAVING LOG")
            for log in store.cravingLogs {
                lines.append("\(df.string(from: log.date)): \(log.trigger.rawValue)")
            }
            lines.append("")
        }

        // Behavioral analysis
        let totalCleanDays = Int(store.totalSugarFreeTime / 86400)
        if totalCleanDays >= 7 {
            lines.append("")
            lines.append("BEHAVIORAL ANALYSIS")
            // Average fast duration across all completed and current fasts.
            let totalFastCount = store.resetEvents.count + (store.isTracking ? 1 : 0)
            if totalFastCount > 0 {
                let avgSecs = store.totalSugarFreeTime / Double(totalFastCount)
                let avgH = Int(avgSecs) / 3600
                let avgD = avgH / 24
                let avgStr = avgD > 0
                    ? (avgH % 24 > 0 ? "\(avgD)d \(avgH % 24)h" : "\(avgD)d")
                    : "\(avgH)h"
                lines.append("Average fast length: \(avgStr)")
            }
            lines.append("Total resets logged: \(store.resetEvents.count)")

            if !store.cravingLogs.isEmpty {
                // Peak craving hour
                let cal = Calendar.current
                let hourCounts = Dictionary(
                    grouping: store.cravingLogs,
                    by: { cal.component(.hour, from: $0.date) }
                ).mapValues(\.count)
                if let peakHour = hourCounts.max(by: { $0.value < $1.value })?.key {
                    let ampm = peakHour >= 12 ? "pm" : "am"
                    let displayHour = peakHour == 0 ? 12 : (peakHour > 12 ? peakHour - 12 : peakHour)
                    lines.append("Peak craving window: \(displayHour)\(ampm)")
                }

                // Most common trigger
                var triggerCounts: [String: Int] = [:]
                for log in store.cravingLogs {
                    triggerCounts[log.trigger.rawValue, default: 0] += 1
                }
                if let topTrigger = triggerCounts.max(by: { $0.value < $1.value })?.key {
                    lines.append("Most common trigger: \(topTrigger)")
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notifStatus = settings.authorizationStatus
                if settings.authorizationStatus == .authorized {
                    UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in
                        DispatchQueue.main.async {
                            // Only check for the daily identifiers — milestone notifications
                            // exist separately and shouldn't drive this toggle.
                            notificationsOn = reqs.contains {
                                $0.identifier.hasPrefix("nightcap.morning") ||
                                $0.identifier.hasPrefix("nightcap.evening")
                            }
                            notifStatusLoaded = true
                        }
                    }
                } else {
                    notifStatusLoaded = true
                }
            }
        }
    }

    private var dailyNotifSubtitle: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .none
        fmt.timeStyle = .short
        let morning = fmt.string(from: morningTime)
        let evening = fmt.string(from: eveningTime)
        return "\(morning) reframe · \(evening) craving check-in"
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
