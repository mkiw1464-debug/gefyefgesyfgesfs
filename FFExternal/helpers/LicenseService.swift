import Foundation
import UIKit

struct LicenseResponse: Decodable {
    let valid:      Bool
    let status:     String?
    let expires_at: String?
    let hwid:       String?
}

enum LicenseService {
    static let apiURL = "https://ffexxxx.vercel.app/api/licenses/validate"

    static var deviceID: String {
        UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device"
    }

    static var deviceName: String {
        UIDevice.current.name
    }

    static func validate(key: String) async throws -> LicenseResponse {
        guard let url = URL(string: apiURL) else { throw LicenseError.network }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["key": key, "hwid": deviceID]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)

        guard let http = resp as? HTTPURLResponse else { throw LicenseError.network }

        // 404 / 401 = invalid key
        if http.statusCode == 404 || http.statusCode == 401 || http.statusCode == 403 {
            return LicenseResponse(valid: false, status: "invalid", expires_at: nil, hwid: nil)
        }

        let decoded = try JSONDecoder().decode(LicenseResponse.self, from: data)
        return decoded
    }
}

enum LicenseError: Error {
    case network
    case invalid
}

// MARK: - Local session persistence
enum LicenseSession {
    private static let keyStoreKey    = "ffex_license_key"
    private static let expiryStoreKey = "ffex_license_expiry"

    static func save(key: String, expiry: String?) {
        UserDefaults.standard.set(key, forKey: keyStoreKey)
        UserDefaults.standard.set(expiry ?? "", forKey: expiryStoreKey)
    }

    static func savedKey() -> String? {
        UserDefaults.standard.string(forKey: keyStoreKey)
    }

    static func savedExpiry() -> String? {
        UserDefaults.standard.string(forKey: expiryStoreKey)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: keyStoreKey)
        UserDefaults.standard.removeObject(forKey: expiryStoreKey)
    }

    static func isExpired() -> Bool {
        guard let expiryStr = savedExpiry(), !expiryStr.isEmpty else { return false }
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = fmt.date(from: expiryStr) else { return false }
        return date < Date()
    }

    static func formattedExpiry() -> String {
        guard let raw = savedExpiry(), !raw.isEmpty else { return "—" }
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = fmt.date(from: raw) else { return raw }
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: date)
    }

    /// e.g. "FFEX-A1B2-****-****"
    static func maskedKey() -> String {
        guard let k = savedKey() else { return "" }
        let parts = k.split(separator: "-").map(String.init)
        guard parts.count >= 2 else { return k }
        let visible = parts.prefix(2).joined(separator: "-")
        let hidden  = parts.dropFirst(2).map { String(repeating: "*", count: $0.count) }.joined(separator: "-")
        return [visible, hidden].joined(separator: "-")
    }
}
