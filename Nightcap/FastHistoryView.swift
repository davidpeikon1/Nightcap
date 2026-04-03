import SwiftUI
import Charts

struct FastHistoryView: View {
    @EnvironmentObject var store: FastingStore
    @Environment(\.dismiss) var dismiss
    @State private var showAllCravings = false

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
            .navigationTitle("Fast History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color("NCAccent"))
                        .fontWeight(.medium)
                }
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

    // MARK: - Stats Row

    private var statsRow: some View {
        let longestText = store.longestFastEver > 0
            ? formatHoursCompact(store.longestFastEver)
            : "—"
        let totalText = store.totalSugarFreeTime > 0
            ? formatHoursCompact(store.totalSugarFreeTime)
            : "—"
        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                statCard(value: longestText,                  label: "Longest fast")
                statCard(value: "\(store.streakDays)",        label: "Day streak")
            }
            HStack(spacing: 12) {
                statCard(value: "\(store.resetEvents.count)", label: "Total resets")
                statCard(value: totalText,                    label: "Total clean time")
            }
        }
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
                Text("PAST FASTS")
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
        return store.elapsedSeconds > previousBest && previousBest > 0
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

            if !isLast {
                Rectangle()
                    .fill(Color("NCTextTertiary").opacity(0.2))
                    .frame(height: 1)
                    .padding(.leading, 36)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 36, weight: .thin))
                .foregroundStyle(Color("NCTextTertiary"))
            Text("No history yet.")
                .font(.system(size: 17, weight: .light))
                .foregroundStyle(Color("NCTextPrimary"))
            Text("Your past fasts will appear here.")
                .font(.system(size: 14))
                .foregroundStyle(Color("NCTextSecondary"))
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
        if d > 0 { return "\(d)d \(h % 24)h" }
        return "\(h)h"
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let d = h / 24
        let m = (Int(seconds) % 3600) / 60
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

    private var cravingInsightsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("CRAVING LOG")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(Color("NCTextSecondary"))
                Spacer()
                Text("\(store.cravingLogs.count) total")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color("NCTextTertiary"))
            }

            // Trigger breakdown bars
            VStack(spacing: 10) {
                ForEach(CravingTrigger.allCases) { trigger in
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
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

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
        let morning   = count(in: 6...11)
        let afternoon = count(in: 12...17)
        let evening   = count(in: 18...21)
        let night     = count(in: 22...23) + count(in: 0...5)
        let peak      = [("Morning", morning), ("Afternoon", afternoon), ("Evening", evening), ("Night", night)]
            .max(by: { $0.1 < $1.1 })
        return HStack {
            Image(systemName: "clock")
                .font(.system(size: 11, weight: .light))
                .foregroundStyle(Color("NCTextTertiary"))
            Text(peak.map { "Most cravings: \($0.0)" } ?? "")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(Color("NCTextSecondary"))
            Spacer()
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

            if !isLast {
                Rectangle()
                    .fill(Color("NCTextTertiary").opacity(0.2))
                    .frame(height: 1)
            }
        }
    }
}
