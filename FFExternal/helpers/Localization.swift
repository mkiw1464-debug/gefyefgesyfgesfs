import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    static let storageKey = "ffex_appLanguage"

    case english   = "en"
    case indonesia = "id"
    case brazil    = "pt-BR"
    case vietnam   = "vi"
    case taiwan    = "zh-TW"

    var id: String { rawValue }
    var locale: Locale { Locale(identifier: rawValue) }

    var displayName: String {
        switch self {
        case .english:   return "English"
        case .indonesia: return "Indonesia"
        case .brazil:    return "Português (BR)"
        case .vietnam:   return "Tiếng Việt"
        case .taiwan:    return "繁體中文"
        }
    }

    var flagEmoji: String {
        switch self {
        case .english:   return "🇬🇧"
        case .indonesia: return "🇮🇩"
        case .brazil:    return "🇧🇷"
        case .vietnam:   return "🇻🇳"
        case .taiwan:    return "🇹🇼"
        }
    }

    // MARK: - Strings
    func t(_ key: LocalizedKey) -> String {
        switch self {
        case .english:   return key.en
        case .indonesia: return key.id
        case .brazil:    return key.ptBR
        case .vietnam:   return key.vi
        case .taiwan:    return key.zhTW
        }
    }

    func text(_ key: String) -> String {
        switch key {
        case "attribution.subtitle": return [
            .english: "Display Identity Attribution", .indonesia: "Atribusi Identitas Tampilan",
            .brazil: "Atribuição de Identidade de Exibição", .vietnam: "Ghi công danh tính hiển thị",
            .taiwan: "顯示身分資訊"
        ][self] ?? "Display Identity Attribution"
        case "attribution.link_section": return [
            .english: "Link", .indonesia: "Tautan", .brazil: "Link", .vietnam: "Liên kết", .taiwan: "連結"
        ][self] ?? "Link"
        case "attribution.url": return [
            .english: "URL", .indonesia: "URL", .brazil: "URL", .vietnam: "URL", .taiwan: "網址"
        ][self] ?? "URL"
        case "attribution.open": return [
            .english: "Open", .indonesia: "Buka", .brazil: "Abrir", .vietnam: "Mở", .taiwan: "開啟"
        ][self] ?? "Open"
        case "attribution.share": return [
            .english: "Share", .indonesia: "Bagikan", .brazil: "Compartilhar", .vietnam: "Chia sẻ", .taiwan: "分享"
        ][self] ?? "Share"
        case "attribution.title": return [
            .english: "Attribution", .indonesia: "Atribusi", .brazil: "Atribuição", .vietnam: "Ghi công", .taiwan: "資訊"
        ][self] ?? "Attribution"
        case "common.close": return [
            .english: "Close", .indonesia: "Tutup", .brazil: "Fechar", .vietnam: "Đóng", .taiwan: "關閉"
        ][self] ?? "Close"
        default: return key
        }
    }
}

struct LocalizedKey {
    let en:   String
    let id:   String
    let ptBR: String
    let vi:   String
    let zhTW: String
}

// MARK: - All app strings
enum L {
    // Language picker
    static let selectLanguage = LocalizedKey(
        en:   "Select Language",
        id:   "Pilih Bahasa",
        ptBR: "Selecionar Idioma",
        vi:   "Chọn Ngôn Ngữ",
        zhTW: "選擇語言"
    )
    static let continueBtn = LocalizedKey(
        en:   "Continue",
        id:   "Lanjutkan",
        ptBR: "Continuar",
        vi:   "Tiếp tục",
        zhTW: "繼續"
    )

    // Login
    static let loginTitle = LocalizedKey(
        en:   "FF External",
        id:   "FF External",
        ptBR: "FF External",
        vi:   "FF External",
        zhTW: "FF External"
    )
    static let enterKey = LocalizedKey(
        en:   "Enter License Key",
        id:   "Masukkan License Key",
        ptBR: "Inserir Chave de Licença",
        vi:   "Nhập License Key",
        zhTW: "輸入授權金鑰"
    )
    static let keyPlaceholder = LocalizedKey(
        en:   "FFEX-XXXX-XXXX-XXXX",
        id:   "FFEX-XXXX-XXXX-XXXX",
        ptBR: "FFEX-XXXX-XXXX-XXXX",
        vi:   "FFEX-XXXX-XXXX-XXXX",
        zhTW: "FFEX-XXXX-XXXX-XXXX"
    )
    static let validateKey = LocalizedKey(
        en:   "Validate Key",
        id:   "Validasi Key",
        ptBR: "Validar Chave",
        vi:   "Xác thực Key",
        zhTW: "驗證金鑰"
    )
    static let validating = LocalizedKey(
        en:   "Validating...",
        id:   "Memvalidasi...",
        ptBR: "Validando...",
        vi:   "Đang xác thực...",
        zhTW: "驗證中..."
    )
    static let invalidKey = LocalizedKey(
        en:   "Invalid or expired key",
        id:   "Key tidak valid atau sudah expired",
        ptBR: "Chave inválida ou expirada",
        vi:   "Key không hợp lệ hoặc đã hết hạn",
        zhTW: "金鑰無效或已過期"
    )
    static let networkError = LocalizedKey(
        en:   "Network error. Try again.",
        id:   "Error jaringan. Coba lagi.",
        ptBR: "Erro de rede. Tente novamente.",
        vi:   "Lỗi mạng. Thử lại.",
        zhTW: "網路錯誤，請重試。"
    )
    static let keyLabel = LocalizedKey(
        en:   "Key",
        id:   "Key",
        ptBR: "Chave",
        vi:   "Key",
        zhTW: "金鑰"
    )
    static let deviceLabel = LocalizedKey(
        en:   "Device",
        id:   "Perangkat",
        ptBR: "Dispositivo",
        vi:   "Thiết bị",
        zhTW: "裝置"
    )
    static let expiresLabel = LocalizedKey(
        en:   "Expires",
        id:   "Kedaluwarsa",
        ptBR: "Expira",
        vi:   "Hết hạn",
        zhTW: "到期日"
    )
    static let telegramJoin = LocalizedKey(
        en:   "Join Telegram for updates",
        id:   "Gabung Telegram untuk update",
        ptBR: "Entre no Telegram para atualizações",
        vi:   "Tham gia Telegram để cập nhật",
        zhTW: "加入 Telegram 獲取更新"
    )

