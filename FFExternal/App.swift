import SwiftUI
import UIKit

@main
struct FFExternalApp: App {
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    @StateObject private var appState = AppState()
    @State private var flowStep: FlowStep = .language

    private var language: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .english
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(red: 0.04, green: 0.04, blue: 0.08).ignoresSafeArea()

                switch flowStep {
                case .language:
                    LanguagePickerView {
                        withAnimation(.easeInOut(duration: 0.40)) {
                            flowStep = .login
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    .zIndex(3)

                case .login:
                    LoginView {
                        withAnimation(.easeInOut(duration: 0.40)) {
                            flowStep = .main
                        }
                    }
                    .environment(\.appLanguage, language)
                    .environmentObject(appState)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    .zIndex(2)

                case .main:
                    MainView()
                        .environment(\.appLanguage, language)
                        .environmentObject(appState)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                        .zIndex(1)
                }
            }
            .animation(.spring(response: 0.42, dampingFraction: 0.88), value: flowStep)
            .onAppear {
                if !LicenseSession.isExpired(), LicenseSession.savedKey() != nil {
                    flowStep = .main
                } else {
                    flowStep = .language
                }
                appState.detectSupport()
            }
            .onReceive(NotificationCenter.default.publisher(for: .ffexLogout)) { _ in
                withAnimation(.easeInOut(duration: 0.40)) {
                    flowStep = .language
                }
            }
        }
    }
}

enum FlowStep: Equatable {
    case language
    case login
    case main
}

// MARK: - AppState
class AppState: ObservableObject {
    @Published var exploitStatus: ExploitStatus = .notStarted
    @Published var kernelExploitRunning = false
    private var autoRunAttempted = false

    var kernelExploitApplicable: Bool {
        KernelExploit.isApplicable(
            major: AppInfo.versionTuple.major,
            minor: AppInfo.versionTuple.minor,
            patch: AppInfo.versionTuple.patch,
            build: AppInfo.osBuild
        )
    }

    func detectSupport() {
        let v = AppInfo.versionTuple
        let supported = ExploitSupportPolicy.isSupported(
            major: v.major, minor: v.minor, patch: v.patch, build: AppInfo.osBuild
        )
        if !supported {
            exploitStatus = .unsupported("iOS \(AppInfo.osVersion)")
            return
        }
        let applicable = KernelExploit.isApplicable(
            major: v.major, minor: v.minor, patch: v.patch, build: AppInfo.osBuild
        )
        guard applicable else { return }

        if KernelExploit.requiresSandboxEscape, KernelExploit.hasSandboxAccess() {
            exploitStatus = .success(method: "kexploit")
        }

        guard !autoRunAttempted else { return }
        autoRunAttempted = true
        runKernelExploit()
    }

    func runKernelExploit() {
        guard !kernelExploitRunning, !exploitStatus.isSuccess, !exploitStatus.isFailed else { return }
        kernelExploitRunning = true
        DispatchQueue.global(qos: .userInitiated).async {
            let ok = KernelExploit.run()
            DispatchQueue.main.async {
                self.kernelExploitRunning = false
                self.exploitStatus = ok
                    ? .success(method: "kexploit")
                    : .failed(method: "kexploit", code: -1)
            }
        }
    }
}
