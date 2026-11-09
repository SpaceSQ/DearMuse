import SwiftUI

/// Immersive midnight ocean palette — poetic, not purple-neon.
struct SoulPalette {
    let abyss: Color
    let deep: Color
    let mist: Color
    let moonlight: Color
    let secondary: Color
    let aurora: Color
    let rose: Color
    let glass: Color

    static let night = SoulPalette(
        abyss: Color(red: 0.03, green: 0.04, blue: 0.09),
        deep: Color(red: 0.06, green: 0.10, blue: 0.18),
        mist: Color(red: 0.12, green: 0.18, blue: 0.28),
        moonlight: Color(red: 0.85, green: 0.90, blue: 0.95),
        secondary: Color(red: 0.62, green: 0.70, blue: 0.78),
        aurora: Color(red: 0.55, green: 0.78, blue: 0.78),
        rose: Color(red: 0.78, green: 0.62, blue: 0.55),
        glass: Color.white.opacity(0.08)
    )
}

struct SoulNightBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    SoulPalette.night.abyss,
                    SoulPalette.night.deep,
                    Color(red: 0.08, green: 0.07, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            SoulStarField()
                .opacity(0.55)
            RadialGradient(
                colors: [SoulPalette.night.aurora.opacity(0.12), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }
}

struct SoulStarField: View {
    private let stars: [(CGFloat, CGFloat, CGFloat)] = {
        var rng = SeededGenerator(seed: 42)
        return (0..<48).map { _ in
            (CGFloat.random(in: 0...1, using: &rng),
             CGFloat.random(in: 0...1, using: &rng),
             CGFloat.random(in: 0.6...2.2, using: &rng))
        }
    }()

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                for star in stars {
                    let rect = CGRect(
                        x: star.0 * size.width,
                        y: star.1 * size.height,
                        width: star.2,
                        height: star.2
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.55)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(.ultraThinMaterial.opacity(0.55), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(SoulPalette.night.moonlight.opacity(0.12), lineWidth: 1)
            )
    }
}

extension View {
    func glassCard() -> some View { modifier(GlassCardModifier()) }
}
