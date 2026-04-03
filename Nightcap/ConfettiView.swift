import SwiftUI

// MARK: - Particle model

struct ConfettiParticle: Identifiable {
    let id = UUID()
    // Layout (0...1 normalized to screen width)
    let startX: CGFloat
    let driftX: CGFloat
    // Timing
    let delay: Double
    let duration: Double
    // Appearance
    let width: CGFloat
    let height: CGFloat
    let endRotation: Double
    let colorIndex: Int

    static func make(count: Int = 80) -> [ConfettiParticle] {
        (0..<count).map { i in
            ConfettiParticle(
                startX:      CGFloat.random(in: 0.05...0.95),
                driftX:      CGFloat.random(in: -0.22...0.22),
                delay:       Double.random(in: 0...0.65),
                duration:    Double.random(in: 1.1...2.3),
                width:       CGFloat.random(in: 7...14),
                height:      CGFloat.random(in: 4...9),
                endRotation: Double.random(in: 120...480),
                colorIndex:  i % 6
            )
        }
    }
}

// MARK: - Single piece

struct ConfettiPiece: View {
    let particle: ConfettiParticle
    let active: Bool
    let bounds: CGSize

    private static let palette: [Color] = [
        Color("NCWarning"),
        Color("NCSuccess"),
        Color("NCAccent").opacity(0.8),
        .orange,
        Color(red: 0.9, green: 0.45, blue: 0.45),
        Color(red: 0.45, green: 0.65, blue: 0.90),
    ]

    private var color: Color { Self.palette[particle.colorIndex] }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: particle.width, height: particle.height)
            .rotationEffect(.degrees(active ? particle.endRotation : 0))
            .position(
                x: (particle.startX + (active ? particle.driftX : 0)) * bounds.width,
                y: active ? bounds.height + 30 : -20
            )
            .opacity(active ? 0 : 1)
            .animation(
                .easeIn(duration: particle.duration).delay(particle.delay),
                value: active
            )
    }
}

// MARK: - Container view

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var active = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    ConfettiPiece(particle: p, active: active, bounds: geo.size)
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            particles = ConfettiParticle.make()
            // Tiny delay so the initial off-screen position renders before animation starts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                active = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color("NCBackground").ignoresSafeArea()
        ConfettiView()
    }
}
