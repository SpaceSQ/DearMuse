import Foundation

/// 100% on-device sandbox for DID ledger, bottles, relations, and mirror memories.
final class LocalSandboxStore: @unchecked Sendable {
    static let shared = LocalSandboxStore()

    private let root: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        root = support.appendingPathComponent("DearMuse", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    var identityURL: URL { root.appendingPathComponent("identity.json") }
    var relationsURL: URL { root.appendingPathComponent("local_annotated_relations.json") }
    var bottlesURL: URL { root.appendingPathComponent("drift_archive.json") }
    var mirrorsURL: URL { root.appendingPathComponent("muse_coupled_mirror_memories.json") }
    var magpieURL: URL { root.appendingPathComponent("magpie_profile.json") }

    func loadOrCreateIdentity() -> String {
        if let data = try? Data(contentsOf: identityURL),
           let did = try? decoder.decode(String.self, from: data),
           MuseTargetAddress.s2DID(did).isValid {
            return did
        }
        let minted = MuseTargetAddress.mintLocalS2DID()
        try? encoder.encode(minted).write(to: identityURL, options: .atomic)
        return minted
    }

    func saveRelations(_ ledger: [String: LocalAnnotatedRelation]) {
        try? encoder.encode(ledger).write(to: relationsURL, options: .atomic)
    }

    func loadRelations() -> [String: LocalAnnotatedRelation] {
        guard let data = try? Data(contentsOf: relationsURL),
              let ledger = try? decoder.decode([String: LocalAnnotatedRelation].self, from: data) else {
            return [:]
        }
        return ledger
    }

    func saveMagpieProfile(_ profile: MagpieParticipantProfile) {
        try? encoder.encode(profile).write(to: magpieURL, options: .atomic)
    }

    func loadMagpieProfile() -> MagpieParticipantProfile {
        guard let data = try? Data(contentsOf: magpieURL),
              let profile = try? decoder.decode(MagpieParticipantProfile.self, from: data) else {
            return MagpieParticipantProfile()
        }
        return profile
    }
}
