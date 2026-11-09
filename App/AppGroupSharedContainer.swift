import Foundation

/// Shared on-device model mount for Dear Universe App Group (≤12GB guard).
enum AppGroupSharedContainer {
    static let appGroupID = "group.com.s2.dearuniverse"
    static let maxBytes: Int64 = 12 * 1024 * 1024 * 1024

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    static var modelsDirectory: URL? {
        containerURL?.appendingPathComponent("models", isDirectory: true)
    }

    static func ensureDirectories() {
        guard let models = modelsDirectory else { return }
        try? FileManager.default.createDirectory(at: models, withIntermediateDirectories: true)
    }

    static func remainingQuotaBytes() -> Int64 {
        guard let url = containerURL else { return 0 }
        let used = directoryByteSize(at: url)
        return max(0, maxBytes - used)
    }

    private static func directoryByteSize(at url: URL) -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                  values.isRegularFile == true else { continue }
            total += Int64(values.fileSize ?? 0)
        }
        return total
    }
}
