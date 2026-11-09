import XCTest
@testable import DearMuse

final class MQTTPacketCodecTests: XCTestCase {
    func testConnectPacketStartsWithTypeOne() {
        let packet = MQTTPacketCodec.connect(clientID: "dearmuse-test")
        XCTAssertEqual(packet[0] >> 4, 1)
        XCTAssertGreaterThan(packet.count, 10)
    }

    func testPublishRetainFalseFlag() {
        let packet = MQTTPacketCodec.publish(
            topic: "s2rb/dearmuse/ocean/bottle/2026_11_09",
            payload: Data(#"{"ok":true}"#.utf8),
            qos: 0,
            retain: false
        )
        XCTAssertEqual(packet[0] >> 4, 3)
        XCTAssertEqual(packet[0] & 0b1, 0, "retain must be false for Rainbow Bridge")
    }

    func testParseConnackAccepted() {
        let connack = Data([0x20, 0x02, 0x00, 0x00])
        let events = MQTTPacketCodec.parseIncoming(connack)
        XCTAssertEqual(events, [.connack(returnCode: 0)])
    }
}
