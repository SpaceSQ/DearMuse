import Foundation

/// Production Rainbow Bridge transport: MQTT 3.1.1 over WebSocket (WSS).
/// Cloud remains exchange-only (`retain = false`). Lover/relation truth stays local.
@MainActor
@Observable
final class RainbowBridgeMQTTClient {
    enum ConnectionState: Equatable {
        case idle
        case connecting
        case connected
        case failed(String)
    }

    struct Config: Equatable, Sendable {
        var webSocketURL: URL
        var clientIDPrefix: String
        var keepAliveSeconds: UInt16

        static func loadFromBundle() -> Config {
            let defaults = Bundle.main.object(forInfoDictionaryKey: "DEARMUSE_MQTT_WSS_URL") as? String
            let urlString = (defaults?.isEmpty == false ? defaults! : "wss://broker.emqx.io:8084/mqtt")
            let url = URL(string: urlString) ?? URL(string: "wss://broker.emqx.io:8084/mqtt")!
            return Config(
                webSocketURL: url,
                clientIDPrefix: "dearmuse",
                keepAliveSeconds: 45
            )
        }
    }

    private(set) var state: ConnectionState = .idle
    private(set) var lastError: String?
    private(set) var publishedCount = 0
    private(set) var receivedCount = 0

    private let myS2DID: String
    private let router: S2RBMQTTRouter
    private var config: Config
    private var task: URLSessionWebSocketTask?
    private var session: URLSession?
    private var packetID: UInt16 = 1
    private var pingTimer: Timer?
    private var receiveHandler: ((S2RBMQTTEnvelope) -> Void)?

    init(myS2DID: String, router: S2RBMQTTRouter, config: Config = .loadFromBundle()) {
        self.myS2DID = myS2DID
        self.router = router
        self.config = config
    }

    func onEnvelope(_ handler: @escaping (S2RBMQTTEnvelope) -> Void) {
        receiveHandler = handler
    }

    func connect() {
        disconnect()
        state = .connecting
        lastError = nil

        let session = URLSession(configuration: .default)
        self.session = session
        var request = URLRequest(url: config.webSocketURL)
        request.setValue("mqtt", forHTTPHeaderField: "Sec-WebSocket-Protocol")
        let task = session.webSocketTask(with: request)
        self.task = task
        task.resume()

        let clientID = "\(config.clientIDPrefix)-\(String(myS2DID.suffix(8)))-\(UUID().uuidString.prefix(6))"
        send(MQTTPacketCodec.connect(clientID: clientID, keepAlive: config.keepAliveSeconds))
        listen()
    }

    func disconnect() {
        pingTimer?.invalidate()
        pingTimer = nil
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        session?.invalidateAndCancel()
        session = nil
        if case .connected = state {
            state = .idle
        }
    }

    /// Publish envelope to the canonical S2RB topic. Always `retain = false`.
    func publish(_ envelope: S2RBMQTTEnvelope) throws {
        guard case .connected = state else {
            throw BridgeError.notConnected
        }
        let topic = topic(for: envelope)
        let payload = try JSONEncoder().encode(envelope)
        send(MQTTPacketCodec.publish(topic: topic, payload: payload, qos: 0, retain: false))
        publishedCount += 1
    }

    func flushOutboundQueue() {
        let batch = router.drainOutboundQueue()
        for envelope in batch {
            do {
                try publish(envelope)
            } catch {
                router.enqueueOutbound(envelope)
            }
        }
    }

    func subscribeDefaultInboxes() {
        guard case .connected = state else { return }
        subscribe(S2RBTopic.crushInbox(recipient22: myS2DID))
        subscribe(S2RBTopic.loverChannel(recipient22: myS2DID))
        // Ocean pool: today's delivery key (demo / edge pickup)
        subscribe(S2RBTopic.oceanBottle(deliveryDateYYYYMMDD: CalendarKeys.todayKey().replacingOccurrences(of: "-", with: "_")))
    }

    // MARK: - private

    private func subscribe(_ topic: String) {
        packetID &+= 1
        send(MQTTPacketCodec.subscribe(packetID: packetID, topic: topic, qos: 0))
    }

    private func topic(for envelope: S2RBMQTTEnvelope) -> String {
        switch envelope.packetType {
        case .driftBottle:
            let date: String
            if let ts = envelope.deliverAfterTimestamp {
                date = CalendarKeys.todayKey(now: Date(timeIntervalSince1970: ts)).replacingOccurrences(of: "-", with: "_")
            } else {
                date = CalendarKeys.todayKey().replacingOccurrences(of: "-", with: "_")
            }
            return S2RBTopic.oceanBottle(deliveryDateYYYYMMDD: date)
        case .secretCrushNote:
            return S2RBTopic.crushInbox(recipient22: envelope.recipientDID)
        case .magpiePreview, .magpieConsentHandshake:
            return S2RBTopic.magpieHandshake(sessionID: envelope.recipientDID)
        case .loverDirectMessage, .midnightMuseMirror:
            return S2RBTopic.loverChannel(recipient22: envelope.recipientDID)
        }
    }

    private func send(_ data: Data) {
        task?.send(.data(data)) { [weak self] error in
            Task { @MainActor in
                if let error {
                    self?.lastError = error.localizedDescription
                    self?.state = .failed(error.localizedDescription)
                }
            }
        }
    }

    private func listen() {
        task?.receive { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .failure(let error):
                    self.lastError = error.localizedDescription
                    self.state = .failed(error.localizedDescription)
                case .success(let message):
                    let data: Data
                    switch message {
                    case .data(let d): data = d
                    case .string(let s): data = Data(s.utf8)
                    @unknown default: data = Data()
                    }
                    self.handle(data)
                    self.listen()
                }
            }
        }
    }

    private func handle(_ data: Data) {
        for event in MQTTPacketCodec.parseIncoming(data) {
            switch event {
            case .connack(let code):
                if code == 0 {
                    state = .connected
                    startPing()
                    subscribeDefaultInboxes()
                    flushOutboundQueue()
                } else {
                    state = .failed("CONNACK \(code)")
                }
            case .publish(let msg):
                receivedCount += 1
                if let envelope = try? JSONDecoder().decode(S2RBMQTTEnvelope.self, from: msg.payload),
                   router.shouldAcceptIncomingMQTTEnvelope(envelope) {
                    receiveHandler?(envelope)
                }
            case .suback, .pingresp:
                break
            }
        }
    }

    private func startPing() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(config.keepAliveSeconds / 2), repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.send(MQTTPacketCodec.pingReq())
            }
        }
    }

    enum BridgeError: LocalizedError {
        case notConnected
        var errorDescription: String? {
            switch self {
            case .notConnected: return "Rainbow Bridge MQTT is not connected."
            }
        }
    }
}
