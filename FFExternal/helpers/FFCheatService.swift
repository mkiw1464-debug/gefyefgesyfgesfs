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
    case aimBody    = "AimBody"
    case aimNeck    = "AimNeck"
    case aimDrag    = "AimDrag"
    case magicBullet = "Magic Bullet"
    case antena     = "Antena"
    case hologram   = "Hologram"

    var folderName: String {
        switch self {
        case .aimBody:    return "Aimbody"
        case .aimNeck:    return "Aimneck"
        case .aimDrag:    return "Aimdrag"
        case .magicBullet: return "Magic Bullet"
        case .antena:     return "Antena"
        case .hologram:   return "Hologram"
        }
    }

    var icon: String {
        switch self {
        case .aimBody:    return "scope"
        case .aimNeck:    return "target"
        case .aimDrag:    return "hand.draw"
        case .magicBullet: return "wand.and.rays"
        case .antena:     return "antenna.radiowaves.left.and.right"
        case .hologram:   return "cube.transparent"
        }
    }
}

// MARK: - GitHub asset URLs
private let githubBase = "https://raw.githubusercontent.com/mkiw1464-debug/kntollshahhaha/main"

enum FFCheatService {
    // MARK: - Check asset exists on GitHub
    static func checkAssetExists(game: FFGame, feature: FFFeature) async -> [String: Bool] {
        let gameFolder = game == .freeFire ? "Free Fire" : "Free Fire Max"
        let featureFolder = feature.folderName
        let listURL = URL(string: "\(githubBase)/\(gameFolder.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? gameFolder)/\(featureFolder.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? featureFolder)/files.json")!

        do {
            let (data, resp) = try await URLSession.shared.data(from: listURL)
            if let http = resp as? HTTPURLResponse, http.statusCode == 200,
               let files = try? JSONDecoder().decode([String].self, from: data) {
                var result: [String: Bool] = [:]
                for f in files { result[f] = true }
                return result
            }
        } catch {}
        // fallback: at least check if folder root exists
        let checkURL = URL(string: "\(githubBase)/\(gameFolder.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? gameFolder)/\(featureFolder.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? featureFolder)/")!
        if let resp = try? await URLSession.shared.data(from: checkURL).1 as? HTTPURLResponse {
            return resp.statusCode == 200 ? ["exists": true] : [:]
        }
        return [:]
    }

    // MARK: - Fetch asset from GitHub
    static func fetchAsset(game: FFGame, feature: FFFeature, filename: String) async throws -> Data {
        let gameFolder = game == .freeFire ? "Free Fire" : "Free Fire Max"
        let featureFolder = feature.folderName
        let rawURL = "\(githubBase)/\(gameFolder)/\(featureFolder)/\(filename)"
        guard let url = URL(string: rawURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? rawURL) else {
            throw FFCheatError.fileNotFound
        }
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw FFCheatError.fileNotFound
        }
        return data
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

        let assetDir = (containerPath as NSString).appendingPathComponent(game.gameassetPath)
        progress("[*] Backing up original files...")

        let backupURL = backupDir(for: game, feature: feature)
        try? FileManager.default.createDirectory(at: backupURL, withIntermediateDirectories: true)

        for file in files {
            let targetPath = (assetDir as NSString).appendingPathComponent(file.filename)
            let backupPath = backupURL.appendingPathComponent(file.filename)

            // backup original if exists and not already backed up
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
                    // write data to temp first
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

        let assetDir = (containerPath as NSString).appendingPathComponent(game.gameassetPath)
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
