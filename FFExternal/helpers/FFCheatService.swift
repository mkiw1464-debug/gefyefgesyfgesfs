import Foundation

// MARK: - Game definitions
enum FFGame {
    case freeFire
    case freeFireMax

    var bundleID: String {
        switch self {
        case .freeFire:    return "com.dts.freefireth"
        case .freeFireMax: return "com.dts.freefiremax"
        }
    }

    var gameassetPath: String {
        return "Documents/contentcache/Compulsory/ios/gameassetbundles"
    }
}

// MARK: - Feature definitions
enum FFFeature: String, CaseIterable {
    case aimBody     = "AimBody"
    case aimNeck     = "AimNeck"
    case aimDrag     = "AimDrag"
    case magicBullet = "Magic Bullet"
    case antena      = "Antena"
    case hologram    = "Hologram"

    var folderName: String {
        switch self {
        case .aimBody:     return "Aimbody"
        case .aimNeck:     return "Aimneck"
        case .aimDrag:     return "Aimdrag"
        case .magicBullet: return "Magic Bullet"
        case .antena:      return "Antena"
        case .hologram:    return "Hologram"
        }
    }

    // No icon used in UI — removed
}

// MARK: - GitHub base URL
private let githubBase = "https://raw.githubusercontent.com/mkiw1464-debug/kntollshahhaha/main"

enum FFCheatService {

    // MARK: - Check if source folder is available (files.json in folder)
    /// Returns true if the folder has a valid files.json listing.
    static func checkSourceAvailable(game: FFGame, feature: FFFeature) async -> Bool {
        let gameFolder    = game == .freeFire ? "Free Fire" : "Free Fire Max"
        let featureFolder = feature.folderName
        let urlStr = "\(githubBase)/\(gameFolder)/\(featureFolder)/files.json"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: urlStr) else { return false }

        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return false }
            // Must be a valid JSON array of filenames
            if let names = try? JSONDecoder().decode([String].self, from: data), !names.isEmpty {
                return true
            }
        } catch {}
        return false
    }

    // MARK: - Backup directory
    private static func backupDir(for game: FFGame, feature: FFFeature) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs
            .appendingPathComponent("FFExternal_Backup")
            .appendingPathComponent(game.bundleID)
            .appendingPathComponent(feature.folderName)
    }

    // MARK: - Inject
    /// files.json inside the feature folder lists the raw filenames (no path).
    /// The actual cheat files sit beside files.json in the same folder.
    static func inject(
        game: FFGame,
        feature: FFFeature,
        files: [(filename: String, data: Data)],
        progress: @escaping (String) -> Void
    ) async throws {

        progress("[*] Locating game container...")
        guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: game.bundleID) else {
            throw FFCheatError.gameNotInstalled
        }

        let assetDir  = (containerPath as NSString).appendingPathComponent(game.gameassetPath)
        let backupURL = backupDir(for: game, feature: feature)
        try? FileManager.default.createDirectory(at: backupURL, withIntermediateDirectories: true)

        progress("[*] Backing up original files...")
        for file in files {
            let targetPath = (assetDir as NSString).appendingPathComponent(file.filename)
            let backupPath = backupURL.appendingPathComponent(file.filename)

            if FileManager.default.fileExists(atPath: targetPath),
               !FileManager.default.fileExists(atPath: backupPath.path) {
                try? FileManager.default.copyItem(atPath: targetPath, toPath: backupPath.path)
            }
        }

        progress("[*] Writing cheat assets...")
        for file in files {
            let targetPath = (assetDir as NSString).appendingPathComponent(file.filename)
            let targetURL  = URL(fileURLWithPath: targetPath)

            if FileManager.default.fileExists(atPath: targetPath) {
                _ = try FileReplacementService.replace(target: targetURL, with: {
                    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                    try file.data.write(to: tmp)
                    return tmp
                }())
            } else {
                try file.data.write(to: targetURL)
            }
        }

        progress("[✓] Done!")
    }

    // MARK: - Restore
    static func restore(
        game: FFGame,
        feature: FFFeature,
        progress: @escaping (String) -> Void
    ) async throws {

        progress("[*] Locating game container...")
        guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: game.bundleID) else {
            throw FFCheatError.gameNotInstalled
        }

        let assetDir  = (containerPath as NSString).appendingPathComponent(game.gameassetPath)
        let backupURL = backupDir(for: game, feature: feature)

        progress("[*] Restoring original files...")
        guard let backups = try? FileManager.default.contentsOfDirectory(at: backupURL, includingPropertiesForKeys: nil),
              !backups.isEmpty else {
            throw FFCheatError.noBackup
        }

        for backup in backups {
            let targetPath = (assetDir as NSString).appendingPathComponent(backup.lastPathComponent)
            let targetURL  = URL(fileURLWithPath: targetPath)

            if FileManager.default.fileExists(atPath: targetPath) {
                _ = try FileReplacementService.replace(target: targetURL, with: backup)
            } else {
                try FileManager.default.copyItem(at: backup, to: targetURL)
            }
            try? FileManager.default.removeItem(at: backup)
        }

        try? FileManager.default.removeItem(at: backupURL)
        progress("[✓] Restored!")
    }

    static func hasBackup(game: FFGame, feature: FFFeature) -> Bool {
        let url = backupDir(for: game, feature: feature)
        return (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil))?.isEmpty == false
    }
}

// MARK: - Errors
enum FFCheatError: Error, LocalizedError {
    case gameNotInstalled
    case fileNotFound
    case noBackup
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .gameNotInstalled: return "Game not installed or inaccessible."
        case .fileNotFound:     return "Cheat file not found on server."
        case .noBackup:         return "No backup found to restore."
        case .writeFailed:      return "Failed to write file."
        }
    }
}
