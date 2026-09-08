import SwiftUI

struct InjectTerminalView: View {
    let logs: [TerminalLine]
    let isDone: Bool
    let isSuccess: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Terminal header bar
            HStack(spacing: 6) {
                Circle().fill(Color(white: 0.35)).frame(width: 10, height: 10)
                Circle().fill(Color(white: 0.35)).frame(width: 10, height: 10)
                Circle().fill(Color(white: 0.35)).frame(width: 10, height: 10)
                Spacer()
                Text("inject.sh")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.30))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.05))

            Divider().overlay(Color.white.opacity(0.08))

            // Log lines
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(logs) { line in
                        Text(line.text)
                            .font(.system(size: 12.5, weight: .regular, design: .monospaced))
                            .foregroundStyle(line.color)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if !isDone {
                        // Blinking cursor
                        BlinkingCursor()
                    }
                }
                .padding(14)
                .animation(.easeInOut(duration: 0.25), value: logs.count)
            }
            .frame(minHeight: 120, maxHeight: 160)

            // Success checkmark animation
            if isDone && isSuccess {
                Divider().overlay(Color.white.opacity(0.08))
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        if #available(iOS 17.0, *) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(Color(white: 0.82))
                                .symbolEffect(.bounce, value: isDone)
                        } else {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(Color(white: 0.82))
                        }
                        Text("Success")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                }
                .padding(.vertical, 14)
                .transition(.scale(scale: 0.80).combined(with: .opacity))
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.11), lineWidth: 1)
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.78), value: isDone)
    }
}

struct TerminalLine: Identifiable {
    let id = UUID()
    let text: String
    var color: Color {
        if text.hasPrefix("[✓]") { return Color(white: 0.70) }
        if text.hasPrefix("[✗]") { return Color(white: 0.55) }
        if text.hasPrefix("[!]") { return Color(white: 0.60) }
        return Color(white: 0.82)
    }
}

private struct BlinkingCursor: View {
    @State private var visible = true
    var body: some View {
        Text("█")
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(Color(white: 0.7).opacity(visible ? 0.8 : 0.0))
            .onAppear {
                withAnimation(.easeInOut(duration: 0.55).repeatForever()) {
                    visible.toggle()
                }
            }
    }
}
