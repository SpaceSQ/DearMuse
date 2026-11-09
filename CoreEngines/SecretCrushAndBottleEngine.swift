import Foundation
import CryptoKit

public struct AnonymousRomanticNote: Codable, Identifiable, Sendable {
    public let id: UUID
    public let content: String
    public let moodWeatherSnapshot: String
    public let writtenDateKey: String
}

public enum RomanticDispatchError: Error, LocalizedError, Sendable {
    case dailyDriftBottleQuotaExceeded
    case invalidRecipientAddress
    case emptyContent

    public var errorDescription: String? {
        switch self {
        case .dailyDriftBottleQuotaExceeded:
            return "You've already cast one bottle today. Keep the next longing for tomorrow."
        case .invalidRecipientAddress:
            return "That 22-char S2-DID or six-segment address looks invalid."
        case .emptyContent:
            return "Write a few words before casting."
        }
    }
}

/// Zero-return-address drift bottles + secret crush notes.
/// Call from the main actor / a single serial owner — relationship ledger lives on-device.
public final class SecretCrushAndBottleEngine: @unchecked Sendable {
    public static let oceanPoolRecipient = "S2RB_OCEAN_RANDOM_POOL"

    private let router: S2RBMQTTRouter
    private var lastDriftBottleSentDateKey: String?
    private(set) var castArchive: [AnonymousRomanticNote] = []
    private(set) var inbox: [AnonymousRomanticNote] = []
    private var outboundCrushHashes: Set<String> = []
    private var inboundCrushHashes: Set<String> = []

    public init(router: S2RBMQTTRouter, lastSentDateKey: String? = nil) {
        self.router = router
        self.lastDriftBottleSentDateKey = lastSentDateKey
    }

    public var hasCastToday: Bool {
        lastDriftBottleSentDateKey == CalendarKeys.todayKey()
    }

    public func castDailyDriftBottle(
        thoughtForFutureLover: String,
        weatherSnapshot: String,
        todayDateKey: String = CalendarKeys.todayKey()
    ) async throws -> S2RBMQTTEnvelope {
        let trimmed = thoughtForFutureLover.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw RomanticDispatchError.emptyContent }
        guard lastDriftBottleSentDateKey != todayDateKey else {
            throw RomanticDispatchError.dailyDriftBottleQuotaExceeded
        }

        let note = AnonymousRomanticNote(
            id: UUID(),
            content: trimmed,
            moodWeatherSnapshot: weatherSnapshot,
            writtenDateKey: todayDateKey
        )
        let payloadData = try JSONEncoder().encode(note)

        let randomDaysInYear = Double(Int.random(in: 1...365))
        let now = Date().timeIntervalSince1970
        let pickUpTimestamp = now + (randomDaysInYear * 86_400.0)

        let envelope = S2RBMQTTEnvelope(
            packetType: .driftBottle,
            recipientDID: Self.oceanPoolRecipient,
            senderDID: nil,
            createdAtTimestamp: now,
            deliverAfterTimestamp: pickUpTimestamp,
            encryptedPayload: payloadData
        )

        lastDriftBottleSentDateKey = todayDateKey
        castArchive.append(note)
        router.enqueueOutbound(envelope)
        return envelope
    }

    public func sendSecretCrushNote(
        targetAddress: MuseTargetAddress,
        crushConfession: String,
        weatherSnapshot: String,
        todayDateKey: String = CalendarKeys.todayKey()
    ) async throws -> S2RBMQTTEnvelope {
        let trimmed = crushConfession.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw RomanticDispatchError.emptyContent }
        guard targetAddress.isValid else { throw RomanticDispatchError.invalidRecipientAddress }

        let resolvedRecipientDID = try await router.resolveToS2DIDViaRainbowBridge(address: targetAddress)
        let note = AnonymousRomanticNote(
            id: UUID(),
            content: trimmed,
            moodWeatherSnapshot: weatherSnapshot,
            writtenDateKey: todayDateKey
        )
        let payloadData = try JSONEncoder().encode(note)

        let envelope = S2RBMQTTEnvelope(
            packetType: .secretCrushNote,
            recipientDID: resolvedRecipientDID,
            senderDID: nil,
            createdAtTimestamp: Date().timeIntervalSince1970,
            deliverAfterTimestamp: nil,
            encryptedPayload: payloadData
        )

        let pairHash = Self.mutualCrushHash(from: router.myS2DID, to: resolvedRecipientDID)
        outboundCrushHashes.insert(pairHash)
        castArchive.append(note)
        router.enqueueOutbound(envelope)
        return envelope
    }

    public func receiveAnonymousNote(_ note: AnonymousRomanticNote, as packet: S2RBMQTTPacketType) {
        inbox.append(note)
        _ = packet
    }

    public func registerInboundCrushFromUnknownSender(hypotheticalPairWithMeAnd: String) -> Bool {
        let hash = Self.mutualCrushHash(from: hypotheticalPairWithMeAnd, to: router.myS2DID)
        inboundCrushHashes.insert(hash)
        return outboundCrushHashes.contains(hash)
    }

    public func checkMutualCrush(with otherDID: String) -> Bool {
        let hash = Self.mutualCrushHash(from: router.myS2DID, to: otherDID)
        return outboundCrushHashes.contains(hash) && inboundCrushHashes.contains(hash)
    }

    public static func mutualCrushHash(from a: String, to b: String) -> String {
        let pair = [a, b].sorted().joined(separator: "|")
        let digest = SHA256.hash(data: Data(pair.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
