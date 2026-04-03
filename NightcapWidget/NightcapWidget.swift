import WidgetKit
import SwiftUI

// MARK: - Shared data loader

struct WidgetFastData {
    let lastSugarDate: Date?

    static func load() -> WidgetFastData {
        let defaults = UserDefaults(suiteName: "group.com.nightcap.app") ?? .standard
        return WidgetFastData(
            lastSugarDate: defaults.object(forKey: "lastSugarDate") as? Date
        )
    }

    func elapsed(at date: Date) -> TimeInterval {
        guard let d = lastSugarDate else { return 0 }
        return max(0, date.timeIntervalSince(d))
    }

    func phase(at date: Date) -> String {
        let h = elapsed(at: date) / 3600
        switch h {
        case ..<1:      return "Starting Out"
        case 1..<24:    return "First Day"
        case 24..<72:   return "Withdrawal"
        case 72..<168:  return "Breakthrough"
        case 168..<336: return "Rewiring"
        default:        return "Freedom"
        }
    }

    func phaseProgress(at date: Date) -> Double {
        let s = elapsed(at: date)
        let h = s / 3600
        let (prev, next): (Double, Double) = {
            switch h {
            case ..<1:      return (0, 3_600)
            case 1..<24:    return (3_600, 86_400)
            case 24..<72:   return (86_400, 259_200)
            case 72..<168:  return (259_200, 604_800)
            case 168..<336: return (604_800, 1_209_600)
            default:        return (1_209_600, 1_209_600)
            }
        }()
        guard next > prev else { return 1 }
        return min(1, (s - prev) / (next - prev))
    }

    func formattedElapsed(at date: Date) -> String {
        let total = Int(elapsed(at: date))
        let d = total / 86400
        let h = (total % 86400) / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if d >= 7 { return "\(d) days" }
        if d >= 1 { return "\(d)d \(h)h" }
        if h >= 1 { return "\(h)h \(m)m" }
        return String(format: "%d:%02d", m, s)
    }

    func nextMilestone(at date: Date) -> String {
        let h = elapsed(at: date) / 3600
        if h >= 336 { return "Living in freedom" }
        let remaining: TimeInterval = {
            switch h {
            case ..<1:      return 3_600    - elapsed(at: date)
            case 1..<24:    return 86_400   - elapsed(at: date)
            case 24..<72:   return 259_200  - elapsed(at: date)
            case 72..<168:  return 604_800  - elapsed(at: date)
            default:        return 1_209_600 - elapsed(at: date)
            }
        }()
        let rh = Int(remaining) / 3600
        let rm = (Int(remaining) % 3600) / 60
        if rh >= 24 { return "\(rh/24)d \(rh%24)h" }
        if rh > 0   { return "\(rh)h \(rm)m" }
        return "\(rm)m"
    }
}

// MARK: - Timeline Entry

struct FastingEntry: TimelineEntry {
    let date: Date
    let data: WidgetFastData
}

// MARK: - Timeline Provider

struct FastingProvider: TimelineProvider {
    func placeholder(in context: Context) -> FastingEntry {
        FastingEntry(date: Date(), data: WidgetFastData(lastSugarDate: Date().addingTimeInterval(-172800)))
    }

