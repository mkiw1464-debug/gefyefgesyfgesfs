import SwiftUI

struct LoginView: View {
    @Environment(\.appLanguage) private var language
    @State private var keyInput   : String = ""
    @State private var isValidating = false
    @State private var errorMsg   : String = ""
    @State private var showError  = false
    @State private var keyVisible = false
    let onSuccess: () -> Void

    var body: some View {
        ZStack {
            liquidGlassBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 70)

                    // App wordmark — no logo icon
                    VStack(spacing: 8) {
                        Text("FF External")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color(red: 0.65, green: 0.75, blue: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("v1.0  •  License Required")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.28))
                            .kerning(0.4)
                    }
                    .padding(.bottom, 48)

                    // License card
                    VStack(spacing: 0) {

                        // Header row
                        HStack {
                            Text(language.t(L.enterKey))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white.opacity(0.45))
                                .textCase(.uppercase)
                                .kerning(0.7)
                            Spacer()
                            Image(systemName: "key.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.30))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 14)

                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 1)

                        // Key input field
                        HStack(spacing: 10) {
                            Group {
                                if keyVisible {
                                    TextField("", text: $keyInput)
                                } else {
                                    SecureField("", text: $keyInput)
                                }
                            }
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .placeholder(when: keyInput.isEmpty) {
                                Text(language.t(L.keyPlaceholder))
                                    .foregroundStyle(.white.opacity(0.20))
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                            }

                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    keyVisible.toggle()
                                }
                            } label: {
                                Image(systemName: keyVisible ? "eye.slash.fill" : "eye.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.35))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)

                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 1)

                        // Device info
                        HStack(spacing: 8) {
                            Image(systemName: "iphone")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.35))
                            Text(LicenseService.deviceName)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white.opacity(0.55))
                            Spacer()
                            Text("iOS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white.opacity(0.30))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.08), in: Capsule())
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
                    .padding(.horizontal, 22)

                    // Error banner
                    if showError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(red: 1.0, green: 0.80, blue: 0.22))
                            Text(errorMsg)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            Color(red: 1.0, green: 0.55, blue: 0.10).opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(red: 1.0, green: 0.65, blue: 0.15).opacity(0.30), lineWidth: 1)
                        )
                        .padding(.horizontal, 22)
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
                                    ProgressView().tint(.white).controlSize(.small)
                                    Text(language.t(L.validating))
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.shield.fill")
                                        .font(.system(size: 16, weight: .bold))
                                    Text(language.t(L.validateKey))
                                        .font(.system(size: 17, weight: .bold))
                                }
                                .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                    .background(
    keyInput.isEmpty
        ? LinearGradient(
            colors: [Color.white.opacity(0.10), Color.white.opacity(0.07)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        : LinearGradient(
            colors: [
                Color(red: 0.35, green: 0.22, blue: 0.92),
                Color(red: 0.12, green: 0.50, blue: 0.95)
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        ),
    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
)
                        )
                        .shadow(
                            color: keyInput.isEmpty
                                ? .clear
                                : Color(red: 0.25, green: 0.30, blue: 0.90).opacity(0.50),
                            radius: 12, y: 4
                        )
                    }
                    .disabled(keyInput.trimmingCharacters(in: .whitespaces).isEmpty || isValidating)
                    .padding(.horizontal, 22)
                    .padding(.top, 20)

                    // Telegram
                    Link(destination: URL(string: "https://t.me/ffexternal")!) {
                        HStack(spacing: 6) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text(language.t(L.telegramJoin))
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(.white.opacity(0.32))
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 50)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.80), value: showError)
    }

    // MARK: - Validate
    private func validateKey() async {
        let trimmed = keyInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        await MainActor.run { isValidating = true; showError = false }

        do {
            let resp = try await LicenseService.validate(key: trimmed)
            await MainActor.run {
                isValidating = false
                if resp.valid && resp.status == "active" {
                    LicenseSession.save(key: trimmed, expiry: resp.expires_at)
                    onSuccess()
                } else {
                    errorMsg  = language.t(L.invalidKey)
                    showError = true
                }
            }
        } catch {
            await MainActor.run {
                isValidating = false
                errorMsg  = language.t(L.networkError)
                showError = true
            }
        }
    }

    // MARK: - Background
    private var liquidGlassBackground: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.08)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.35, green: 0.20, blue: 0.90).opacity(0.50), .clear],
                        center: .center, startRadius: 0, endRadius: 210
                    )
                )
                .frame(width: 400, height: 340)
                .blur(radius: 75)
                .offset(x: -90, y: -220)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.10, green: 0.50, blue: 0.95).opacity(0.38), .clear],
                        center: .center, startRadius: 0, endRadius: 180
                    )
                )
                .frame(width: 300, height: 280)
                .blur(radius: 65)
                .offset(x: 120, y: 310)
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
