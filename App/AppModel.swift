import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class AppModel {
    let myS2DID: String
    let router: S2RBMQTTRouter
    let bottleEngine: SecretCrushAndBottleEngine
    let magpie: MagpieBridgeMatcher
    let memory: MuseMirrorMemoryEngine
    let storeKit = StoreKitManager()
    let bridge: RainbowBridgeMQTTClient

    var showLaunch = true
    var selectedTab: RootTab = .drift
    var chatDraft = ""
    var chatLines: [ChatLine] = []
    var bottleDraft = ""
    var crushDraft = ""
    var crushAddress = ""
    var lastStatus: String?
    var pickedNote: AnonymousRomanticNote?
    var soulFlowPhase: Double = 0
    var blockedChannels: [BlockReportAction] = []

    init() {
        let did = LocalSandboxStore.shared.loadOrCreateIdentity()
        myS2DID = did
        router = S2RBMQTTRouter(myS2DID: did)
        for (key, value) in LocalSandboxStore.shared.loadRelations() {
            router.annotateRelationLocally(targetDID: key, relation: value)
        }
        bottleEngine = SecretCrushAndBottleEngine(router: router)
        magpie = MagpieBridgeMatcher(
            router: router,
            profile: LocalSandboxStore.shared.loadMagpieProfile()
        )
        memory = MuseMirrorMemoryEngine(myS2DID: did, router: router)
        bridge = RainbowBridgeMQTTClient(myS2DID: did, router: router)
        AppGroupSharedContainer.ensureDirectories()
        seedWelcome()
        bridge.onEnvelope { [weak self] envelope in
            self?.handleIncomingBridgeEnvelope(envelope)
        }
    }

    func connectRainbowBridge() {
        bridge.connect()
        lastStatus = "Connecting Rainbow Bridge MQTT…"
    }

    func disconnectRainbowBridge() {
        bridge.disconnect()
        lastStatus = "Rainbow Bridge disconnected."
    }

    private func publishLatestOutbound() {
        bridge.flushOutboundQueue()
    }

    private func handleIncomingBridgeEnvelope(_ envelope: S2RBMQTTEnvelope) {
        if blockedChannels.contains(where: { envelope.recipientDID.contains($0.channelTopic) || $0.channelTopic.contains(envelope.id.uuidString) }) {
            return
        }
        switch envelope.packetType {
        case .driftBottle, .secretCrushNote:
            if let note = try? JSONDecoder().decode(AnonymousRomanticNote.self, from: envelope.encryptedPayload) {
                let safe = OnDeviceSafetyFilter.shared.sanitize(note.content)
                let filtered = AnonymousRomanticNote(
                    id: note.id,
                    content: safe,
                    moodWeatherSnapshot: note.moodWeatherSnapshot,
                    writtenDateKey: note.writtenDateKey
                )
                bottleEngine.receiveAnonymousNote(filtered, as: envelope.packetType)
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                    pickedNote = filtered
                }
                lastStatus = envelope.packetType == .driftBottle
                    ? "A bottle washed ashore via Rainbow Bridge."
                    : "An anonymous crush note arrived. No return address."
            }
        case .midnightMuseMirror:
            Task { @MainActor in
                let summary = memory.distillMidnightSummary()
                let insight = MuseMirrorMemoryEngine.ruleBasedFusion(
                    mySummary: summary,
                    partnerSummary: String(data: envelope.encryptedPayload, encoding: .utf8) ?? ""
                )
                _ = try? await memory.fuseAndSaveMidnightMirrorMemory(
                    myDialogueSummary300: summary,
                    myContextSummary300: "bridge night",
                    incomingEnvelope: envelope,
                    localLLMInvoke: { @Sendable _ in insight }
                )
                lastStatus = "00:00 lover mirror fused locally."
            }
        default:
            lastStatus = "Bridge packet \(envelope.packetType.rawValue) received."
        }
    }

    private func seedWelcome() {
        chatLines = [
            ChatLine(
                role: .muse,
                text: "I am your Muse. Cast one bottle a day into the year ahead — no return address. On Sundays at midnight, Magpie Bridge may open for ~20% of souls."
            )
        ]
    }

    func persistRelations() {
        LocalSandboxStore.shared.saveRelations(router.snapshotRelations())
    }

    func castBottle() async {
        let safe = OnDeviceSafetyFilter.shared.sanitize(bottleDraft)
        do {
            let envelope = try await bottleEngine.castDailyDriftBottle(
                thoughtForFutureLover: safe,
                weatherSnapshot: "night mist"
            )
            let days = Int(((envelope.deliverAfterTimestamp ?? 0) - envelope.createdAtTimestamp) / 86_400)
            publishLatestOutbound()
            lastStatus = "Bottle cast into the ocean. It may surface in ~\(days) days. No return address."
            bottleDraft = ""
            withAnimation(.easeInOut(duration: 1.6)) { soulFlowPhase += 1 }
        } catch {
            lastStatus = error.localizedDescription
        }
    }

    func pickDemoBottle() {
        let samples = [
            "If you ever find this, know someone once waited quietly for a kindness like yours.",
            "I folded a year of almosts into this glass. Keep it — or let the tide decide.",
            "No name. Only the wish that you are warmer tonight than I am."
        ]
        let note = AnonymousRomanticNote(
            id: UUID(),
            content: samples.randomElement()!,
            moodWeatherSnapshot: "salt air",
            writtenDateKey: CalendarKeys.daysAgoKey(Int.random(in: 1...200))
        )
        bottleEngine.receiveAnonymousNote(note, as: .driftBottle)
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
            pickedNote = note
        }
    }

    func sendCrush() async {
        let raw = crushAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let address: MuseTargetAddress = raw.contains(".")
            ? .sixSegmentAddress(raw)
            : .s2DID(raw.uppercased())
        let safe = OnDeviceSafetyFilter.shared.sanitize(crushDraft)
        do {
            _ = try await bottleEngine.sendSecretCrushNote(
                targetAddress: address,
                crushConfession: safe,
                weatherSnapshot: "quiet pulse"
            )
            publishLatestOutbound()
            lastStatus = "Crush note delivered with no return address. They will never know it was you — unless they write you too."
            crushDraft = ""
        } catch {
            lastStatus = error.localizedDescription
        }
    }

    func saveMagpieProfile(_ profile: MagpieParticipantProfile) {
        magpie.updateProfile(profile)
        LocalSandboxStore.shared.saveMagpieProfile(profile)
    }

    func runMagpieDemo(forceMatch: Bool = false) {
        let card = magpie.runLocalSundayMatchRoll(
            randomRoll: forceMatch ? 0.05 : Double.random(in: 0...1)
        )
        if card == nil {
            lastStatus = "No Magpie preview this Sunday (~20% gate). Keep tending your Muse — destiny is patient."
        } else {
            lastStatus = "A Magpie preview arrived. No detailed identity — only a choice."
        }
    }

    func decideMagpie(_ decision: MagpieDecision) {
        magpie.recordMyDecision(decision)
        guard let preview = magpie.pendingPreview else { return }
        if decision == .rejected {
            _ = magpie.finalizeMagpieHandshake(
                sessionID: preview.id,
                myDecision: .rejected,
                partnerDecision: .pending,
                revealedPartnerS2DID: nil
            )
            lastStatus = "You declined. The ephemeral handshake dissolved."
            persistRelations()
            return
        }
        // Demo: partner mirrors agreement and reveals a minted DID.
        let partner = MuseTargetAddress.mintLocalS2DID(seed: preview.id)
        let ok = magpie.finalizeMagpieHandshake(
            sessionID: preview.id,
            myDecision: .agreed,
            partnerDecision: .agreed,
            revealedPartnerS2DID: partner
        )
        lastStatus = ok
            ? "Both agreed. Lover relation annotated locally. Magpie locked for 4 weeks."
            : "Handshake failed."
        persistRelations()
    }

    func sendChat() {
        let text = chatDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        chatLines.append(ChatLine(role: .user, text: text))
        memory.appendRawLog(excerpt: text)
        chatDraft = ""
        let reply = museReply(to: text)
        chatLines.append(ChatLine(role: .muse, text: reply))
    }

    private func museReply(to text: String) -> String {
        if text.lowercased().contains("bottle") || text.contains("漂流") {
            return "One bottle a day is enough. Scarcity keeps the longing honest."
        }
        if text.lowercased().contains("magpie") || text.contains("鹊桥") {
            return "Sunday midnight opens Magpie Bridge for about one in five. After a match, four quiet weeks."
        }
        return "I heard you. I'll keep this in the seven-day warmth and fold it into midnight's letter."
    }

    func blockChannel(topic: String, reason: String) {
        blockedChannels.append(BlockReportAction(channelTopic: topic, reason: reason, createdAt: Date()))
        lastStatus = "Channel blocked locally. Future packets on this topic will be ignored."
    }

    func runMidnightPass() async {
        let summary = memory.distillMidnightSummary()
        let lovers = router.snapshotRelations().filter { $0.value == .lover }.map(\.key)
        for partner in lovers {
            _ = try? memory.buildMidnightOutboundMirrorEnvelope(
                partnerS2DID: partner,
                myDailyDialogueSummary300: summary,
                myDailyContextSummary300: "local weather · quiet room",
                emotionalTone: "tender",
                dateKey: CalendarKeys.todayKey()
            )
        }
        publishLatestOutbound()
        lastStatus = "00:00 pass: daily summary distilled; lover mirrors enqueued if any."
    }
}

struct ChatLine: Identifiable, Equatable {
    enum Role { case user, muse }
    let id = UUID()
    let role: Role
    let text: String
}

enum RootTab: String, CaseIterable, Identifiable {
    case muse, drift, crush, magpie, memory
    var id: String { rawValue }

    var title: String {
        switch self {
        case .muse: return "Muse"
        case .drift: return "Drift"
        case .crush: return "Crush"
        case .magpie: return "Magpie"
        case .memory: return "Memory"
        }
    }

    var symbol: String {
        switch self {
        case .muse: return "sparkles"
        case .drift: return "water.waves"
        case .crush: return "heart.text.square"
        case .magpie: return "link.circle"
        case .memory: return "moon.stars"
        }
    }
}
