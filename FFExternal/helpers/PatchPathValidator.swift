import Foundation

enum PatchPathValidator {
    enum ValidationError: Error { case invalidBundleIdentifier }
    static func canonicalBundleIdentifier(_ value: String) throws -> String {
        let s = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard s == value, !s.isEmpty else { throw ValidationError.invalidBundleIdentifier }
        let parts = s.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count >= 2 else { throw ValidationError.invalidBundleIdentifier }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        guard parts.allSatisfy({ !$0.isEmpty && $0.first?.isNumber != true && $0.unicodeScalars.allSatisfy(allowed.contains) }) else {
            throw ValidationError.invalidBundleIdentifier
        }
        return s
    }
}
