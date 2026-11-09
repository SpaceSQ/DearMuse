import SwiftUI

struct DearMuseLaunchPreludeView: View {
    var onFinished: () -> Void
    @State private var appear = false
    @State private var breathe = false

    var body: some View {
        ZStack {
            SoulNightBackground()
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(SoulPalette.night.aurora.opacity(0.18))
                        .frame(width: breathe ? 128 : 96, height: breathe ? 128 : 96)
                        .blur(radius: 18)
                    Image(systemName: "water.waves")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(SoulPalette.night.moonlight)
                        .scaleEffect(appear ? 1 : 0.7)
                        .opacity(appear ? 1 : 0)
                }
                Text("Dear Muse")
                    .font(.system(size: 36, weight: .light, design: .serif))
                    .foregroundStyle(SoulPalette.night.moonlight)
                    .opacity(appear ? 1 : 0)
                Text("Soul Drift")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(SoulPalette.night.aurora)
                    .opacity(appear ? 1 : 0)
                Text("零回信 · 周日鹊桥 · 心动秘密")
                    .font(.footnote)
                    .foregroundStyle(SoulPalette.night.secondary)
                    .opacity(appear ? 0.9 : 0)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.1)) { appear = true }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                breathe = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                onFinished()
            }
        }
    }
}
