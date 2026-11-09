import Foundation

public struct MagpieParticipantProfile: Codable, Equatable, Sendable {
    public var nickname: String
    public var gender: String
    public var sexualOrientation: String
    public var partnerExpectations: String
    public var personalHobbies: [String]
    public var distilledSoulTags: [String]

    public init(
        nickname: String = "",
        gender: String = "",
        sexualOrientation: String = "",
        partnerExpectations: String = "",
        personalHobbies: [String] = [],
        distilledSoulTags: [String] = []
    ) {
        self.nickname = nickname
        self.gender = gender
        self.sexualOrientation = sexualOrientation
        self.partnerExpectations = partnerExpectations
        self.personalHobbies = personalHobbies
        self.distilledSoulTags = distilledSoulTags
    }
}

public struct MagpieAnonymousPreviewCard: Codable, Identifiable, Sendable {
    public let id: String
    public let weekKey: String
    public let maskedNickname: String
    public let sharedHobbiesSummary: String
    public let museResonanceNote: String
}

public enum MagpieDecision: String, Codable, Sendable {
    case pending
    case agreed
    case rejected
}

/// Sunday 24:00 Magpie Bridge — ~20% match gate, dual consent, 4-week cooldown.
public final class MagpieBridgeMatcher: @unchecked Sendable {
    public static let targetMatchProbability: Double = 0.20
    public static let postMatchCooldownWeeks: Int = 4

    private let router: S2RBMQTTRouter
    private var lastMatchedSuccessTimestamp: TimeInterval?
    public private(set) var profile: MagpieParticipantProfile
    public private(set) var pendingPreview: MagpieAnonymousPreviewCard?
    public private(set) var myDecision: MagpieDecision = .pending

    public init(
        router: S2RBMQTTRouter,
        profile: MagpieParticipantProfile = MagpieParticipantProfile(),
        lastMatchedSuccessTimestamp: TimeInterval? = nil
    ) {
        self.router = router
        self.profile = profile
        self.lastMatchedSuccessTimestamp = lastMatchedSuccessTimestamp
    }

    public func updateProfile(_ profile: MagpieParticipantProfile) {
        self.profile = profile
    }

    public func canParticipateInMagpieThisSunday(
        currentTimestamp: TimeInterval = Date().timeIntervalSince1970
    ) -> (eligible: Bool, remainingWaitDays: Int) {
        guard let matchedTime = lastMatchedSuccessTimestamp else { return (true, 0) }
        let cooldownSeconds = Double(Self.postMatchCooldownWeeks * 7 * 86_400)
        let elapsed = currentTimestamp - matchedTime
        if elapsed >= cooldownSeconds {
            return (true, 0)
        }
        let remainingDays = Int(ceil((cooldownSeconds - elapsed) / 86_400.0))
        return (false, remainingDays)
    }

    public static func evaluateSundayMidnightMatch(
        userA: MagpieParticipantProfile,
        userB: MagpieParticipantProfile,
        compatibilityScore: Double,
        randomRoll: Double = Double.random(in: 0.0...1.0)
    ) -> Bool {
        _ = userA
        _ = userB
        guard randomRoll <= targetMatchProbability, compatibilityScore >= 0.72 else {
            return false
        }
        return true
    }

    @discardableResult
    public func runLocalSundayMatchRoll(
        weekKey: String = CalendarKeys.isoWeekKey(),
        compatibilityScore: Double = 0.85,
        randomRoll: Double = Double.random(in: 0.0...1.0)
    ) -> MagpieAnonymousPreviewCard? {
        let eligibility = canParticipateInMagpieThisSunday()
        guard eligibility.eligible else { return nil }
        guard Self.evaluateSundayMidnightMatch(
            userA: profile,
            userB: MagpieParticipantProfile(nickname: "•••"),
            compatibilityScore: compatibilityScore,
            randomRoll: randomRoll
        ) else {
            pendingPreview = nil
            myDecision = .pending
            return nil
        }

        let card = MagpieAnonymousPreviewCard(
            id: UUID().uuidString,
            weekKey: weekKey,
            maskedNickname: Self.maskNickname(profile.nickname.isEmpty ? "Wanderer" : profile.nickname),
            sharedHobbiesSummary: profile.personalHobbies.prefix(3).joined(separator: " · ").ifEmpty("Quiet nights · books · rain"),
            museResonanceNote: "Two souls orbit the same quiet longing. No names. No addresses. Only a choice."
        )
        pendingPreview = card
        myDecision = .pending
        router.annotateRelationLocally(targetDID: card.id, relation: .pendingMagpie)
        return card
    }

    public func recordMyDecision(_ decision: MagpieDecision) {
        myDecision = decision
    }

    @discardableResult
    public func finalizeMagpieHandshake(
        sessionID: String,
        myDecision: MagpieDecision,
        partnerDecision: MagpieDecision,
        revealedPartnerS2DID: String?,
        currentTimestamp: TimeInterval = Date().timeIntervalSince1970
    ) -> Bool {
        guard myDecision == .agreed && partnerDecision == .agreed,
              let partnerDID = revealedPartnerS2DID else {
            pendingPreview = nil
            self.myDecision = .pending
            return false
        }

        router.annotateRelationLocally(targetDID: partnerDID, relation: .lover)
        lastMatchedSuccessTimestamp = currentTimestamp
        pendingPreview = nil
        self.myDecision = .pending
        _ = sessionID
        return true
    }

    public static func maskNickname(_ name: String) -> String {
        guard let first = name.first else { return "•" }
        return "\(first)•••"
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
