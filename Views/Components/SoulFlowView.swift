import SwiftUI

/// Ambient soul-current visualization for cast / pick moments.
struct SoulFlowView: View {
    var phase: Double
    var intensity: Double = 1

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate + phase
            Canvas { context, size in
                let waves = 5
                for i in 0..<waves {
                    var path = Path()
                    let yBase = size.height * (0.25 + CGFloat(i) * 0.12)
                    let amp = 10 + CGFloat(i) * 3 * intensity
                    path.move(to: CGPoint(x: 0, y: yBase))
                    for x in stride(from: 0, through: size.width, by: 6) {
                        let y = yBase + sin((x / 40) + t * (0.8 + Double(i) * 0.15)) * amp
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    context.stroke(
                        path,
                        with: .color(SoulPalette.night.aurora.opacity(0.18 + Double(i) * 0.05)),
                        lineWidth: 1.2
                    )
                }

                // Floating bottle mote
                let bx = size.width * (0.2 + 0.6 * (0.5 + 0.5 * sin(t * 0.35)))
                let by = size.height * (0.55 + 0.08 * cos(t * 0.5))
                let bottle = Path(ellipseIn: CGRect(x: bx - 7, y: by - 14, width: 14, height: 28))
                context.fill(bottle, with: .color(SoulPalette.night.moonlight.opacity(0.35)))
                context.stroke(bottle, with: .color(SoulPalette.night.rose.opacity(0.55)), lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
    }
}

struct DriftBottleGlyph: View {
    var floating = true
    @State private var lift = false

    var body: some View {
        Image(systemName: "wineglass")
            .font(.system(size: 42, weight: .ultraLight))
            .foregroundStyle(
                LinearGradient(
                    colors: [SoulPalette.night.moonlight, SoulPalette.night.aurora],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .offset(y: floating && lift ? -10 : 0)
            .rotationEffect(.degrees(floating && lift ? -6 : 6))
            .shadow(color: SoulPalette.night.aurora.opacity(0.35), radius: 16)
            .onAppear {
                guard floating else { return }
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                    lift = true
                }
            }
    }
}
