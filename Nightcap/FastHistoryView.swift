import SwiftUI
import Charts

struct FastHistoryView: View {
    @EnvironmentObject var store: FastingStore
    @Environment(\.dismiss) var dismiss

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
        HStack(spacing: 12) {
            statCard(
                value: formatHoursCompact(store.longestFastEver),
                label: "Longest fast"
            )
            statCard(
                value: "\(store.streakDays)",
                label: "Day streak"
            )
            statCard(
                value: "\(store.resetEvents.count)",
                label: "Total resets"
            )
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

    private var currentFastRow: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color("NCSuccess"))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text("In progress")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color("NCTextPrimary"))
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
}
