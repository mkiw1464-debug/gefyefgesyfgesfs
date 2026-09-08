import SwiftUI

struct LoginView: View {
    @Environment(\.appLanguage) private var language
    @State private var keyInput: String = ""
    @State private var isValidating = false
    @State private var errorMsg: String = ""
    @State private var showError = false
    let onSuccess: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            glassBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)

                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 54, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(white: 0.92), Color(white: 0.50)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .shadow(color: .white.opacity(0.10), radius: 14)
                            .padding(.bottom, 2)

                        Text("FF External")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color(white: 0.60)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )

                        Text("v1.0")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.30))
                    }
                    .padding(.bottom, 40)

                    // License card
                    VStack(spacing: 0) {
                        Text(language.t(L.enterKey))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.50))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 18)
                            .padding(.bottom, 10)

                        Divider().overlay(Color.white.opacity(0.08))

                        // Key text field
                        HStack(spacing: 12) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.40))

                            TextField("", text: $keyInput)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.characters)
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white)
                                .placeholder(when: keyInput.isEmpty) {
                                    Text(language.t(L.keyPlaceholder))
                                        .foregroundStyle(.white.opacity(0.25))
                                        .font(.system(size: 15, design: .monospaced))
                                }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)

                        Divider().overlay(Color.white.opacity(0.08))

                        // Device info row
                        HStack(spacing: 8) {
                            Image(systemName: "iphone")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.35))
                            Text(LicenseService.deviceName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.55))
                            Spacer()
                            Text("iOS")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.25))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.07), in: Capsule())
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.11), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)

                    // Error
                    if showError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                            Text(errorMsg)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(Color(white: 0.85))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)
                        .padding(.top, 14)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Validate button
                    Button {
                        Task { await validateKey() }
                    } label: {
                        ZStack {
                            if isValidating {
                                HStack(spacing: 10) {
                                    ProgressView()
                                        .tint(.black)
                                        .controlSize(.small)
                                    Text(language.t(L.validating))
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(.black)
                                }
                            } else {
                                Text(language.t(L.validateKey))
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: keyInput.isEmpty
                                    ? [Color(white: 0.40), Color(white: 0.30)]
                                    : [Color(white: 0.95), Color(white: 0.78)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                    }
                    .disabled(keyInput.trimmingCharacters(in: .whitespaces).isEmpty || isValidating)
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                    .shadow(color: .white.opacity(0.07), radius: 8, y: 4)

                    // Telegram link
                    Link(destination: URL(string: "https://t.me/ffexternal")!) {
                        HStack(spacing: 6) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 12))
                            Text(language.t(L.telegramJoin))
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(.white.opacity(0.40))
                    }
                    .padding(.top, 22)
                    .padding(.bottom, 40)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.80), value: showError)
    }

    // MARK: - Validate
    private func validateKey() async {
        let trimmed = keyInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        await MainActor.run {
            isValidating = true
            showError = false
        }

        do {
            let resp = try await LicenseService.validate(key: trimmed)
            await MainActor.run {
                isValidating = false
                if resp.valid && resp.status == "active" {
                    LicenseSession.save(key: trimmed, expiry: resp.expires_at)
                    onSuccess()
                } else {
                    errorMsg = language.t(L.invalidKey)
                    showError = true
                }
            }
        } catch {
            await MainActor.run {
                isValidating = false
                errorMsg = language.t(L.networkError)
                showError = true
            }
        }
    }

    private var glassBackground: some View {
        ZStack {
            Color(white: 0.07)
            Circle()
                .fill(Color(white: 0.16).opacity(0.35))
                .frame(width: 300).blur(radius: 80)
                .offset(x: -80, y: -200)
            Circle()
                .fill(Color(white: 0.12).opacity(0.28))
                .frame(width: 250).blur(radius: 80)
                .offset(x: 110, y: 280)
        }
    }
}

// MARK: - Placeholder helper
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: .leading) {
            if shouldShow { placeholder() }
            self
        }
    }
}
