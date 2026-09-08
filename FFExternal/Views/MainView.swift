import SwiftUI

struct MainView: View {
    @Environment(\.appLanguage) private var language
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    @State private var selectedTab = 0
    @State private var showLogout = false
    @State private var showLanguagePicker = false
    @State private var hasSource: Bool? = nil  // nil = checking

    var body: some View {
        ZStack {
            liquidGlassBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                    .padding(.top, safeTop)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        keyInfoCard
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                            .padding(.bottom, 14)

                        tabSwitcher
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)

                        Group {
                            if selectedTab == 0 {
                                GameMenuView(game: .freeFire, hasSource: hasSource)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .leading).combined(with: .opacity),
                                        removal:   .move(edge: .trailing).combined(with: .opacity)
                                    ))
                            } else {
                                GameMenuView(game: .freeFireMax, hasSource: hasSource)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal:   .move(edge: .leading).combined(with: .opacity)
                                    ))
                            }
                        }
                        .animation(.spring(response: 0.38, dampingFraction: 0.84), value: selectedTab)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .task { await checkSourceAvailability() }
        .confirmationDialog(language.t(L.logoutConfirm), isPresented: $showLogout, titleVisibility: .visible) {
            Button(language.t(L.logoutBtn), role: .destructive) {
                LicenseSession.clear()
                // App will re-detect on next launch; force restart flow via notification
                NotificationCenter.default.post(name: .ffexLogout, object: nil)
            }
            Button(language.t(L.cancelBtn), role: .cancel) {}
        }
        .sheet(isPresented: $showLanguagePicker) {
            InlineLanguagePickerView(isPresented: $showLanguagePicker)
        }
    }

    // MARK: - Source check
    private func checkSourceAvailability() async {
        // Check if ANY feature folder for freeFire has files
        let feature = FFFeature.aimBody
        let exists = await FFCheatService.checkSourceAvailable(game: .freeFire, feature: feature)
        await MainActor.run { hasSource = exists }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("FF External")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text(language.t(L.headerSubtitle))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.40))
                    .kerning(0.3)
            }

            Spacer()

            // Language toggle
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    showLanguagePicker = true
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "globe")
                        .font(.system(size: 13, weight: .semibold))
                    Text(currentLanguage.flagEmoji)
                        .font(.system(size: 14))
                }
                .foregroundStyle(.white.opacity(0.75))
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
            }
            .buttonStyle(.plain)

            // Telegram
            Link(destination: URL(string: "https://t.me/ffexternal")!) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.70))
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
            }

            // Logout
            Button {
                showLogout = true
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private var currentLanguage: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .english
    }

    // MARK: - Key info card
    private var keyInfoCard: some View {
        HStack(spacing: 0) {
            infoCell(label: language.t(L.keyLabel), value: LicenseSession.maskedKey(), icon: "key.fill")
            glassVDivider
            infoCell(label: language.t(L.deviceLabel), value: LicenseService.deviceName, icon: "iphone")
            glassVDivider
            infoCell(label: language.t(L.expiresLabel), value: LicenseSession.formattedExpiry(), icon: "calendar")
        }
        .padding(.vertical, 16)
        .background(glassCard)
    }

    private var glassVDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.10))
            .frame(width: 1, height: 40)
    }

    private func infoCell(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.40))
                .textCase(.uppercase)
                .kerning(0.6)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tab switcher
    private var tabSwitcher: some View {
        HStack(spacing: 0) {
            tabButton(title: language.t(L.freeFire), index: 0)
            tabButton(title: language.t(L.freeFireMax), index: 1)
        }
        .padding(4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func tabButton(title: String, index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
                selectedTab = index
            }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(selectedTab == index ? .black : .white.opacity(0.50))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if selectedTab == index {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.92))
                                .shadow(color: .white.opacity(0.25), radius: 6, y: 2)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Liquid glass background (iOS 26 style)
    private var liquidGlassBackground: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.08)

            // Primary orb — violet/blue tint
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.35, green: 0.20, blue: 0.90).opacity(0.45), .clear],
                        center: .center, startRadius: 0, endRadius: 200
                    )
                )
                .frame(width: 380, height: 320)
                .blur(radius: 70)
                .offset(x: -80, y: -260)

            // Secondary orb — cyan
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.10, green: 0.50, blue: 0.95).opacity(0.35), .clear],
                        center: .center, startRadius: 0, endRadius: 180
                    )
                )
                .frame(width: 300, height: 280)
                .blur(radius: 65)
                .offset(x: 130, y: 300)

            // Subtle noise texture via thin overlay
            Color.white.opacity(0.015)
                .blendMode(.overlay)
        }
    }

    // MARK: - Glass card modifier
    private var glassCard: some ShapeStyle {
        AnyShapeStyle(
            .ultraThinMaterial
        )
    }

    private var safeTop: CGFloat {
        UIApplication.shared
            .connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first?.safeAreaInsets.top }
            .first ?? 50
    }
}

// MARK: - Glass card ViewModifier helper
private extension View {
    func glassCardStyle(cornerRadius: CGFloat = 20) -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
    }
}

// MARK: - Notification
extension Notification.Name {
    static let ffexLogout = Notification.Name("ffex.logout")
}
