import Foundation

public struct DailyMuseDialogueMirrorPacket: Codable, Sendable {
    public let senderS2DID: String
    public let dateKey: String
    public let mirroredDialogueSummary300: String
    public let mirroredContextSummary300: String
    public let emotionalToneTag: String
}

public struct CoupledMirrorMemoryRecord: Codable, Identifiable, Sendable {
    public var id: String { "\(dateKey)_\(partnerS2DID)" }
    public let dateKey: String
    public let partnerS2DID: String
    public let mySummary300: String
    public let partnerMirrorSummary300: String
    public let fusedResonanceInsight300: String
    public let dailyOnePercentEvolution: [String: Double]
}

public struct RollingMemoryEntry: Codable, Identifiable, Sendable {
    public let id: UUID
    public let dateKey: String
    public let rawExcerpt: String
    public let distilledSummary: String?
}

/// Hippocampus V3 + midnight lover mirror fusion (100% on-device).
public final class MuseMirrorMemoryEngine: @unchecked Sendable {
    private let myS2DID: String
    private let router: S2RBMQTTRouter

    public private(set) var rolling30dRawLogs: [RollingMemoryEntry] = []
    public private(set) var dailyDistilledSummaries: [String: String] = [:]
    public private(set) var coupledMirrorMemories: [CoupledMirrorMemoryRecord] = []

    public init(myS2DID: String, router: S2RBMQTTRouter) {
        self.myS2DID = myS2DID
        self.router = router
    }

    public func appendRawLog(excerpt: String, dateKey: String = CalendarKeys.todayKey()) {
        let entry = RollingMemoryEntry(
            id: UUID(),
            dateKey: dateKey,
            rawExcerpt: String(excerpt.prefix(2000)),
            distilledSummary: nil
        )
        rolling30dRawLogs.append(entry)
        pruneRollingWindow()
    }

    public func distillMidnightSummary(dateKey: String = CalendarKeys.todayKey()) -> String {
        let todays = rolling30dRawLogs.filter { $0.dateKey == dateKey }.map(\.rawExcerpt)
        let summary = String(todays.joined(separator: " ").prefix(300))
        dailyDistilledSummaries[dateKey] = summary
        return summary
    }

    public func buildMidnightOutboundMirrorEnvelope(
        partnerS2DID: String,
        myDailyDialogueSummary300: String,
        myDailyContextSummary300: String,
        emotionalTone: String,
        dateKey: String
    ) throws -> S2RBMQTTEnvelope? {
        guard router.queryLocalRelation(for: partnerS2DID) == .lover else {
            return nil
        }

        let mirrorPacket = DailyMuseDialogueMirrorPacket(
            senderS2DID: myS2DID,
            dateKey: dateKey,
            mirroredDialogueSummary300: String(myDailyDialogueSummary300.prefix(300)),
            mirroredContextSummary300: String(myDailyContextSummary300.prefix(300)),
            emotionalToneTag: emotionalTone
        )
        let payload = try JSONEncoder().encode(mirrorPacket)

        let envelope = S2RBMQTTEnvelope(
            packetType: .midnightMuseMirror,
            recipientDID: partnerS2DID,
            senderDID: myS2DID,
            createdAtTimestamp: Date().timeIntervalSince1970,
            deliverAfterTimestamp: nil,
            encryptedPayload: payload
        )
        router.enqueueOutbound(envelope)
        return envelope
    }

    public func fuseAndSaveMidnightMirrorMemory(
        myDialogueSummary300: String,
        myContextSummary300: String,
        incomingEnvelope: S2RBMQTTEnvelope,
        localLLMInvoke: @escaping @Sendable (_ prompt: String) async throws -> String
    ) async throws -> CoupledMirrorMemoryRecord {
        guard router.shouldAcceptIncomingMQTTEnvelope(incomingEnvelope) else {
            throw NSError(
                domain: "MuseMirrorEngine",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: "Local lover relation check failed; mirror rejected"]
            )
        }

        let partnerMirror = try JSONDecoder().decode(
            DailyMuseDialogueMirrorPacket.self,
            from: incomingEnvelope.encryptedPayload
        )

        let fusionPrompt = """
        You are Dear Muse. Fuse tonight's dual mirrors into ≤300 words of resonance insight and a gentle tomorrow cue.
        Mine: \(myDialogueSummary300) | \(myContextSummary300)
        Partner mirror: \(partnerMirror.mirroredDialogueSummary300) | \(partnerMirror.mirroredContextSummary300) (\(partnerMirror.emotionalToneTag))
        """

        let fusedInsight = try await localLLMInvoke(fusionPrompt)

        let coupledRecord = CoupledMirrorMemoryRecord(
            dateKey: partnerMirror.dateKey,
            partnerS2DID: partnerMirror.senderS2DID,
            mySummary300: String(myDialogueSummary300.prefix(300)),
            partnerMirrorSummary300: partnerMirror.mirroredDialogueSummary300,
            fusedResonanceInsight300: String(fusedInsight.prefix(300)),
            dailyOnePercentEvolution: ["empathy_resonance": 0.01, "romantic_insight": 0.01]
        )

        coupledMirrorMemories.insert(coupledRecord, at: 0)
        return coupledRecord
    }

    public static func ruleBasedFusion(
        mySummary: String,
        partnerSummary: String
    ) -> String {
        let mine = String(mySummary.prefix(120))
        let theirs = String(partnerSummary.prefix(120))
        return "Tonight your Muse felt a quiet echo between you. You carried: \(mine). Their mirror held: \(theirs). Tomorrow, lead with one soft question and leave room for silence."
    }

    private func pruneRollingWindow() {
        let cutoff = CalendarKeys.daysAgoKey(30)
        rolling30dRawLogs.removeAll { $0.dateKey < cutoff }
    }
}
