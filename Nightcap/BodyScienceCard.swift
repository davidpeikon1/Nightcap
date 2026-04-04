import SwiftUI
import UIKit

struct BodyScienceCard: View {
    @EnvironmentObject var store: FastingStore
    @State private var isExpanded = false
    @State private var showPhaseDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row — three separate hit targets to avoid nested-button ambiguity
            HStack(spacing: 0) {
                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    withAnimation(.spring(duration: 0.3)) { isExpanded.toggle() }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "flask")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Color("NCSuccess"))

                        Text("YOUR BODY NOW")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(2)
                            .foregroundStyle(Color("NCTextSecondary"))

                        Spacer()
                    }
                }
                .buttonStyle(.plain)

                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    showPhaseDetail = true
                } label: {
                    HStack(spacing: 4) {
                        Text(store.fastingPhase.rawValue.uppercased())
                            .font(.system(size: 10, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(Color("NCSuccess"))
                        Image(systemName: "info.circle")
                            .font(.system(size: 10, weight: .light))
                            .foregroundStyle(Color("NCSuccess").opacity(0.7))
                    }
                }
                .buttonStyle(.plain)

                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    withAnimation(.spring(duration: 0.3)) { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .light))
                        .foregroundStyle(Color("NCTextTertiary"))
                        .padding(.leading, 12)
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    Rectangle()
                        .fill(Color("NCTextTertiary").opacity(0.4))
                        .frame(height: 1)
                        .padding(.top, 14)

                    Text(store.fastingPhase.bodyScience)
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(Color("NCTextPrimary"))
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)

                    // Phase journey mini-strip
                    phaseStrip

                    // Approaching-next-phase callout — Zeigarnik: the open loop
                    // of an almost-reached milestone keeps it salient.
                    if let callout = nextPhaseCallout {
                        Text(callout)
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(Color("NCSuccess").opacity(0.8))
                            .padding(.top, 4)
                            .transition(.opacity)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .background(Color("NCSurface"))
        .cornerRadius(16)
        .animation(.spring(duration: 0.3), value: isExpanded)
        .onChange(of: store.fastingPhase) { _, newPhase in
            // Auto-expand when a new phase unlocks so users immediately see
            // what's happening biologically. Skip .justStarted (reset state).
            if newPhase != .justStarted {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(duration: 0.35)) { isExpanded = true }
            }
        }
        .sheet(isPresented: $showPhaseDetail) {
            PhaseDetailSheet(phase: store.fastingPhase)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    /// Returns a short callout when the next phase is within 4 hours.
    /// Nil in Freedom phase (no next phase) and when more than 4 h away.
    private var nextPhaseCallout: String? {
        let phase = store.fastingPhase
        guard phase != .freedom else { return nil }
        let remaining = phase.nextThreshold - store.elapsedSeconds
        guard remaining > 0, remaining <= 14_400 else { return nil }
        let phases = FastingPhase.allCases
        guard let idx = phases.firstIndex(of: phase), idx + 1 < phases.count else { return nil }
        let next = phases[idx + 1]
        let h = Int(remaining) / 3600
        let m = max(1, (Int(remaining) % 3600) / 60)
        let label = h > 0 ? "\(h)h \(m)m" : "\(m)m"
        return "\(label) to \(next.rawValue)."
    }

    private var phaseStrip: some View {
        let completedPhases = FastingPhase.allCases
            .filter { $0.previousThreshold < store.fastingPhase.previousThreshold }
            .map(\.rawValue)
        let a11yLabel: String = {
            if completedPhases.isEmpty {
                return "Phase journey: currently in \(store.fastingPhase.rawValue)."
            }
            return "Phase journey: \(completedPhases.joined(separator: ", ")) completed. Currently in \(store.fastingPhase.rawValue)."
        }()

        return HStack(spacing: 0) {
            ForEach(FastingPhase.allCases, id: \.self) { phase in
                let isActive = (phase == store.fastingPhase)
                let isPast   = phase.previousThreshold < store.fastingPhase.previousThreshold

                VStack(spacing: 5) {
                    Rectangle()
                        .fill(
                            isPast  ? Color("NCSuccess").opacity(0.7) :
                            isActive ? Color("NCSuccess") :
                            Color("NCTextTertiary").opacity(0.25)
                        )
                        .frame(height: isActive ? 4 : 2)
                        .cornerRadius(2)
                        .animation(.easeInOut, value: store.fastingPhase)

                    if isActive {
                        Text(phase.rawValue)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color("NCSuccess"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(a11yLabel)
    }
}

#Preview {
    BodyScienceCard()
        .environmentObject(FastingStore())
        .padding()
        .background(Color("NCBackground"))
}