    func getSnapshot(in context: Context, completion: @escaping (FastingEntry) -> Void) {
        completion(FastingEntry(date: Date(), data: WidgetFastData.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FastingEntry>) -> Void) {
        let data = WidgetFastData.load()
        let now  = Date()

        // One entry per minute for the next hour, then reload
        let entries = (0..<60).map { i in
            FastingEntry(
                date: now.addingTimeInterval(Double(i) * 60),
                data: data
            )
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Colour helpers (no asset catalog in extension)

private extension Color {
    static let ncBackground  = Color(red: 0.980, green: 0.973, blue: 0.961)
    static let ncSurface     = Color(red: 0.949, green: 0.937, blue: 0.914)
    static let ncTextPrimary = Color(red: 0.110, green: 0.110, blue: 0.102)
    static let ncTextSecond  = Color(red: 0.541, green: 0.533, blue: 0.502)
    static let ncTextTert    = Color(red: 0.710, green: 0.698, blue: 0.675)
    static let ncSuccess     = Color(red: 0.290, green: 0.486, blue: 0.349)
    static let ncWarning     = Color(red: 0.757, green: 0.486, blue: 0.227)
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: FastingEntry

    var body: some View {
        if entry.data.lastSugarDate == nil {
            notStartedView
        } else {
            trackingView
        }
    }

    private var notStartedView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("nightcap")
                .font(.system(size: 9, weight: .light))
                .tracking(1.5)
                .foregroundStyle(Color.ncTextTert)
            Spacer()
            Text("Start your fast")
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(Color.ncTextPrimary)
                .lineLimit(2)
            Spacer(minLength: 4)
            Text("Open the app to begin")
                .font(.system(size: 10, weight: .light))
                .foregroundStyle(Color.ncTextTert)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(Color.ncBackground, for: .widget)
    }

    private var trackingView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("nightcap")
                .font(.system(size: 9, weight: .light))
                .tracking(1.5)
                .foregroundStyle(Color.ncTextTert)

            Spacer(minLength: 4)

            Text(entry.data.formattedElapsed(at: entry.date))
                .font(.system(size: 28, weight: .light).monospacedDigit())
                .foregroundStyle(Color.ncTextPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text("sugar free")
                .font(.system(size: 11, weight: .light))
                .foregroundStyle(Color.ncTextSecond)

            Spacer(minLength: 8)

            VStack(alignment: .leading, spacing: 5) {
                Text(entry.data.phase(at: entry.date).uppercased())
                    .font(.system(size: 8, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(Color.ncTextTert)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.ncTextTert.opacity(0.3)).frame(height: 3)
                        Capsule()
                            .fill(Color.ncSuccess)
                            .frame(width: geo.size.width * entry.data.phaseProgress(at: entry.date),
                                   height: 3)
                    }
                }
                .frame(height: 3)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(Color.ncBackground, for: .widget)
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: FastingEntry

    var body: some View {
        guard entry.data.lastSugarDate != nil else {
            return AnyView(
                HStack(spacing: 16) {
                    Image(systemName: "timer")
                        .font(.system(size: 28, weight: .thin))
                        .foregroundStyle(Color.ncTextTert)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("nightcap")
                            .font(.system(size: 11, weight: .light))
                            .tracking(2)
                            .foregroundStyle(Color.ncTextTert)
                        Text("Open the app to start\nyour sugar-free fast.")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(Color.ncTextPrimary)
                            .lineSpacing(3)
                    }
                    Spacer()
                }
                .padding(16)
                .containerBackground(Color.ncBackground, for: .widget)
            )
        }
        return AnyView(trackingView)
    }

    private var trackingView: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left — timer
            VStack(alignment: .leading, spacing: 0) {
                Text("nightcap")
                    .font(.system(size: 9, weight: .light))
                    .tracking(1.5)
                    .foregroundStyle(Color.ncTextTert)

                Spacer(minLength: 6)

                Text(entry.data.formattedElapsed(at: entry.date))
                    .font(.system(size: 38, weight: .light).monospacedDigit())
                    .foregroundStyle(Color.ncTextPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text("sugar free")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Color.ncTextSecond)

                Spacer(minLength: 10)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.ncTextTert.opacity(0.25)).frame(height: 4)
                        Capsule()
                            .fill(Color.ncSuccess)
                            .frame(
                                width: geo.size.width * entry.data.phaseProgress(at: entry.date),
                                height: 4
                            )
                    }
                }
                .frame(height: 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 20)

            // Right — phase + milestone
            VStack(alignment: .trailing, spacing: 6) {
                Text(entry.data.phase(at: entry.date).uppercased())
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Color.ncSuccess)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("NEXT")
                        .font(.system(size: 8, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(Color.ncTextTert)
                    Text(entry.data.nextMilestone(at: entry.date))
                        .font(.system(size: 13, weight: .light).monospacedDigit())
                        .foregroundStyle(Color.ncTextSecond)
                        .multilineTextAlignment(.trailing)
                }
            }
            .frame(width: 80)
        }
        .padding(16)
        .containerBackground(Color.ncBackground, for: .widget)
    }
}

// MARK: - Large Widget

struct LargeWidgetView: View {
    let entry: FastingEntry

    var body: some View {
        guard entry.data.lastSugarDate != nil else {
            return AnyView(
                VStack(spacing: 16) {
                    Image(systemName: "timer")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundStyle(Color.ncTextTert)
                    Text("nightcap")
                        .font(.system(size: 13, weight: .light))
                        .tracking(3)
                        .foregroundStyle(Color.ncTextTert)
                    Text("Open the app to start\nyour sugar-free fast.")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(Color.ncTextPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .containerBackground(Color.ncBackground, for: .widget)
            )
        }
        return AnyView(trackingView)
    }

    private var trackingView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("nightcap")
                    .font(.system(size: 10, weight: .light))
                    .tracking(2)
                    .foregroundStyle(Color.ncTextTert)
                Spacer()
                Text(entry.data.phase(at: entry.date).uppercased())
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Color.ncSuccess)
            }

