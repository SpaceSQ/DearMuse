import XCTest
@testable import DearMuse

final class CoreEngineTests: XCTestCase {
    func testS2DIDChecksumRoundTrip() {
        let body = String(repeating: "A1", count: 10) // 20 chars
        let checksum = MuseTargetAddress.computeTwoLetterChecksum(for: body)
        let did = body + checksum
        XCTAssertTrue(MuseTargetAddress.s2DID(did).isValid)
        XCTAssertFalse(MuseTargetAddress.s2DID(body + "ZZ").isValid)
    }

    func testMintedDIDIsValid() {
        let did = MuseTargetAddress.mintLocalS2DID()
        XCTAssertEqual(did.count, 22)
        XCTAssertTrue(MuseTargetAddress.s2DID(did).isValid)
    }

    func testDailyBottleQuotaBlocksSecondCast() async throws {
        let router = S2RBMQTTRouter(myS2DID: MuseTargetAddress.mintLocalS2DID())
        let engine = SecretCrushAndBottleEngine(router: router)
        let day = "2026-11-09"
        _ = try await engine.castDailyDriftBottle(
            thoughtForFutureLover: "first longing",
            weatherSnapshot: "mist",
            todayDateKey: day
        )
        do {
            _ = try await engine.castDailyDriftBottle(
                thoughtForFutureLover: "second longing",
                weatherSnapshot: "mist",
                todayDateKey: day
            )
            XCTFail("Expected daily quota error")
        } catch RomanticDispatchError.dailyDriftBottleQuotaExceeded {
            // expected
        }
    }

    func testSecretCrushEnvelopeHasNilSender() async throws {
        let myDID = MuseTargetAddress.mintLocalS2DID()
        let router = S2RBMQTTRouter(myS2DID: myDID)
        let engine = SecretCrushAndBottleEngine(router: router)
        let target = MuseTargetAddress.mintLocalS2DID(seed: "crush-target")
        let envelope = try await engine.sendSecretCrushNote(
            targetAddress: .s2DID(target),
            crushConfession: "I notice you in quiet rooms.",
            weatherSnapshot: "rain"
        )
        XCTAssertNil(envelope.senderDID)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(envelope)
        let decoded = try JSONDecoder().decode(S2RBMQTTEnvelope.self, from: data)
        XCTAssertNil(decoded.senderDID, "Zero-return-address iron rule: senderDID must stay nil after round-trip")
        let json = String(data: data, encoding: .utf8) ?? ""
        XCTAssertFalse(json.contains("\"senderDID\":\"\""), json)
        // Explicit null or key absence both satisfy the envelope contract; prefer explicit null.
        if json.contains("senderDID") {
            XCTAssertTrue(json.contains("\"senderDID\":null"), json)
        }
    }

    func testMagpieMatchRateAroundTwentyPercent() {
        var hits = 0
        let trials = 1000
        for i in 0..<trials {
            let mixed = UInt64(i) &* 2_654_435_761
            let pseudo = Double(mixed % 10_000) / 10_000.0
            if MagpieBridgeMatcher.evaluateSundayMidnightMatch(
                userA: MagpieParticipantProfile(nickname: "A"),
                userB: MagpieParticipantProfile(nickname: "B"),
                compatibilityScore: 0.9,
                randomRoll: pseudo
            ) {
                hits += 1
            }
        }
        let rate = Double(hits) / Double(trials)
        XCTAssertGreaterThan(rate, 0.18)
        XCTAssertLessThan(rate, 0.22)
    }

    func testMagpieCooldownFourWeeks() {
        let router = S2RBMQTTRouter(myS2DID: MuseTargetAddress.mintLocalS2DID())
        let matcher = MagpieBridgeMatcher(router: router)
        let now: TimeInterval = 1_700_000_000
        let partner = MuseTargetAddress.mintLocalS2DID(seed: "partner")
        XCTAssertTrue(
            matcher.finalizeMagpieHandshake(
                sessionID: "s1",
                myDecision: .agreed,
                partnerDecision: .agreed,
                revealedPartnerS2DID: partner,
                currentTimestamp: now
            )
        )
        let day27 = matcher.canParticipateInMagpieThisSunday(currentTimestamp: now + 27 * 86_400)
        XCTAssertFalse(day27.eligible)
        let day29 = matcher.canParticipateInMagpieThisSunday(currentTimestamp: now + 29 * 86_400)
        XCTAssertTrue(day29.eligible)
    }

    func testLoverGuardRejectsAfterUnlabel() throws {
        let me = MuseTargetAddress.mintLocalS2DID(seed: "me")
        let partner = MuseTargetAddress.mintLocalS2DID(seed: "lover")
        let router = S2RBMQTTRouter(myS2DID: me)
        router.annotateRelationLocally(targetDID: partner, relation: .lover)
        let memory = MuseMirrorMemoryEngine(myS2DID: me, router: router)
        let outbound = try memory.buildMidnightOutboundMirrorEnvelope(
            partnerS2DID: partner,
            myDailyDialogueSummary300: "soft day",
            myDailyContextSummary300: "rain",
            emotionalTone: "calm",
            dateKey: "2026-11-09"
        )
        XCTAssertNotNil(outbound)

        router.annotateRelationLocally(targetDID: partner, relation: .stranger)
        let inbound = S2RBMQTTEnvelope(
            packetType: .midnightMuseMirror,
            recipientDID: me,
            senderDID: partner,
            createdAtTimestamp: Date().timeIntervalSince1970,
            deliverAfterTimestamp: nil,
            encryptedPayload: Data("{}".utf8)
        )
        XCTAssertFalse(router.shouldAcceptIncomingMQTTEnvelope(inbound))
    }

    func testSixSegmentAddressValid() {
        XCTAssertTrue(MuseTargetAddress.sixSegmentAddress("CN.GD.GZ.TH.CB.311").isValid)
        XCTAssertFalse(MuseTargetAddress.sixSegmentAddress("CN.GD.GZ").isValid)
    }
}