    // Main menu
    static let freeFire = LocalizedKey(
        en:   "Free Fire",
        id:   "Free Fire",
        ptBR: "Free Fire",
        vi:   "Free Fire",
        zhTW: "Free Fire"
    )
    static let freeFireMax = LocalizedKey(
        en:   "Free Fire MAX",
        id:   "Free Fire MAX",
        ptBR: "Free Fire MAX",
        vi:   "Free Fire MAX",
        zhTW: "Free Fire MAX"
    )
    static let injectCheat = LocalizedKey(
        en:   "Inject Cheat",
        id:   "Inject Cheat",
        ptBR: "Injetar Cheat",
        vi:   "Chèn Cheat",
        zhTW: "注入外掛"
    )
    static let restoreDefault = LocalizedKey(
        en:   "Restore Default",
        id:   "Restore Default",
        ptBR: "Restaurar Padrão",
        vi:   "Khôi phục mặc định",
        zhTW: "恢復預設"
    )
    static let injected = LocalizedKey(
        en:   "Injected!",
        id:   "Berhasil Inject!",
        ptBR: "Injetado!",
        vi:   "Đã chèn!",
        zhTW: "已注入！"
    )
    static let restored = LocalizedKey(
        en:   "Restored!",
        id:   "Berhasil Restore!",
        ptBR: "Restaurado!",
        vi:   "Đã khôi phục!",
        zhTW: "已恢復！"
    )
    static let unavailable = LocalizedKey(
        en:   "Unavailable",
        id:   "Tidak Tersedia",
        ptBR: "Indisponível",
        vi:   "Không khả dụng",
        zhTW: "不可用"
    )
    static let injectTutorial = LocalizedKey(
        en:   "Inject features while in lobby, and turn off before entering the game",
        id:   "Inject features while in lobby, and turn off before entering the game",
        ptBR: "Inject features while in lobby, and turn off before entering the game",
        vi:   "Inject features while in lobby, and turn off before entering the game",
        zhTW: "Inject features while in lobby, and turn off before entering the game"
    )

    // Inject terminal steps
    static let injectStep1 = LocalizedKey(
        en:   "[*] Initializing exploit access...",
        id:   "[*] Initializing exploit access...",
        ptBR: "[*] Initializing exploit access...",
        vi:   "[*] Initializing exploit access...",
        zhTW: "[*] Initializing exploit access..."
    )
    static let injectStep2 = LocalizedKey(
        en:   "[*] Locating game container...",
        id:   "[*] Locating game container...",
        ptBR: "[*] Locating game container...",
        vi:   "[*] Locating game container...",
        zhTW: "[*] Locating game container..."
    )
    static let injectStep3 = LocalizedKey(
        en:   "[*] Backing up original files...",
        id:   "[*] Backing up original files...",
        ptBR: "[*] Backing up original files...",
        vi:   "[*] Backing up original files...",
        zhTW: "[*] Backing up original files..."
    )
    static let injectStep4 = LocalizedKey(
        en:   "[*] Writing cheat assets...",
        id:   "[*] Writing cheat assets...",
        ptBR: "[*] Writing cheat assets...",
        vi:   "[*] Writing cheat assets...",
        zhTW: "[*] Writing cheat assets..."
    )
    static let injectStepDone = LocalizedKey(
        en:   "[✓] Done!",
        id:   "[✓] Done!",
        ptBR: "[✓] Done!",
        vi:   "[✓] Done!",
        zhTW: "[✓] Done!"
    )
    static let injectFailed = LocalizedKey(
        en:   "[✗] Inject failed. Game not installed?",
        id:   "[✗] Inject gagal. Game tidak terinstall?",
        ptBR: "[✗] Injeção falhou. Jogo não instalado?",
        vi:   "[✗] Chèn thất bại. Game chưa cài?",
        zhTW: "[✗] 注入失敗，遊戲未安裝？"
    )
    static let fileNotFound = LocalizedKey(
        en:   "[!] File not found on server.",
        id:   "[!] File tidak ditemukan di server.",
        ptBR: "[!] Arquivo não encontrado no servidor.",
        vi:   "[!] Không tìm thấy file trên server.",
        zhTW: "[!] 伺服器找不到檔案。"
    )
}

// MARK: - Environment key
private struct LanguageEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppLanguage.english
}
extension EnvironmentValues {
    var appLanguage: AppLanguage {
        get { self[LanguageEnvironmentKey.self] }
        set { self[LanguageEnvironmentKey.self] = newValue }
    }
}
