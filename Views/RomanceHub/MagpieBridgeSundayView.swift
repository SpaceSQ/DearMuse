import SwiftUI

struct MagpieBridgeSundayView: View {
    @Environment(AppModel.self) private var model
    @State private var nickname = ""
    @State private var gender = ""
    @State private var orientation = ""
    @State private var expectations = ""
    @State private var hobbies = ""

    var body: some View {
        NavigationStack {
            ZStack {
                SoulNightBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(L10n.magpieBridge.resolve())
                            .font(.system(size: 32, weight: .light, design: .serif))
                            .foregroundStyle(SoulPalette.night.moonlight)

                        Text("Sunday 24:00 · ~20% match rate · dual consent · 4-week cooldown after success")
                            .font(.callout)
                            .foregroundStyle(SoulPalette.night.secondary)
                            .glassCard()

                        eligibilityBanner
                        profileForm

                        Button {
                            saveProfile()
                            model.runMagpieDemo()
                        } label: {
                            Label("Simulate Sunday midnight roll", systemImage: "sparkle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SoulPrimaryButtonStyle())

                        if let preview = model.magpie.pendingPreview {
                            previewCard(preview)
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
            .navigationTitle("Magpie Bridge")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                let p = model.magpie.profile
                nickname = p.nickname
                gender = p.gender
                orientation = p.sexualOrientation
                expectations = p.partnerExpectations
                hobbies = p.personalHobbies.joined(separator: ", ")
            }
        }
    }

    private var eligibilityBanner: some View {
        let gate = model.magpie.canParticipateInMagpieThisSunday()
        return HStack {
            Image(systemName: gate.eligible ? "checkmark.seal" : "lock.fill")
            Text(gate.eligible
                 ? "Eligible for this Sunday's Magpie Bridge"
                 : "Cooldown active — \(gate.remainingWaitDays) days until week 5 unlock")
                .font(.subheadline)
        }
        .foregroundStyle(gate.eligible ? SoulPalette.night.aurora : SoulPalette.night.rose)
        .glassCard()
    }

    private var profileForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            field("Nickname", text: $nickname)
            field("Gender", text: $gender)
            field("Orientation", text: $orientation)
            field("Partner expectations", text: $expectations)
            field("Hobbies (comma separated)", text: $hobbies)
            Button("Save Magpie profile") { saveProfile() }
                .buttonStyle(SoulGhostButtonStyle())
        }
        .glassCard()
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(SoulPalette.night.secondary)
            TextField(title, text: text)
                .padding(12)
                .background(SoulPalette.night.mist.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(SoulPalette.night.moonlight)
        }
    }

    private func previewCard(_ card: MagpieAnonymousPreviewCard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Anonymous preview")
                    .font(.headline)
                    .foregroundStyle(SoulPalette.night.moonlight)
                Spacer()
                Button {
                    model.blockChannel(topic: S2RBTopic.magpieHandshake(sessionID: card.id), reason: "report")
                } label: {
                    Image(systemName: "exclamationmark.bubble")
                }
                .accessibilityLabel("Block & Report")
            }
            Text(card.maskedNickname)
                .font(.title3.weight(.medium))
                .foregroundStyle(SoulPalette.night.aurora)
            Text(card.sharedHobbiesSummary)
                .foregroundStyle(SoulPalette.night.secondary)
            Text(card.museResonanceNote)
                .font(.callout)
                .foregroundStyle(SoulPalette.night.moonlight.opacity(0.9))
            HStack {
                Button("Agree") { model.decideMagpie(.agreed) }
                    .buttonStyle(SoulPrimaryButtonStyle())
                Button("Reject") { model.decideMagpie(.rejected) }
                    .buttonStyle(SoulGhostButtonStyle())
            }
        }
        .glassCard()
    }

    private func saveProfile() {
        let profile = MagpieParticipantProfile(
            nickname: nickname,
            gender: gender,
            sexualOrientation: orientation,
            partnerExpectations: expectations,
            personalHobbies: hobbies.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        )
        model.saveMagpieProfile(profile)
    }
}
