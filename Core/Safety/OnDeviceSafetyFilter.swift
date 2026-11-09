import Foundation

/// App Store Guideline 1.2 UGC shield — on-device blocklist + report hook.
public struct OnDeviceSafetyFilter: Sendable {
    public static let shared = OnDeviceSafetyFilter()

    private let blockedTerms: Set<String> = [
        "kill yourself", "bomb", "terror", "child porn", "csam",
        "自杀", "炸弹", "恐袭"
    ]

    public func isSafe(_ text: String) -> Bool {
        let lowered = text.lowercased()
        return !blockedTerms.contains { lowered.contains($0) }
    }

    public func sanitize(_ text: String) -> String {
        guard isSafe(text) else {
            return "[filtered — this note was blocked by the on-device safety shield]"
        }
        return text
    }
}

public struct BlockReportAction: Identifiable, Sendable {
    public let id = UUID()
    public let channelTopic: String
    public let reason: String
    public let createdAt: Date
}
