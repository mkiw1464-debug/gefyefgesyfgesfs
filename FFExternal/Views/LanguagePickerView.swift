import SwiftUI

struct LanguagePickerView: View {
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    @State private var selected: AppLanguage = .english
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            glassBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo / title
                VStack(spacing: 10) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(white: 0.9), Color(white: 0.55)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .white.opacity(0.12), radius: 12)

                    Text("FF External")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(white: 0.95), Color(white: 0.60)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                // Language picker card
                VStack(spacing: 0) {
                    Text(selected.t(L.selectLanguage))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                        .padding(.bottom, 10)

                    Divider().overlay(Color.white.opacity(0.10))

                    ForEach(AppLanguage.allCases) { lang in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                selected = lang
                            }
                        } label: {
                            HStack(spacing: 14) {
                                Text(lang.flagEmoji)
                                    .font(.system(size: 22))
                                Text(lang.displayName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                                Spacer()
                                if selected == lang {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color(white: 0.75))
                                        .font(.system(size: 18, weight: .semibold))
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(
                                selected == lang
                                    ? Color.white.opacity(0.08)
                                    : Color.clear
                            )
                            .animation(.easeInOut(duration: 0.18), value: selected)
                        }
                        .buttonStyle(.plain)

                        if lang != AppLanguage.allCases.last {
                            Divider().overlay(Color.white.opacity(0.07)).padding(.horizontal, 20)
                        }
                    }

                    Divider().overlay(Color.white.opacity(0.10))
                        .padding(.bottom, 4)
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .padding(.horizontal, 24)

                // Continue button
                Button {
                    languageCode = selected.rawValue
                    withAnimation(.easeInOut(duration: 0.35)) { onContinue() }
                } label: {
                    Text(selected.t(L.continueBtn))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(white: 0.95), Color(white: 0.78)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                }
                .padding(.horizontal, 24)
                .shadow(color: .white.opacity(0.08), radius: 8, y: 4)

                Spacer()
            }
        }
        .onAppear {
            selected = AppLanguage(rawValue: languageCode) ?? .english
        }
    }

    private var glassBackground: some View {
        ZStack {
            Color(white: 0.07)
            // Subtle gradient orbs
            Circle()
                .fill(Color(white: 0.18).opacity(0.35))
                .frame(width: 320)
                .blur(radius: 80)
                .offset(x: -60, y: -180)
            Circle()
                .fill(Color(white: 0.14).opacity(0.25))
                .frame(width: 260)
                .blur(radius: 80)
                .offset(x: 100, y: 260)
        }
    }
}
