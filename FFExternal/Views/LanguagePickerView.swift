import SwiftUI

// MARK: - Initial onboarding language picker (shown before login)
struct LanguagePickerView: View {
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    @State private var selected: AppLanguage = .english
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            liquidGlassBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 60)

                // Wordmark
                VStack(spacing: 8) {
                    Text("FF External")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(red: 0.65, green: 0.75, blue: 1.0)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                    Text("Choose your language")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.28))
                        .kerning(0.3)
                }
                .padding(.bottom, 42)

                // Language card
                VStack(spacing: 0) {
                    Text(selected.t(L.selectLanguage))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.45))
                        .textCase(.uppercase)
                        .kerning(0.7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                        .padding(.bottom, 14)

                    Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)

                    ForEach(AppLanguage.allCases) { lang in
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                selected = lang
                            }
                        } label: {
                            HStack(spacing: 14) {
                                Text(lang.flagEmoji).font(.system(size: 22))
                                Text(lang.displayName)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                                Spacer()
                                if selected == lang {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.50, green: 0.65, blue: 1.0),
                                                    Color(red: 0.35, green: 0.22, blue: 0.92)
                                                ],
                                                startPoint: .topLeading, endPoint: .bottomTrailing
                                            )
                                        )
                                        .font(.system(size: 20, weight: .bold))
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)
                            .background(
                                selected == lang
                                    ? Color(red: 0.35, green: 0.22, blue: 0.92).opacity(0.12)
                                    : Color.clear
                            )
                            .animation(.easeInOut(duration: 0.15), value: selected)
                        }
                        .buttonStyle(.plain)

                        if lang != AppLanguage.allCases.last {
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 1)
                                .padding(.horizontal, 20)
                        }
                    }

                    Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1).padding(.top, 4)
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .padding(.horizontal, 22)

                // Continue button
                Button {
                    languageCode = selected.rawValue
                    withAnimation(.easeInOut(duration: 0.35)) { onContinue() }
                } label: {
                    HStack(spacing: 8) {
                        Text(selected.t(L.continueBtn))
                            .font(.system(size: 17, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.35, green: 0.22, blue: 0.92),
                                Color(red: 0.12, green: 0.50, blue: 0.95)
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .shadow(color: Color(red: 0.25, green: 0.30, blue: 0.90).opacity(0.45), radius: 12, y: 4)
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)

                Spacer(minLength: 50)
            }
        }
        .onAppear {
            selected = AppLanguage(rawValue: languageCode) ?? .english
        }
    }

    private var liquidGlassBackground: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.08)
            Ellipse()
                .fill(RadialGradient(
                    colors: [Color(red: 0.35, green: 0.20, blue: 0.90).opacity(0.48), .clear],
                    center: .center, startRadius: 0, endRadius: 210
                ))
                .frame(width: 380, height: 320).blur(radius: 75).offset(x: -70, y: -200)
            Ellipse()
                .fill(RadialGradient(
                    colors: [Color(red: 0.10, green: 0.50, blue: 0.95).opacity(0.35), .clear],
                    center: .center, startRadius: 0, endRadius: 180
                ))
                .frame(width: 300, height: 280).blur(radius: 65).offset(x: 100, y: 280)
        }
    }
}

// MARK: - Inline sheet language picker (post-login, from MainView)
struct InlineLanguagePickerView: View {
    @Binding var isPresented: Bool
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    @State private var selected: AppLanguage = .english

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.10).ignoresSafeArea()

            VStack(spacing: 0) {
                // Sheet handle
                Capsule()
                    .fill(Color.white.opacity(0.20))
                    .frame(width: 38, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 24)

                Text("Language")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.bottom, 24)

                VStack(spacing: 0) {
                    ForEach(AppLanguage.allCases) { lang in
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                selected = lang
                            }
                        } label: {
                            HStack(spacing: 14) {
                                Text(lang.flagEmoji).font(.system(size: 22))
                                Text(lang.displayName)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                                Spacer()
                                if selected == lang {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.50, green: 0.65, blue: 1.0),
                                                    Color(red: 0.35, green: 0.22, blue: 0.92)
                                                ],
                                                startPoint: .topLeading, endPoint: .bottomTrailing
                                            )
                                        )
                                        .font(.system(size: 20, weight: .bold))
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)
                            .background(
                                selected == lang
                                    ? Color(red: 0.35, green: 0.22, blue: 0.92).opacity(0.12)
                                    : Color.clear
                            )
                            .animation(.easeInOut(duration: 0.15), value: selected)
                        }
                        .buttonStyle(.plain)

                        if lang != AppLanguage.allCases.last {
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 1)
                                .padding(.horizontal: 20)
                        }
                    }
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .padding(.horizontal, 22)

                // Apply button
                Button {
                    languageCode = selected.rawValue
                    isPresented = false
                } label: {
                    Text("Apply")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.35, green: 0.22, blue: 0.92),
                                    Color(red: 0.12, green: 0.50, blue: 0.95)
                                ],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                        )
                        .shadow(color: Color(red: 0.25, green: 0.30, blue: 0.90).opacity(0.45), radius: 12, y: 4)
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            selected = AppLanguage(rawValue: languageCode) ?? .english
        }
    }
}
