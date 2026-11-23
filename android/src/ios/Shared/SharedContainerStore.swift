import Foundation

/// Reads and writes PendingShare data to the App Group shared container.
/// Compiled into both the main app target and the Share Extension target.
enum SharedContainerStore {
    static let appGroupID = "group.io.github.nanomuse.app"

    // nanoMuse: privately signed builds can use their own sandbox without the release app group.
    static let appGroupContainerURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: appGroupID
    )
    static let storageContainerURL = appGroupContainerURL ?? FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("NanoMuse", isDirectory: true)

    private static let pendingShareKey = "pendingShare"

    static var sharedDefaults: UserDefaults? {
        guard appGroupContainerURL != nil else { return nil } // nanoMuse: sharing needs a common container.
        return UserDefaults(suiteName: appGroupID)
    }

    /// Directory in the shared container for transferring attachment files.
    static var sharedFileDirectory: URL? {
        appGroupContainerURL?.appendingPathComponent("ShareExtension", isDirectory: true) // nanoMuse:
    }

    // MARK: - Write (called by Share Extension)

    static func savePendingShare(_ share: PendingShare) {
        guard let defaults = sharedDefaults else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(share) {
            defaults.set(data, forKey: pendingShareKey)
            defaults.synchronize()
        }
    }

    // MARK: - Read & Consume (called by main app)

    static func loadPendingShare() -> PendingShare? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: pendingShareKey) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(PendingShare.self, from: data)
    }

    static func clearPendingShare() {
        sharedDefaults?.removeObject(forKey: pendingShareKey)
        sharedDefaults?.synchronize()
    }

    /// Remove all files from the shared transfer directory.
    static func cleanSharedFiles() {
        guard let dir = sharedFileDirectory else { return }
        let fm = FileManager.default
        if let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
            for file in files {
                try? fm.removeItem(at: file)
            }
        }
    }
}
