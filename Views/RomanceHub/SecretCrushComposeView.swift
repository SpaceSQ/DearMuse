import SwiftUI

struct SecretCrushComposeView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            ZStack {
                SoulNightBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(L10n.secretCrush.resolve())
                            .font(.system(size: 32, weight: .light, design: .serif))
                            .foregroundStyle(SoulPalette.night.moonlight)

                        Text("Address a 22-char S2-DID (with checksum) or a six-segment code like CN.GD.GZ.TH.CB.311. The envelope strips your return address before Rainbow Bridge delivery.")
                            .font(.callout)
                            .foregroundStyle(SoulPalette.night.secondary)
                            .glassCard()

                        VStack(alignment: .leading, spacing: 12) {
                            TextField("S2-DID or six-segment address", text: $model.crushAddress)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .padding(14)
                                .background(SoulPalette.night.mist.opacity(0.45), in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(SoulPalette.night.moonlight)

                            TextEditor(text: $model.crushDraft)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 120)
                                .padding(12)
                                .background(SoulPalette.night.mist.opacity(0.45), in: RoundedRectangle(cornerRadius: 16))
                                .foregroundStyle(SoulPalette.night.moonlight)

                            Button {
                                Task { await model.sendCrush() }
                            } label: {
                                Label("Send anonymous crush note", systemImage: "envelope.open")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SoulPrimaryButtonStyle())
                        }
                        .glassCard()

                        identityCard

                        if let status = model.lastStatus {
                            Text(status)
                                .font(.footnote)
                                .foregroundStyle(SoulPalette.night.aurora)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Secret Crushes")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your local S2-DID")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SoulPalette.night.moonlight)
            Text(model.myS2DID)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(SoulPalette.night.aurora)
                .textSelection(.enabled)
            Text("Kept in the on-device sandbox. Cloud never stores your lover graph.")
                .font(.caption)
                .foregroundStyle(SoulPalette.night.secondary)
        }
        .glassCard()
    }
}