            Spacer(minLength: 12)

            // Big timer
            Text(entry.data.formattedElapsed(at: entry.date))
                .font(.system(size: 56, weight: .light).monospacedDigit())
                .foregroundStyle(Color.ncTextPrimary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text("sugar free")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Color.ncTextSecond)

            Spacer(minLength: 16)

            // Phase progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.ncTextTert.opacity(0.25)).frame(height: 5)
                    Capsule()
                        .fill(Color.ncSuccess)
                        .frame(
                            width: geo.size.width * entry.data.phaseProgress(at: entry.date),
                            height: 5
                        )
                }
            }
            .frame(height: 5)

            Spacer(minLength: 20)

            // Divider
            Rectangle()
                .fill(Color.ncTextTert.opacity(0.2))
                .frame(height: 1)

            Spacer(minLength: 16)

            // Phase description
            Text(phaseBodyScience(for: entry.data.phase(at: entry.date)))
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Color.ncTextSecond)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 16)

            // Next milestone footer
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("NEXT MILESTONE")
                        .font(.system(size: 8, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(Color.ncTextTert)
                    Text(entry.data.nextMilestone(at: entry.date))
                        .font(.system(size: 14, weight: .light).monospacedDigit())
                        .foregroundStyle(Color.ncTextPrimary)
                }
                Spacer()
            }
        }
        .padding(18)
        .containerBackground(Color.ncBackground, for: .widget)
    }

    private func phaseBodyScience(for phase: String) -> String {
        switch phase {
        case "Starting Out":
            return "Your blood sugar is beginning to stabilize. The craving you feel is your brain expecting its usual dopamine hit — not your body needing fuel."
        case "First Day":
            return "Your liver is burning through glycogen reserves. Any fatigue you feel is the metabolic shift starting."
        case "Withdrawal":
            return "Headaches and irritability now are your brain recalibrating reward pathways. Serotonin is shifting back to your gut."
        case "Breakthrough":
            return "The compulsive edge of cravings drops sharply at 72 hours. Your taste receptors are beginning to reset."
        case "Rewiring":
            return "Your gut microbiome has measurably shifted. Bacteria that amplify cravings are dying off."
        default: // Freedom
            return "At two weeks, fMRI studies show reduced reward-center activation in response to sugar images. You have literally rewired."
        }
    }
}

// MARK: - Lock Screen Circular

struct CircularWidgetView: View {
    let entry: FastingEntry

    var body: some View {
        VStack(spacing: 1) {
            Image(systemName: "timer")
                .font(.system(size: 11, weight: .light))
            Text(compactElapsed)
                .font(.system(size: 13, weight: .medium).monospacedDigit())
                .minimumScaleFactor(0.7)
        }
        .containerBackground(for: .widget) { }
    }

    private var compactElapsed: String {
        let total = Int(entry.data.elapsed(at: entry.date))
        let d = total / 86400
        let h = (total % 86400) / 3600
        if d > 0 { return "\(d)d" }
        return "\(h)h"
    }
}

// MARK: - Lock Screen Rectangular

struct RectangularWidgetView: View {
    let entry: FastingEntry

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "timer")
                .font(.system(size: 14, weight: .light))

            VStack(alignment: .leading, spacing: 1) {
                Text(entry.data.formattedElapsed(at: entry.date))
                    .font(.system(size: 15, weight: .medium).monospacedDigit())
                    .foregroundStyle(.primary)
                Text(entry.data.phase(at: entry.date))
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(for: .widget) { }
    }
}

// MARK: - Adaptive entry view (reads widgetFamily from environment)

struct NightcapWidgetEntryView: View {
    let entry: FastingEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .accessoryCircular:
            CircularWidgetView(entry: entry)
        case .accessoryRectangular:
            RectangularWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget definition

struct NightcapWidget: Widget {
    let kind = "NightcapWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FastingProvider()) { entry in
            NightcapWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Fast Timer")
        .description("Track your sugar-free fast from your home screen.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
        ])
    }
}

// MARK: - Entry point

@main
struct NightcapWidgetBundle: WidgetBundle {
    var body: some Widget {
        NightcapWidget()
    }
}
