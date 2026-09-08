import SwiftUI

// MARK: - Terminal line type
enum TerminalLineType {
    case info
    case success
    case error
    case warning
}

struct TerminalLine: Identifiable {
    let id    = UUID()
    let text  : String
    var type  : TerminalLineType = .info

    var color: Color {
        switch type {
        case .success: return Color(red: 0.22, green: 0.95, blue: 0.55)
        case .error:   return Color(red: 1.00, green: 0.38, blue: 0.38)
        case .warning: return Color(red: 1.00, green: 0.80, blue: 0.22)
        case .info:
            if text.hasPrefix("[✓]") { return Color(red: 0.22, green: 0.95, blue: 0.55) }
            if text.hasPrefix("[✗]") { return Color(red: 1.00, green: 0.38, blue: 0.38) }
            if text.hasPrefix("[!]") { return Color(red: 1.00, green: 0.80, blue: 0.22) }
            return Color(red: 0.75, green: 0.85, blue: 1.00)
        }
    }
}

// MARK: - Terminal view
struct InjectTerminalView: View {
    let logs      : [TerminalLine]
    let isDone    : Bool
    let isSuccess : Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // macOS-style traffic lights header
            HStack(spacing: 7) {
                Circle().fill(Color(red: 1.00, green: 0.37, blue: 0.35)).frame(width: 11, height: 11)
                Circle().fill(Color(red: 1.00, green: 0.74, blue: 0.22)).frame(width: 11, height: 11)
                Circle().fill(Color(red: 0.22, green: 0.83, blue: 0.38)).frame(width: 11, height: 11)

                Spacer()

                Text("inject.sh")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.30))

                Spacer()

                // Mirror spacing
                HStack(spacing: 7) {
                    Circle().fill(Color.clear).frame(width: 11, height: 11)
                    Circle().fill(Color.clear).frame(width: 11, height: 11)
                    Circle().fill(Color.clear).frame(width: 11, height: 11)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color.white.opacity(0.04))

            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)

            // Log lines
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(logs) { line in
                            HStack(alignment: .top, spacing: 6) {
                                Text("›")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(line.color.opacity(0.55))
                                Text(line.text)
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundStyle(line.color)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .id(line.id)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        if !isDone {
                            BlinkingCursor()
                        }
                    }
                    .padding(14)
                    .animation(.easeInOut(duration: 0.22), value: logs.count)
                }
                .frame(minHeight: 110, maxHeight: 155)
                .onChange(of: logs.count) { _ in
                    if let last = logs.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            // Done state
            if isDone {
                Rectangle()
                    .fill(Color.white.opacity(0.07))
                    .frame(height: 1)

                HStack(spacing: 14) {
                    Spacer()
                    VStack(spacing: 5) {
                        if isSuccess {
                            if #available(iOS 17.0, *) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(Color(red: 0.22, green: 0.95, blue: 0.55))
                                    .symbolEffect(.bounce, value: isDone)
                            } else {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(Color(red: 0.22, green: 0.95, blue: 0.55))
                            }
                            Text("DONE")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(red: 0.22, green: 0.95, blue: 0.55).opacity(0.70))
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(Color(red: 1.00, green: 0.38, blue: 0.38))
                            Text("FAILED")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(red: 1.00, green: 0.38, blue: 0.38).opacity(0.70))
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 14)
                .transition(.scale(scale: 0.82).combined(with: .opacity))
            }
        }
        .background(
            ZStack {
                Color(red: 0.04, green: 0.05, blue: 0.10)
                Color.white.opacity(0.02)
            },
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    isDone
                        ? (isSuccess
                            ? Color(red: 0.22, green: 0.95, blue: 0.55).opacity(0.30)
                            : Color(red: 1.00, green: 0.38, blue: 0.38).opacity(0.30))
                        : Color.white.opacity(0.10),
                    lineWidth: 1
                )
        )
        .animation(.spring(response: 0.40, dampingFraction: 0.78), value: isDone)
    }
}

// MARK: - Blinking cursor
private struct BlinkingCursor: View {
    @State private var visible = true
    var body: some View {
        HStack(spacing: 4) {
            Text("›")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(red: 0.55, green: 0.75, blue: 1.0).opacity(0.40))
            Text("█")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color(red: 0.55, green: 0.75, blue: 1.0).opacity(visible ? 0.80 : 0.0))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.52).repeatForever()) {
                visible.toggle()
            }
        }
    }
}
