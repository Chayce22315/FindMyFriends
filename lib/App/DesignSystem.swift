import SwiftUI
import UIKit

/// Centers content on wide phones / iPad so layouts do not feel SE-sized in the middle of the screen.
enum LayoutMetrics {
    static var screenWidth: CGFloat { UIScreen.main.bounds.width }
    static var screenHeight: CGFloat { UIScreen.main.bounds.height }
    static var isLargePhone: Bool { screenWidth >= 414 }
    static var isXLPhone: Bool { screenWidth >= 430 }
    /// Small phones (e.g. mini, SE) need shorter fixed blocks so the scene is not clipped.
    static var isCompactPhone: Bool { screenHeight < 700 || screenWidth < 360 }

    static var contentMaxWidth: CGFloat { isXLPhone ? 840 : (isLargePhone ? 760 : 600) }
    static var cardPadding: CGFloat { isXLPhone ? 28 : (isLargePhone ? 24 : 20) }
    static var sectionSpacing: CGFloat { isXLPhone ? 36 : (isLargePhone ? 32 : 28) }
    static var pageHorizontalPadding: CGFloat { isXLPhone ? 6 : (isLargePhone ? 12 : 20) }
    static var headerHorizontalPadding: CGFloat { pageHorizontalPadding + (isXLPhone ? 10 : 4) }
    /// Overlays on full-screen map use full width on phones (avoid maxWidth clamp letterboxing).
    static var mapOverlayHorizontalPadding: CGFloat { isCompactPhone ? 14 : (isXLPhone ? 18 : 16) }
    static var mapCardHeight: CGFloat { isXLPhone ? 300 : (isLargePhone ? 280 : 240) }
    static var heroCardHeight: CGFloat {
        if isCompactPhone { return 340 }
        return isXLPhone ? 560 : (isLargePhone ? 520 : 500)
    }
}

struct ContentMaxWidthModifier: ViewModifier {
    var maxWidth: CGFloat = LayoutMetrics.contentMaxWidth

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    func contentMaxWidth(_ maxWidth: CGFloat = LayoutMetrics.contentMaxWidth) -> some View {
        modifier(ContentMaxWidthModifier(maxWidth: maxWidth))
    }
}

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
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        content()
            .padding(LayoutMetrics.cardPadding)
            .background {
                if settings.liquidGlassEnabled {
                    LiquidGlassSurface(cornerRadius: cornerRadius)
                } else {
                    DefaultGlassSurface(cornerRadius: cornerRadius)
                }
            }
    }
}

private struct DefaultGlassSurface: View {
    var cornerRadius: CGFloat

    var body: some View {
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

private struct LiquidGlassSurface: View {
    var cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.28),
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.16),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.screen)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.55),
                                Color.white.opacity(0.12),
                                AppTheme.accent.opacity(0.35),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.22),
                                Color.white.opacity(0.06),
                                Color.clear,
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 220
                        )
                    )
                    .blur(radius: 12)
            }
            .shadow(color: .black.opacity(0.28), radius: 26, y: 12)
            .shadow(color: AppTheme.accent.opacity(0.15), radius: 18, y: 6)
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String?
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        let useLarge = sizeClass == .regular || LayoutMetrics.isLargePhone
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(useLarge ? .title.weight(.semibold) : .title2.weight(.semibold))
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
