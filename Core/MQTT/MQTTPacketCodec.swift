import Foundation

/// Minimal MQTT 3.1.1 binary codec for CONNECT / CONNACK / PUBLISH / SUBSCRIBE / PING.
enum MQTTPacketCodec {
    static let protocolName = "MQTT"
    static let protocolLevel: UInt8 = 4

    static func connect(clientID: String, keepAlive: UInt16 = 60, cleanSession: Bool = true) -> Data {
        var variable = Data()
        variable.append(mqttString(protocolName))
        variable.append(protocolLevel)
        var connectFlags: UInt8 = cleanSession ? 0b0000_0010 : 0
        variable.append(connectFlags)
        variable.append(contentsOf: [UInt8(keepAlive >> 8), UInt8(keepAlive & 0xff)])
        variable.append(mqttString(clientID))
        return fixedHeader(type: 1, flags: 0, remaining: variable) + variable
    }

    static func subscribe(packetID: UInt16, topic: String, qos: UInt8 = 0) -> Data {
        var variable = Data()
        variable.append(contentsOf: [UInt8(packetID >> 8), UInt8(packetID & 0xff)])
        variable.append(mqttString(topic))
        variable.append(qos)
        return fixedHeader(type: 8, flags: 0b0010, remaining: variable) + variable
    }

    static func publish(topic: String, payload: Data, qos: UInt8 = 0, retain: Bool = false) -> Data {
        var variable = Data()
        variable.append(mqttString(topic))
        // QoS 0 — no packet id
        variable.append(payload)
        var flags: UInt8 = retain ? 0b0001 : 0
        flags |= (qos & 0b11) << 1
        return fixedHeader(type: 3, flags: flags, remaining: variable) + variable
    }

    static func pingReq() -> Data {
        Data([0xC0, 0x00])
    }

    static func parseIncoming(_ data: Data) -> [Incoming] {
        var results: [Incoming] = []
        var offset = 0
        while offset < data.count {
            guard let header = readFixedHeader(data, offset: &offset) else { break }
            let end = offset + header.remainingLength
            guard end <= data.count else { break }
            let body = data.subdata(in: offset..<end)
            offset = end
            switch header.type {
            case 2: // CONNACK
                let code = body.count >= 2 ? body[1] : 0xff
                results.append(.connack(returnCode: code))
            case 3: // PUBLISH
                if let msg = parsePublish(body: body, flags: header.flags) {
                    results.append(.publish(msg))
                }
            case 9: // SUBACK
                results.append(.suback)
            case 13: // PINGRESP
                results.append(.pingresp)
            default:
                break
            }
        }
        return results
    }

    enum Incoming: Equatable {
        case connack(returnCode: UInt8)
        case publish(PublishMessage)
        case suback
        case pingresp
    }

    struct PublishMessage: Equatable {
        let topic: String
        let payload: Data
        let retainFlag: Bool
    }

    // MARK: - helpers

    private static func mqttString(_ string: String) -> Data {
        let utf8 = Data(string.utf8)
        var out = Data([UInt8(utf8.count >> 8), UInt8(utf8.count & 0xff)])
        out.append(utf8)
        return out
    }

    private static func fixedHeader(type: UInt8, flags: UInt8, remaining: Data) -> Data {
        var header = Data([UInt8((type << 4) | (flags & 0x0f))])
        header.append(encodeRemainingLength(remaining.count))
        return header
    }

    private static func encodeRemainingLength(_ length: Int) -> Data {
        var x = length
        var out = Data()
        repeat {
            var encoded = UInt8(x % 128)
            x /= 128
            if x > 0 { encoded |= 0x80 }
            out.append(encoded)
        } while x > 0
        return out
    }

    private struct FixedHeader {
        let type: UInt8
        let flags: UInt8
        let remainingLength: Int
    }

    private static func readFixedHeader(_ data: Data, offset: inout Int) -> FixedHeader? {
        guard offset < data.count else { return nil }
        let first = data[offset]
        offset += 1
        let type = first >> 4
        let flags = first & 0x0f
        var multiplier = 1
        var value = 0
        for _ in 0..<4 {
            guard offset < data.count else { return nil }
            let encoded = data[offset]
            offset += 1
            value += Int(encoded & 0x7f) * multiplier
            if encoded & 0x80 == 0 {
                return FixedHeader(type: type, flags: flags, remainingLength: value)
            }
            multiplier *= 128
        }
        return nil
    }

    private static func parsePublish(body: Data, flags: UInt8) -> PublishMessage? {
        guard body.count >= 2 else { return nil }
        let topicLen = Int(body[0]) << 8 | Int(body[1])
        guard body.count >= 2 + topicLen else { return nil }
        let topicData = body.subdata(in: 2..<(2 + topicLen))
        guard let topic = String(data: topicData, encoding: .utf8) else { return nil }
        var payloadStart = 2 + topicLen
        let qos = (flags >> 1) & 0b11
        if qos > 0 {
            payloadStart += 2 // skip packet id
        }
        guard payloadStart <= body.count else { return nil }
        let payload = body.subdata(in: payloadStart..<body.count)
        return PublishMessage(topic: topic, payload: payload, retainFlag: flags & 0b1 == 1)
    }
}
