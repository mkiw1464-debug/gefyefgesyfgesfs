import SwiftUI

struct GameMenuView: View {
    @Environment(\.appLanguage) private var language
    let game: FFGame
    let hasSource: Bool?   // nil = still checking

    @State private var featureStates: [FFFeature: FeatureState] = {
        var d = [FFFeature: FeatureState]()
        for f in FFFeature.allCases { d[f] = .idle }
        return d
    }()

    @State private var terminalLogs: [TerminalLine] = []
    @State private var terminalVisible  = false
    @State private var terminalDone     = false
    @State private var terminalSuccess  = false
    @State private var activeFeature: FFFeature? = nil

    var body: some View {
        VStack(spacing: 0) {

            // Section header
            HStack(spacing: 10) {
                Text(language.t(game == .freeFire ? L.freeFire : L.freeFireMax))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.55))
                    .textCase(.uppercase)
                    .kerning(0.8)
                Spacer()

                if hasSource == nil {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(.white.opacity(0.40))
                } else if hasSource == false {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.35, blue: 0.35))
                            .frame(width: 6, height: 6)
                        Text("Source Offline")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.45))
                    }
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(red: 0.25, green: 0.92, blue: 0.55))
                            .frame(width: 6, height: 6)
                        Text("Source Online")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(red: 0.25, green: 0.92, blue: 0.55))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 10)

            // Feature rows
            VStack(spacing: 0) {
                ForEach(FFFeature.allCases, id: \.self) { feature in
                    let effectiveState: FeatureState = (hasSource == false) ? .unavailable : (featureStates[feature] ?? .idle)
                    FeatureRow(
                        feature: feature,
                        state: effectiveState,
                        language: language,
                        onInject: { injectFeature(feature) },
                        onRestore: { restoreFeature(feature) }
                    )
                    if feature != FFFeature.allCases.last {
                        Rectangle()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 1)
                            .padding(.horizontal, 18)
                    }
                }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .padding(.horizontal, 16)

            // Tutorial note
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.25))
                    .padding(.top, 1)
                Text(language.t(L.injectTutorial))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.28))
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 22)
            .padding(.top, 10)

            // Terminal
            if terminalVisible {
                InjectTerminalView(
                    logs: terminalLogs,
                    isDone: terminalDone,
                    isSuccess: terminalSuccess
                )
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: terminalVisible)
    }

    // MARK: - Inject
    private func injectFeature(_ feature: FFFeature) {
        guard featureStates[feature] == .idle, hasSource == true else { return }

        activeFeature = feature
        terminalLogs = []
        terminalDone = false
        terminalSuccess = false
        terminalVisible = true
        featureStates[feature] = .injecting

        Task {
            func log(_ msg: String, type: TerminalLineType = .info) {
                DispatchQueue.main.async {
                    withAnimation { terminalLogs.append(TerminalLine(text: msg, type: type)) }
                }
            }

            log(language.t(L.injectStep1))
            try? await Task.sleep(nanoseconds: 350_000_000)
            log(language.t(L.injectStep2))
            try? await Task.sleep(nanoseconds: 400_000_000)

            guard ContainerStore.resolveAppContainerPath(bundleID: game.bundleID) != nil else {
                log(language.t(L.injectFailed), type: .error)
                await MainActor.run {
                    terminalDone = true; terminalSuccess = false
                    featureStates[feature] = .idle
                }
                return
            }

            log(language.t(L.injectStep3))
            try? await Task.sleep(nanoseconds: 300_000_000)
            log(language.t(L.injectStep4))
            try? await Task.sleep(nanoseconds: 400_000_000)

            let gameFolder    = game == .freeFire ? "Free Fire" : "Free Fire Max"
            let featureFolder = feature.folderName
            // Folder-based: looks for files.json listing filenames inside the folder
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
                log(language.t(L.fileNotFound), type: .warning)
                await MainActor.run {
                    terminalDone = true; terminalSuccess = false
                    featureStates[feature] = .idle
                }
                return
            }

            do {
                try await FFCheatService.inject(game: game, feature: feature, files: filesToInject, progress: { _ in })
                log(language.t(L.injectStepDone), type: .success)
                await MainActor.run {
                    terminalDone = true; terminalSuccess = true
                    featureStates[feature] = .injected
                }
            } catch {
                log(language.t(L.injectFailed), type: .error)
                await MainActor.run {
                    terminalDone = true; terminalSuccess = false
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
            func log(_ msg: String, type: TerminalLineType = .info) {
                DispatchQueue.main.async {
                    withAnimation { terminalLogs.append(TerminalLine(text: msg, type: type)) }
                }
            }

            log(language.t(L.injectStep2))
            try? await Task.sleep(nanoseconds: 350_000_000)
            log(language.t(L.injectStep3))
            try? await Task.sleep(nanoseconds: 450_000_000)

            do {
                try await FFCheatService.restore(game: game, feature: feature, progress: { _ in })
                log(language.t(L.injectStepDone), type: .success)
                await MainActor.run {
                    terminalDone = true; terminalSuccess = true
                    featureStates[feature] = .idle
                }
            } catch {
                log("[✗] \(error.localizedDescription)", type: .error)
                await MainActor.run {
                    terminalDone = true; terminalSuccess = false
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
            // Name only — no cheat symbol icons
            Text(feature.rawValue)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(state == .unavailable
                    ? .white.opacity(0.25)
                    : .white.opacity(0.90))

            Spacer()

            actionButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
    }

    @ViewBuilder
    private var actionButton: some View {
        switch state {
        case .idle:
            Button(action: onInject) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text(language.t(L.injectCheat))
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.35, green: 0.22, blue: 0.92),
                            Color(red: 0.12, green: 0.50, blue: 0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Capsule()
                )
                .shadow(color: Color(red: 0.25, green: 0.30, blue: 0.90).opacity(0.45), radius: 8, y: 3)
            }
            .buttonStyle(.plain)

        case .injecting, .restoring:
            HStack(spacing: 7) {
                ProgressView()
                    .controlSize(.mini)
                    .tint(Color(red: 0.55, green: 0.80, blue: 1.0))
                Text(state == .injecting ? "Injecting" : "Restoring")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(red: 0.55, green: 0.80, blue: 1.0))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Color(red: 0.20, green: 0.40, blue: 0.80).opacity(0.20),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(Color(red: 0.40, green: 0.60, blue: 1.0).opacity(0.35), lineWidth: 1)
            )

        case .injected:
            Button(action: onRestore) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text(language.t(L.restoreDefault))
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.72, blue: 0.45),
                            Color(red: 0.05, green: 0.55, blue: 0.35)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Capsule()
                )
                .shadow(color: Color(red: 0.05, green: 0.65, blue: 0.40).opacity(0.40), radius: 7, y: 3)
            }
            .buttonStyle(.plain)

        case .unavailable:
            HStack(spacing: 5) {
                Image(systemName: "slash.circle")
                    .font(.system(size: 11, weight: .semibold))
                Text(language.t(L.unavailable))
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(Color(red: 1.0, green: 0.40, blue: 0.40).opacity(0.70))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Color(red: 1.0, green: 0.25, blue: 0.25).opacity(0.10),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(Color(red: 1.0, green: 0.35, blue: 0.35).opacity(0.25), lineWidth: 1)
            )
        }
    }
}
