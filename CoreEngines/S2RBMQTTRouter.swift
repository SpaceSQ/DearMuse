import Foundation
import CryptoKit

public enum MuseTargetAddress: Codable, Equatable, Sendable {
    case s2DID(String)
    case sixSegmentAddress(String)

    public var isValid: Bool {
        switch self {
        case .s2DID(let raw):
            guard raw.count == 22, !raw.contains("-") else { return false }
            let body = String(raw.prefix(20))
            let checksum = String(raw.suffix(2))
            return Self.computeTwoLetterChecksum(for: body) == checksum
        case .sixSegmentAddress(let addr):
            let segments = addr.split(separator: ".")
            return segments.count == 6 && segments.allSatisfy { !$0.isEmpty }
        }
    }

    public static func computeTwoLetterChecksum(for body20: String) -> String {
        let digest = SHA256.hash(data: Data(body20.utf8))
        let bytes = Array(digest)
        let firstChar = Character(UnicodeScalar(65 + Int(bytes[0] % 26))!)
        let secondChar = Character(UnicodeScalar(65 + Int(bytes[1] % 26))!)
        return "\(firstChar)\(secondChar)"
    }

    public static func mintLocalS2DID(seed: String = UUID().uuidString) -> String {
        let digest = SHA256.hash(data: Data(seed.utf8))
        let hex = digest.map { String(format: "%02X", $0) }.joined()
        let body20 = String(hex.prefix(20))
        return body20 + computeTwoLetterChecksum(for: body20)
    }
}

public enum LocalAnnotatedRelation: String, Codable, Sendable {
    case stranger = "stranger"
    case pendingMagpie = "pending_magpie"
    case lover = "lover"
    case blocked = "blocked"
}

public enum S2RBMQTTPacketType: String, Codable, Sendable {
    case driftBottle = "drift_bottle"
    case secretCrushNote = "secret_crush_note"
    case magpiePreview = "magpie_preview"
    case magpieConsentHandshake = "magpie_Decision"
    case loverDirectMessage = "lover_direct_msg"
    case midnightMuseMirror = "midnight_mirror_00"
}

public struct S2RBMQTTEnvelope: Codable, Identifiable, Sendable {
    public let id: UUID
    public let packetType: S2RBMQTTPacketType
    public let recipientDID: String
    public let senderDID: String?
    public let createdAtTimestamp: TimeInterval
    public let deliverAfterTimestamp: TimeInterval?
    public let encryptedPayload: Data

    public init(
        id: UUID = UUID(),
        packetType: S2RBMQTTPacketType,
        recipientDID: String,
        senderDID: String?,
        createdAtTimestamp: TimeInterval,
        deliverAfterTimestamp: TimeInterval?,
        encryptedPayload: Data
    ) {
        self.id = id
        self.packetType = packetType
        self.recipientDID = recipientDID
        self.senderDID = senderDID
        self.createdAtTimestamp = createdAtTimestamp
        self.deliverAfterTimestamp = deliverAfterTimestamp
        self.encryptedPayload = encryptedPayload
    }
}

public enum S2RBTopic {
    public static func oceanBottle(deliveryDateYYYYMMDD: String) -> String {
        "s2rb/dearmuse/ocean/bottle/\(deliveryDateYYYYMMDD)"
    }

    public static func crushInbox(recipient22: String) -> String {
        "s2rb/dearmuse/inbox/\(recipient22)/crush"
    }

    public static func magpieHandshake(sessionID: String) -> String {
        "s2rb/dearmuse/magpie/\(sessionID)/handshake"
    }

    public static func loverChannel(recipient22: String) -> String {
        "s2rb/dearmuse/lovers/\(recipient22)/mirror_and_chat"
    }
}

/// Rainbow Bridge client router + local relation guard (cloud keeps zero relationship state).
public final class S2RBMQTTRouter: @unchecked Sendable {
    public let myS2DID: String
    private var localRelationLedger: [String: LocalAnnotatedRelation] = [:]
    private(set) var outboundQueue: [S2RBMQTTEnvelope] = []

    public init(myS2DID: String) {
        self.myS2DID = myS2DID
    }

    public func annotateRelationLocally(targetDID: String, relation: LocalAnnotatedRelation) {
        localRelationLedger[targetDID] = relation
    }

    public func queryLocalRelation(for targetDID: String) -> LocalAnnotatedRelation {
        localRelationLedger[targetDID] ?? .stranger
    }

    public func snapshotRelations() -> [String: LocalAnnotatedRelation] {
        localRelationLedger
    }

    public func resolveToS2DIDViaRainbowBridge(address: MuseTargetAddress) async throws -> String {
        guard address.isValid else {
            throw NSError(
                domain: "S2RBRouter",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Invalid 22-char S2-DID or six-segment address"]
            )
        }
        switch address {
        case .s2DID(let did):
            return did
        case .sixSegmentAddress(let sixSeg):
            return try await requestS2RBStatelessResolver(sixSegmentCode: sixSeg)
        }
    }

    public func shouldAcceptIncomingMQTTEnvelope(_ envelope: S2RBMQTTEnvelope) -> Bool {
        switch envelope.packetType {
        case .secretCrushNote, .driftBottle:
            return envelope.recipientDID == myS2DID || envelope.recipientDID == "S2RB_OCEAN_RANDOM_POOL"
        case .magpiePreview, .magpieConsentHandshake:
            return envelope.recipientDID == myS2DID
        case .loverDirectMessage, .midnightMuseMirror:
            guard let sender = envelope.senderDID else { return false }
            return queryLocalRelation(for: sender) == .lover
        }
    }

    public func enqueueOutbound(_ envelope: S2RBMQTTEnvelope) {
        outboundQueue.append(envelope)
    }

    @discardableResult
    public func drainOutboundQueue() -> [S2RBMQTTEnvelope] {
        let batch = outboundQueue
        outboundQueue.removeAll()
        return batch
    }

    private func requestS2RBStatelessResolver(sixSegmentCode: String) async throws -> String {
        let hashed = SHA256.hash(data: Data(sixSegmentCode.utf8))
            .compactMap { String(format: "%02X", $0) }
            .joined()
        let body20 = String(hashed.prefix(20))
        let checksum = MuseTargetAddress.computeTwoLetterChecksum(for: body20)
        return body20 + checksum
    }
}
