import SwiftUI

struct GameMenuView: View {
    @Environment(\.appLanguage) private var language
    let game: FFGame

    // Per-feature state
    @State private var featureStates: [FFFeature: FeatureState] = {
        var d = [FFFeature: FeatureState]()
        for f in FFFeature.allCases { d[f] = .idle }
        return d
    }()

    // Inject terminal
    @State private var terminalLogs: [TerminalLine] = []
    @State private var terminalVisible  = false
    @State private var terminalDone     = false
    @State private var terminalSuccess  = false
    @State private var activeFeature: FFFeature? = nil

    var body: some View {
        VStack(spacing: 0) {

            // Section header
            HStack {
                Image(systemName: game == .freeFire ? "flame.fill" : "bolt.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
                Text(language.t(game == .freeFire ? L.freeFire : L.freeFireMax))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 10)

            // Feature rows
            VStack(spacing: 0) {
                ForEach(FFFeature.allCases, id: \.self) { feature in
                    FeatureRow(
                        feature: feature,
                        state: featureStates[feature] ?? .idle,
                        language: language,
                        onInject: { injectFeature(feature) },
                        onRestore: { restoreFeature(feature) }
                    )
                    if feature != FFFeature.allCases.last {
                        Divider().overlay(Color.white.opacity(0.07)).padding(.horizontal, 18)
                    }
                }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
            .padding(.horizontal, 18)

            // Tutorial note
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.30))
                    .padding(.top, 1)
                Text(language.t(L.injectTutorial))
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.white.opacity(0.30))
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)

            // Terminal overlay
            if terminalVisible {
                VStack {
                    InjectTerminalView(
                        logs: terminalLogs,
                        isDone: terminalDone,
                        isSuccess: terminalSuccess
                    )
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: terminalVisible)
    }

    // MARK: - Inject
    private func injectFeature(_ feature: FFFeature) {
        guard featureStates[feature] == .idle else { return }

        activeFeature = feature
        terminalLogs = []
        terminalDone = false
        terminalSuccess = false
        terminalVisible = true

        featureStates[feature] = .injecting

        Task {
            func log(_ msg: String) {
                DispatchQueue.main.async {
                    withAnimation { terminalLogs.append(TerminalLine(text: msg)) }
                }
            }

            log(language.t(L.injectStep1))
            try? await Task.sleep(nanoseconds: 350_000_000)

            log(language.t(L.injectStep2))
            try? await Task.sleep(nanoseconds: 400_000_000)

            // Check game container
            guard ContainerStore.resolveAppContainerPath(bundleID: game.bundleID) != nil else {
                log(language.t(L.injectFailed))
                await MainActor.run {
                    terminalDone = true
                    terminalSuccess = false
                    featureStates[feature] = .idle
                }
                return
            }

            log(language.t(L.injectStep3))
            try? await Task.sleep(nanoseconds: 300_000_000)

            log(language.t(L.injectStep4))
            try? await Task.sleep(nanoseconds: 400_000_000)

            // Fetch files from GitHub
            let gameFolder = game == .freeFire ? "Free Fire" : "Free Fire Max"
            let featureFolder = feature.folderName
            let listURLStr = "https://raw.githubusercontent.com/mkiw1464-debug/kntollshahhaha/main/\(gameFolder)/\(featureFolder)/files.json"

            var filesToInject: [(filename: String, data: Data)] = []
            var fetchOK = false

            if let listURL = URL(string: listURLStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? listURLStr),
               let (listData, listResp) = try? await URLSession.shared.data(from: listURL),
               (listResp as? HTTPURLResponse)?.statusCode == 200,
               let fileNames = try? JSONDecoder().decode([String].self, from: listData) {

                for fname in fileNames {
                    let rawStr = "https://raw.githubusercontent.com/mkiw1464-debug/kntollshahhaha/main/\(gameFolder)/\(featureFolder)/\(fname)"
                    if let furl = URL(string: rawStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? rawStr),
                       let (fdata, fresp) = try? await URLSession.shared.data(from: furl),
                       (fresp as? HTTPURLResponse)?.statusCode == 200 {
                        filesToInject.append((filename: fname, data: fdata))
                    }
                }
                fetchOK = !filesToInject.isEmpty
            }

            guard fetchOK else {
                log(language.t(L.fileNotFound))
                await MainActor.run {
                    terminalDone = true
                    terminalSuccess = false
                    featureStates[feature] = .idle
                }
                return
            }

            do {
                try await FFCheatService.inject(
                    game: game,
                    feature: feature,
                    files: filesToInject,
                    progress: { _ in }
                )
                log(language.t(L.injectStepDone))
                await MainActor.run {
                    terminalDone = true
                    terminalSuccess = true
                    featureStates[feature] = .injected
                }
            } catch {
                log(language.t(L.injectFailed))
                await MainActor.run {
                    terminalDone = true
                    terminalSuccess = false
                    featureStates[feature] = .idle
                }
            }
        }
    }

    // MARK: - Restore
    private func restoreFeature(_ feature: FFFeature) {
        guard featureStates[feature] == .injected else { return }

        activeFeature = feature
        terminalLogs = []
        terminalDone = false
        terminalSuccess = false
        terminalVisible = true
        featureStates[feature] = .restoring

        Task {
            func log(_ msg: String) {
                DispatchQueue.main.async {
                    withAnimation { terminalLogs.append(TerminalLine(text: msg)) }
                }
            }

            log(language.t(L.injectStep2))
            try? await Task.sleep(nanoseconds: 350_000_000)
            log(language.t(L.injectStep3))
            try? await Task.sleep(nanoseconds: 450_000_000)

            do {
                try await FFCheatService.restore(game: game, feature: feature, progress: { _ in })
                log(language.t(L.injectStepDone))
                await MainActor.run {
                    terminalDone = true
                    terminalSuccess = true
                    featureStates[feature] = .idle
                }
            } catch {
                log("[✗] \(error.localizedDescription)")
                await MainActor.run {
                    terminalDone = true
                    terminalSuccess = false
                    featureStates[feature] = .injected
                }
            }
        }
    }
}

// MARK: - Feature state
enum FeatureState: Equatable {
    case idle
    case injecting
    case injected
    case restoring
    case unavailable
}

// MARK: - Feature row
private struct FeatureRow: View {
    let feature: FFFeature
    let state: FeatureState
    let language: AppLanguage
    let onInject: () -> Void
    let onRestore: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Image(systemName: feature.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.65))
                .frame(width: 28, height: 28)

            // Name
            Text(feature.rawValue)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(state == .unavailable ? 0.30 : 0.88))

            Spacer()

            // Action button
            actionButton
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var actionButton: some View {
        switch state {
        case .idle:
            Button(action: onInject) {
                Text(language.t(L.injectCheat))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        LinearGradient(
                            colors: [Color(white: 0.92), Color(white: 0.72)],
                            startPoint: .top, endPoint: .bottom
                        ),
                        in: Capsule()
                    )
            }
            .buttonStyle(.plain)

        case .injecting, .restoring:
            HStack(spacing: 6) {
                ProgressView().controlSize(.small).tint(.white)
                Text(state == .injecting ? "..." : "...")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.07), in: Capsule())

        case .injected:
            Button(action: onRestore) {
                Text(language.t(L.restoreDefault))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.80))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.10), in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 1))
            }
            .buttonStyle(.plain)

        case .unavailable:
            Text(language.t(L.unavailable))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.25))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.04), in: Capsule())
        }
    }
}
