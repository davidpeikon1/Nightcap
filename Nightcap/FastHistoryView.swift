import SwiftUI
import Charts
import UIKit

struct FastHistoryView: View {
    @EnvironmentObject var store: FastingStore
    @Environment(\.dismiss) var dismiss
    @State private var showAllCravings = false
    @State private var editingReset: ResetEvent? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color("NCBackground").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if !store.historyChartData.isEmpty {
                            chartCard
                        }
                        statsRow
                        if let trend = trendInsightText {
                            trendCard(trend)
                        }
                        if store.isTracking || !store.resetEvents.isEmpty {
                            activityGrid
                        }
                        if store.resetEvents.isEmpty && !store.isTracking {
                            emptyState
                        } else {
                            resetList
                        }
                        if !store.cravingLogs.isEmpty {
                            cravingInsightsCard
                        }
                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color("NCAccent"))
                        .fontWeight(.medium)
                }
            }
            .sheet(item: $editingReset) { event in
                EditNoteSheet(event: event)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Chart Card

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("FASTING HISTORY")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(Color("NCTextSecondary"))
                Spacer()
                Text("hours per fast")
                    .font(.system(size: 11))
                    .foregroundStyle(Color("NCTextTertiary"))
            }

            Chart(store.historyChartData) { entry in
                BarMark(
                    x: .value("Fast", entry.index),
                    y: .value("Hours", entry.hours)
                )
                .foregroundStyle(barColor(for: entry.hours).gradient)
                .cornerRadius(4)
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color("NCTextTertiary").opacity(0.3))
                    AxisValueLabel {
                        if let h = value.as(Double.self) {
                            Text(formatAxisHours(h))
                                .font(.system(size: 9))
                                .foregroundStyle(Color("NCTextTertiary"))
                        }
                    }
                }
            }
            .frame(height: 140)
            .accessibilityLabel(chartAccessibilityLabel)
            .accessibilityHint("Bar chart showing fasting duration for each past fast")

            // Legend
            HStack(spacing: 16) {
                legendDot(color: Color("NCTextTertiary").opacity(0.5), label: "< 24h")
                legendDot(color: Color("NCWarning").opacity(0.7),      label: "1–3 days")
                legendDot(color: Color("NCSuccess"),                   label: "3+ days")
            }
        }
        .padding(20)
        .background(Color("NCSurface"))
        .cornerRadius(16)
    }

    // MARK: - Trend Insight

    /// Compares the 3 most recent completed fasts against the 3 before them.
    /// Returns nil when there's insufficient data or the difference is trivial.
    private var trendInsightText: String? {
        let durations = store.resetEvents.map(\.fastDuration)
        guard durations.count >= 4 else { return nil }
        let recent = Array(durations.prefix(3))
        let older  = Array(durations.dropFirst(3).prefix(3))
        guard !older.isEmpty else { return nil }
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let olderAvg  = older.reduce(0, +)  / Double(older.count)
        let diffH = (recentAvg - olderAvg) / 3600
        guard abs(diffH) >= 2 else { return nil }
        if diffH > 0 {
            let h = Int(diffH)
            return "Your last \(recent.count) fasts averaged \(h)h longer than the \(older.count) before them. The trend is moving in the right direction."
        } else {
            let h = Int(-diffH)
            return "Your recent fasts are averaging \(h)h shorter. Patterns usually have a cause worth logging."
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        let longestText    = store.longestFastEver > 0 ? formatHoursCompact(store.longestFastEver) : "—"
        let totalText      = store.totalSugarFreeTime > 0 ? formatHoursCompact(store.totalSugarFreeTime) : "—"
        let bestStreakText  = store.bestStreakDays > 0 ? "\(store.bestStreakDays)d" : "—"

        // Show average only when there are 2+ completed fasts — one data point isn't a pattern.
        let showAvg = store.resetEvents.count >= 2
        let avgText: String = {
            guard showAvg else { return "—" }
            let total = store.resetEvents.map(\.fastDuration).reduce(0, +)
            return formatHoursCompact(total / Double(store.resetEvents.count))
        }()

        return VStack(spacing: 12) {
            if showAvg {
                HStack(spacing: 12) {
                    statCard(value: longestText,   label: "Longest fast")
                    statCard(value: avgText,        label: "Avg. fast")
                    statCard(value: bestStreakText, label: "Best streak")
                }
            } else {
                HStack(spacing: 12) {
                    statCard(value: longestText,   label: "Longest fast")
                    statCard(value: bestStreakText, label: "Best streak")
                }
            }
            HStack(spacing: 12) {
                statCard(value: "\(store.resetEvents.count)", label: "Resets")
                statCard(value: totalText,                    label: "Time fasted")
            }
        }
    }

    private func trendCard(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Color("NCSuccess").opacity(0.7))
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Color("NCTextSecondary"))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color("NCSurface"))
        .cornerRadius(12)
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .light).monospacedDigit())
                .foregroundStyle(Color("NCTextPrimary"))
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color("NCTextSecondary"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color("NCSurface"))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Reset List

    private var resetList: some View {
        VStack(alignment: .leading, spacing: 12) {
            if store.isTracking {
                Text("CURRENT FAST")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(Color("NCTextSecondary"))

                currentFastRow
            }

            if !store.resetEvents.isEmpty {
                Text(store.resetEvents.count == 1 ? "PAST FAST" : "PAST FASTS")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(Color("NCTextSecondary"))
                    .padding(.top, store.isTracking ? 8 : 0)

                VStack(spacing: 0) {
                    ForEach(Array(store.resetEvents.enumerated()), id: \.element.id) { idx, event in
                        resetRow(event: event, isLast: idx == store.resetEvents.count - 1)
                    }
                }
                .background(Color("NCSurface"))
                .cornerRadius(12)
            }
        }
    }

    /// True when the current fast is strictly longer than all previous fasts.
    private var isPersonalBest: Bool {
        guard store.isTracking else { return false }
        let previousBest = store.resetEvents.map(\.fastDuration).max() ?? 0
        return store.elapsedSeconds > previousBest
    }

    private var currentFastRow: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color("NCSuccess"))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("In progress")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color("NCTextPrimary"))
                    if isPersonalBest {
                        Text("PB")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Color("NCSuccess"))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color("NCSuccess").opacity(0.12))
                            .cornerRadius(4)
                    }
                }
                Text(store.formattedElapsed + " · " + store.fastingPhase.rawValue)
                    .font(.system(size: 12))
                    .foregroundStyle(Color("NCTextSecondary"))
            }

            Spacer()

            Text(store.lastSugarDate.map { relativeDate($0) } ?? "")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color("NCTextTertiary"))
        }
        .padding(16)
        .background(Color("NCSurface"))
        .cornerRadius(12)
    }

    private func resetRow(event: ResetEvent, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Circle()
                    .fill(Color("NCTextTertiary").opacity(0.4))
                    .frame(width: 6, height: 6)

                VStack(alignment: .leading, spacing: 3) {
                    Text(formatDuration(event.fastDuration))
                        .font(.system(size: 14))
                        .foregroundStyle(Color("NCTextPrimary"))
                    if let note = event.note, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 12))
                            .foregroundStyle(Color("NCTextSecondary"))
                    }
                }

                Spacer()

                Text(relativeDate(event.date))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color("NCTextTertiary"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contextMenu {
                Button {
                    editingReset = event
                } label: {
                    Label("Edit note", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    withAnimation {
                        store.deleteResetEvent(id: event.id)
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }

            if !isLast {
                Rectangle()
                    .fill(Color("NCTextTertiary").opacity(0.2))
                    .frame(height: 1)
                    .padding(.leading, 36)
            }
        }
    }

    // MARK: - Activity Grid (28-day heatmap)

    private enum DayStatus { case clean, reset, notTracking }

    private var activityGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("LAST 4 WEEKS")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(Color("NCTextSecondary"))
                Spacer()
                HStack(spacing: 10) {
                    legendDot(color: Color("NCSuccess").opacity(0.7), label: "clean day")
                    legendDot(color: Color("NCWarning").opacity(0.5), label: "reset day")
                }
            }

            let days = last28Days()
            let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            let weekdayLetters = days.prefix(7).map { date -> String in
                let wd = Calendar.current.component(.weekday, from: date) // 1=Sun...7=Sat
                return ["S","M","T","W","T","F","S"][wd - 1]
            }

            LazyVGrid(columns: gridColumns, spacing: 2) {
                ForEach(Array(weekdayLetters.enumerated()), id: \.offset) { _, letter in
                    Text(letter)
                        .font(.system(size: 9, weight: .regular))
                        .foregroundStyle(Color("NCTextTertiary").opacity(0.7))
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(
                columns: gridColumns,
                spacing: 4
            ) {
                ForEach(days, id: \.self) { date in
                    let status = statusForDay(date)
                    let isToday = Calendar.current.isDateInToday(date)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            status == .clean ? Color("NCSuccess").opacity(0.65) :
                            status == .reset ? Color("NCWarning").opacity(0.5)  :
                                               Color("NCTextTertiary").opacity(0.12)
                        )
                        .frame(height: 20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color("NCSuccess"), lineWidth: 1.5)
                                .opacity(isToday ? 1 : 0)
                        )
                        .accessibilityLabel(accessibilityDayLabel(date: date, status: status))
                }
            }
        }
        .padding(20)
        .background(Color("NCSurface"))
        .cornerRadius(16)
    }

    private func last28Days() -> [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<28).reversed().compactMap { i in
            cal.date(byAdding: .day, value: -i, to: today)
        }
    }

    private func statusForDay(_ date: Date) -> DayStatus {
        let cal = Calendar.current
        let day = cal.startOfDay(for: date)
        let hadReset = store.resetEvents.contains { cal.startOfDay(for: $0.date) == day }
        if hadReset { return .reset }
        guard let lastSugar = store.lastSugarDate,
              cal.startOfDay(for: lastSugar) <= day else {
            return .notTracking
        }
        return .clean
    }

    private func accessibilityDayLabel(date: Date, status: DayStatus) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium; df.timeStyle = .none
        let label: String
        switch status {
        case .clean:       label = "clean"
        case .reset:       label = "reset"
        case .notTracking: label = "not tracked"
        }
        return "\(df.string(from: date)): \(label)"
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 36, weight: .thin))
                .foregroundStyle(Color("NCTextTertiary"))
            Text("No resets yet.")
                .font(.system(size: 17, weight: .light))
                .foregroundStyle(Color("NCTextPrimary"))
            Text("Every fast you log will build a picture of your patterns here.")
                .font(.system(size: 14))
                .foregroundStyle(Color("NCTextSecondary"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Helpers

    private var chartAccessibilityLabel: String {
        let data = store.historyChartData
        guard !data.isEmpty else { return "No fasting history yet." }
        let longest = data.map(\.hours).max() ?? 0
        let avg = data.map(\.hours).reduce(0, +) / Double(data.count)
        return "\(data.count) fast\(data.count == 1 ? "" : "s") recorded. Longest: \(formatHoursCompact(longest * 3600)). Average: \(formatHoursCompact(avg * 3600))."
    }

    private func barColor(for hours: Double) -> Color {
        if hours >= 72 { return Color("NCSuccess") }
        if hours >= 24 { return Color("NCWarning").opacity(0.7) }
        return Color("NCTextTertiary").opacity(0.5)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(.system(size: 10)).foregroundStyle(Color("NCTextTertiary"))
        }
    }

    private func formatHoursCompact(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let d = h / 24
        let rem = h % 24
        if d > 0 { return rem > 0 ? "\(d)d \(rem)h" : "\(d)d" }
        return "\(h)h"
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let d = h / 24
        let m = (Int(seconds) % 3600) / 60
        if seconds < 60 { return "< 1 min fast" }
        if d > 0 { return "\(d)d \(h % 24)h \(m)m fast" }
        if h > 0 { return "\(h)h \(m)m fast" }
        return "\(m)m fast"
    }

    private func formatAxisHours(_ h: Double) -> String {
        if h >= 24 { return "\(Int(h / 24))d" }
        return "\(Int(h))h"
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Craving Insights Card

    /// One-sentence synthesis of the dominant craving pattern. Nil when data is insufficient.
    private var cravingInsightLine: String? {
        let logs = store.cravingLogs
        guard logs.count >= 3 else { return nil }

        let total = logs.count
        let triggerCounts = CravingTrigger.allCases.map { t in (t, logs.filter { $0.trigger == t }.count) }
        if let (dominant, count) = triggerCounts.max(by: { $0.1 < $1.1 }),
           count >= 2, count * 2 >= total {
            let pct = Int(Double(count) / Double(total) * 100)
            switch dominant {
            case .stress:   return "Stress is driving \(pct)% of your cravings. The urge passes in 15–20 minutes whether you act on it or not."
            case .boredom:  return "Boredom is your dominant trigger (\(pct)%). The pull disappears when you redirect attention — it doesn't require willpower."
            case .habit:    return "\(pct)% of your cravings are conditioned habit responses, not physiological need. Conditioned responses can be unconditioned."
            case .social:   return "Social situations are your highest-risk context (\(pct)%). Anticipating them in advance is most of the defense."
            case .fatigue:  return "Low energy is triggering \(pct)% of your cravings. Blood sugar stability improves significantly around week 2."
            case .hunger:   return "Genuine hunger is driving \(pct)% of your logged cravings. Protein and fat both satisfy without the dopamine spike."
            }
        }

        let cal = Calendar.current
        let eveningCount = logs.filter { (18...23).contains(cal.component(.hour, from: $0.date)) }.count
        if eveningCount >= 2, eveningCount * 2 > total {
            return "Most of your cravings hit in the evening. That window is where the pattern lives."
        }

        return nil
    }

    private var cravingInsightsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("CRAVING PATTERNS")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(Color("NCTextSecondary"))
                Spacer()
                Text("\(store.cravingLogs.count) total")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color("NCTextTertiary"))
            }

            if let insight = cravingInsightLine {
                Text(insight)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color("NCTextSecondary"))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color("NCBackground"))
                    .cornerRadius(10)
            }

            // Trigger breakdown bars — sorted by count descending so the most relevant triggers surface first.
            let sortedTriggers = CravingTrigger.allCases.sorted { a, b in
                let countA = store.cravingLogs.filter { $0.trigger == a }.count
                let countB = store.cravingLogs.filter { $0.trigger == b }.count
                return countA > countB
            }
            VStack(spacing: 10) {
                ForEach(sortedTriggers) { trigger in
                    triggerBar(trigger)
                }
            }

            // Time-of-day breakdown
            if store.cravingLogs.count >= 3 {
                Rectangle()
                    .fill(Color("NCTextTertiary").opacity(0.3))
                    .frame(height: 1)
                timeOfDayRow
            }

            // Recent entries
            if !store.cravingLogs.isEmpty {
                Rectangle()
                    .fill(Color("NCTextTertiary").opacity(0.3))
                    .frame(height: 1)

                let visibleLogs = showAllCravings
                    ? Array(store.cravingLogs.enumerated())
                    : Array(store.cravingLogs.prefix(5).enumerated())
                let lastIdx = visibleLogs.indices.last ?? 0

                VStack(spacing: 0) {
                    ForEach(visibleLogs, id: \.element.id) { idx, log in
                        cravingRow(log: log, isLast: idx == lastIdx)
                    }
                }
                .background(Color("NCBackground"))
                .cornerRadius(8)

                if store.cravingLogs.count > 5 {
                    Button {
                        withAnimation(.spring(duration: 0.35)) {
                            showAllCravings.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(showAllCravings
                                 ? "Show less"
                                 : "Show all \(store.cravingLogs.count)")
                                .font(.system(size: 12))
                            Image(systemName: showAllCravings ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .light))
                        }
                        .foregroundStyle(Color("NCTextSecondary"))
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding(20)
        .background(Color("NCSurface"))
        .cornerRadius(16)
    }

    private func triggerBar(_ trigger: CravingTrigger) -> some View {
        let count  = store.cravingLogs.filter { $0.trigger == trigger }.count
        let total  = max(1, store.cravingLogs.count)
        let fraction = Double(count) / Double(total)

        return HStack(spacing: 10) {
            Text(trigger.rawValue)
                .font(.system(size: 12))
                .foregroundStyle(Color("NCTextSecondary"))
                .frame(width: 140, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color("NCBackground"))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(count > 0 ? Color("NCWarning").opacity(0.7) : Color.clear)
                        .frame(width: geo.size.width * fraction, height: 6)
                }
            }
            .frame(height: 6)

            Text("\(count)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color("NCTextTertiary"))
                .frame(width: 20, alignment: .trailing)
        }
    }

    private var timeOfDayRow: some View {
        let logs = store.cravingLogs
        func count(in range: ClosedRange<Int>) -> Int {
            logs.filter { range.contains(Calendar.current.component(.hour, from: $0.date)) }.count
        }
        let slots: [(label: String, icon: String, count: Int)] = [
            ("Morning",   "sunrise",      count(in: 6...11)),
            ("Afternoon", "sun.max",      count(in: 12...17)),
            ("Evening",   "sunset",       count(in: 18...21)),
            ("Night",     "moon.stars",   count(in: 22...23) + count(in: 0...5)),
        ]
        let maxCount = max(1, slots.map(\.count).max() ?? 1)

        return VStack(alignment: .leading, spacing: 8) {
            Text("TIME OF DAY")
                .font(.system(size: 10, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(Color("NCTextTertiary"))

            HStack(spacing: 8) {
                ForEach(slots, id: \.label) { slot in
                    VStack(spacing: 6) {
                        GeometryReader { geo in
                            VStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(
                                        slot.count == maxCount && slot.count > 0
                                            ? Color("NCWarning").opacity(0.7)
                                            : Color("NCTextTertiary").opacity(0.25)
                                    )
                                    .frame(
                                        height: slot.count == 0 ? 3
                                            : max(6, geo.size.height * CGFloat(slot.count) / CGFloat(maxCount))
                                    )
                            }
                        }
                        .frame(height: 40)

                        Image(systemName: slot.icon)
                            .font(.system(size: 10, weight: .light))
                            .foregroundStyle(Color("NCTextTertiary"))

                        Text(slot.label)
                            .font(.system(size: 9))
                            .foregroundStyle(Color("NCTextTertiary"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(slot.label): \(slot.count) craving\(slot.count == 1 ? "" : "s")")
                }
            }
        }
    }

    private func cravingRow(log: CravingLog, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color("NCWarning").opacity(0.5))
                    .frame(width: 6, height: 6)
                Text(log.trigger.rawValue)
                    .font(.system(size: 13))
                    .foregroundStyle(Color("NCTextPrimary"))
                Spacer()
                Text(relativeDate(log.date))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color("NCTextTertiary"))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 2)
            .contextMenu {
                Button(role: .destructive) {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    withAnimation {
                        store.deleteCravingLog(id: log.id)
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }

            if !isLast {
                Rectangle()
                    .fill(Color("NCTextTertiary").opacity(0.2))
                    .frame(height: 1)
            }
        }
    }
}

// MARK: - Edit Note Sheet

struct EditNoteSheet: View {
    let event: ResetEvent
    @EnvironmentObject var store: FastingStore
    @Environment(\.dismiss) var dismiss
    @State private var note: String

    init(event: ResetEvent) {
        self.event = event
        self._note = State(initialValue: event.note ?? "")
    }

    var body: some View {
        ZStack {
            Color("NCBackground").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edit note")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(Color("NCTextPrimary"))

                    Text(durationLabel + " · " + dateLabel)
                        .font(.system(size: 14))
                        .foregroundStyle(Color("NCTextSecondary"))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("NOTE")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(Color("NCTextTertiary"))

                    TextField("e.g. birthday cake, work stress, social pressure", text: $note)
                        .font(.system(size: 15))
                        .foregroundStyle(Color("NCTextPrimary"))
                        .padding(14)
                        .background(Color("NCSurface"))
                        .cornerRadius(10)
                        .submitLabel(.done)
                        .onSubmit {
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil, from: nil, for: nil
                            )
                        }
                        .onChange(of: note) { _, v in
                            if v.count > 120 { note = String(v.prefix(120)) }
                        }

                    if note.count > 80 {
                        HStack {
                            Spacer()
                            Text("\(note.count) / 120")
                                .font(.system(size: 11))
                                .foregroundStyle(
                                    note.count > 110 ? Color("NCWarning") : Color("NCTextTertiary")
                                )
                        }
                        .padding(.top, 2)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: note.count > 80)
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        store.updateResetEventNote(id: event.id, note: note.isEmpty ? nil : note)
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color("NCBackground"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color("NCAccent"))
                            .cornerRadius(12)
                    }

                    Button { dismiss() } label: {
                        Text("Cancel")
                            .font(.system(size: 14))
                            .foregroundStyle(Color("NCTextSecondary"))
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding(24)
        }
        .onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }

    private var durationLabel: String {
        let h = Int(event.fastDuration) / 3600
        let d = h / 24
        let m = (Int(event.fastDuration) % 3600) / 60
        if d > 0 { return "\(d)d \(h % 24)h \(m)m" }
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    private var dateLabel: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: event.date, relativeTo: Date())
    }
}
