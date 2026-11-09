import SwiftUI

struct CoupledMirrorTimelineView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            ZStack {
                SoulNightBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Mirror Memories")
                            .font(.system(size: 32, weight: .light, design: .serif))
                            .foregroundStyle(SoulPalette.night.moonlight)

                        Text("7-day heat window · 30-day rolling pool · 00:00 coupled fusion when a local lover exists")
                            .font(.callout)
                            .foregroundStyle(SoulPalette.night.secondary)
                            .glassCard()

                        bridgeStatusCard

                        Button {
                            Task { await model.runMidnightPass() }
                        } label: {
                            Label("Run 00:00 distillation pass", systemImage: "moon.zzz")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SoulPrimaryButtonStyle())

                        if model.memory.coupledMirrorMemories.isEmpty {
                            Text("No coupled mirrors yet. Agree on Magpie Bridge, then wait for midnight.")
                                .font(.footnote)
                                .foregroundStyle(SoulPalette.night.secondary)
                                .glassCard()
                        } else {
                            ForEach(model.memory.coupledMirrorMemories) { record in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(record.dateKey)
                                        .font(.caption)
                                        .foregroundStyle(SoulPalette.night.aurora)
                                    Text(record.fusedResonanceInsight300)
                                        .foregroundStyle(SoulPalette.night.moonlight)
                                    Text("Partner mirror: \(record.partnerMirrorSummary300)")
                                        .font(.caption)
                                        .foregroundStyle(SoulPalette.night.secondary)
                                }
                                .glassCard()
                            }
                        }

                        if let status = model.lastStatus {
                            Text(status)
                                .font(.footnote)
                                .foregroundStyle(SoulPalette.night.aurora)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Memory")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var bridgeStatusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rainbow Bridge MQTT")
                .font(.headline)
                .foregroundStyle(SoulPalette.night.moonlight)
            Text(bridgeStateLabel)
                .font(.footnote)
                .foregroundStyle(SoulPalette.night.aurora)
            HStack {
                Button("Connect") { model.connectRainbowBridge() }
                    .buttonStyle(SoulPrimaryButtonStyle())
                Button("Disconnect") { model.disconnectRainbowBridge() }
                    .buttonStyle(SoulGhostButtonStyle())
            }
            Text("Lab WSS: broker.emqx.io · retain=false · relation truth stays local")
                .font(.caption2)
                .foregroundStyle(SoulPalette.night.secondary)
        }
        .glassCard()
    }

    private var bridgeStateLabel: String {
        switch model.bridge.state {
        case .idle: return "Idle · not connected"
        case .connecting: return "Connecting…"
        case .connected: return "Connected · pub \(model.bridge.publishedCount) · rx \(model.bridge.receivedCount)"
        case .failed(let msg): return "Failed · \(msg)"
        }
    }
}
