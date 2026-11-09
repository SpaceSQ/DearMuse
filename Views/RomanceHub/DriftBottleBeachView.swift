import SwiftUI

struct DriftBottleBeachView: View {
    @Environment(AppModel.self) private var model
    @State private var casting = false

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            ZStack {
                SoulNightBackground()
                SoulFlowView(phase: model.soulFlowPhase)
                    .opacity(0.9)

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        DriftBottleGlyph()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)

                        Text(L10n.zeroReturn.resolve())
                            .font(.callout)
                            .foregroundStyle(SoulPalette.night.secondary)
                            .glassCard()

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Thought for a future lover")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SoulPalette.night.moonlight)
                            TextEditor(text: $model.bottleDraft)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 110)
                                .padding(12)
                                .background(SoulPalette.night.mist.opacity(0.45), in: RoundedRectangle(cornerRadius: 16))
                                .foregroundStyle(SoulPalette.night.moonlight)

                            HStack {
                                Button {
                                    Task {
                                        casting = true
                                        await model.castBottle()
                                        casting = false
                                    }
                                } label: {
                                    Label(
                                        model.bottleEngine.hasCastToday ? "Already cast today" : L10n.castBottle.resolve(),
                                        systemImage: "paperplane"
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(SoulPrimaryButtonStyle())
                                .disabled(model.bottleEngine.hasCastToday || casting)

                                Button {
                                    model.pickDemoBottle()
                                } label: {
                                    Label(L10n.pickBottle.resolve(), systemImage: "hand.raised")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(SoulGhostButtonStyle())
                            }
                        }
                        .glassCard()

                        if let status = model.lastStatus {
                            Text(status)
                                .font(.footnote)
                                .foregroundStyle(SoulPalette.night.aurora)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        if let note = model.pickedNote {
                            pickedCard(note)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Soul Drift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Dear Muse")
                .font(.system(size: 34, weight: .light, design: .serif))
                .foregroundStyle(SoulPalette.night.moonlight)
            Text("One bottle a day · 1–365 day time capsule · zero return address")
                .font(.footnote)
                .foregroundStyle(SoulPalette.night.secondary)
        }
    }

    private func pickedCard(_ note: AnonymousRomanticNote) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Picked from the tide")
                    .font(.headline)
                    .foregroundStyle(SoulPalette.night.moonlight)
                Spacer()
                Button {
                    model.blockChannel(topic: "ocean/\(note.id.uuidString)", reason: "user_report")
                } label: {
                    Image(systemName: "hand.raised.slash")
                        .foregroundStyle(SoulPalette.night.rose)
                }
                .accessibilityLabel("Block & Report")
            }
            Text(note.content)
                .font(.body)
                .foregroundStyle(SoulPalette.night.secondary)
            Text("Weather imprint · \(note.moodWeatherSnapshot) · \(note.writtenDateKey)")
                .font(.caption)
                .foregroundStyle(SoulPalette.night.aurora.opacity(0.8))
            Text("You cannot reply. There is no sender.")
                .font(.caption2)
                .foregroundStyle(SoulPalette.night.rose.opacity(0.9))
        }
        .glassCard()
    }
}

struct SoulPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.vertical, 12)
            .foregroundStyle(SoulPalette.night.abyss)
            .background(
                LinearGradient(
                    colors: [SoulPalette.night.aurora, SoulPalette.night.moonlight],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: Capsule()
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct SoulGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.vertical, 12)
            .foregroundStyle(SoulPalette.night.moonlight)
            .background(Capsule().strokeBorder(SoulPalette.night.moonlight.opacity(0.25)))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
