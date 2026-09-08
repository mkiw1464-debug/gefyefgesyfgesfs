import SwiftUI

struct MainView: View {
    @Environment(\.appLanguage) private var language
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            glassBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top header
                headerBar
                    .padding(.top, safeTop)

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Key info card
                        keyInfoCard
                            .padding(.horizontal, 18)
                            .padding(.top, 20)
                            .padding(.bottom, 14)

                        // Tab switcher
                        tabSwitcher
                            .padding(.horizontal, 18)
                            .padding(.bottom, 16)

                        // Game menu
                        Group {
                            if selectedTab == 0 {
                                GameMenuView(game: .freeFire)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .leading).combined(with: .opacity),
                                        removal:   .move(edge: .trailing).combined(with: .opacity)
                                    ))
                            } else {
                                GameMenuView(game: .freeFireMax)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal:   .move(edge: .leading).combined(with: .opacity)
                                    ))
                            }
                        }
                        .animation(.spring(response: 0.38, dampingFraction: 0.84), value: selectedTab)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("FF External")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Free Fire Cheat Tool")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
            }

            Spacer()

            // Telegram link
            Link(destination: URL(string: "https://t.me/ffexternal")!) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.07), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 12)
    }

    // MARK: - Key info
    private var keyInfoCard: some View {
        HStack(spacing: 0) {
            infoCell(
                label: language.t(L.keyLabel),
                value: LicenseSession.maskedKey(),
                icon: "key.fill"
            )
            Divider().frame(height: 36).overlay(Color.white.opacity(0.10))
            infoCell(
                label: language.t(L.deviceLabel),
                value: LicenseService.deviceName,
                icon: "iphone"
            )
            Divider().frame(height: 36).overlay(Color.white.opacity(0.10))
            infoCell(
                label: language.t(L.expiresLabel),
                value: LicenseSession.formattedExpiry(),
                icon: "calendar"
            )
        }
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func infoCell(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.35))
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.35))
                .textCase(.uppercase)
                .kerning(0.5)
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.80))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tab switcher
    private var tabSwitcher: some View {
        HStack(spacing: 0) {
            tabButton(title: language.t(L.freeFire), icon: "flame.fill", index: 0)
            tabButton(title: language.t(L.freeFireMax), icon: "bolt.fill", index: 1)
        }
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func tabButton(title: String, icon: String, index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.80)) {
                selectedTab = index
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(selectedTab == index ? .black : .white.opacity(0.45))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(
                selectedTab == index
                    ? LinearGradient(
                        colors: [Color(white: 0.92), Color(white: 0.75)],
                        startPoint: .top, endPoint: .bottom
                    )
                    : LinearGradient(
                        colors: [Color.clear, Color.clear],
                        startPoint: .top, endPoint: .bottom
                    ),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .padding(3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Background
    private var glassBackground: some View {
        ZStack {
            Color(white: 0.07)
            Circle()
                .fill(Color(white: 0.15).opacity(0.30))
                .frame(width: 320).blur(radius: 90)
                .offset(x: -60, y: -280)
            Circle()
                .fill(Color(white: 0.11).opacity(0.25))
                .frame(width: 260).blur(radius: 80)
                .offset(x: 120, y: 320)
        }
    }

    private var safeTop: CGFloat {
        UIApplication.shared
            .connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first?.safeAreaInsets.top }
            .first ?? 44
    }
}
