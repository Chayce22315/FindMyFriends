import SwiftUI
import UIKit

enum AppTheme {
    static let accent = Color(red: 0.35, green: 0.55, blue: 1.0)
    static let accentSecondary = Color(red: 0.45, green: 0.85, blue: 0.95)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let glow = Color(red: 0.55, green: 0.45, blue: 1.0)

    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.06, green: 0.07, blue: 0.14),
            Color(red: 0.10, green: 0.12, blue: 0.22),
            Color(red: 0.07, green: 0.09, blue: 0.16),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.12),
            Color.white.opacity(0.04),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 22
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.35), .white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
            }
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
