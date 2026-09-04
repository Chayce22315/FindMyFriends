import SwiftUI
import UIKit

/// Shared sizing rules for the iPhone-first interface.
/// The layout uses the available device width/height rather than hard-coded
/// coordinates, so newer iPhones and the user's iPhone 17,4-sized display
/// keep the same visual rhythm without clipping.
enum LayoutMetrics {
    static var screenWidth: CGFloat { UIScreen.main.bounds.width }
    static var screenHeight: CGFloat { UIScreen.main.bounds.height }
    static var isLargePhone: Bool { screenWidth >= 414 }
    static var isXLPhone: Bool { screenWidth >= 430 }
    static var isCompactPhone: Bool { screenHeight < 700 || screenWidth < 360 }

    static var contentMaxWidth: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 840
        }
        return .infinity
    }

    static var cardPadding: CGFloat {
        if isCompactPhone { return 18 }
        if isXLPhone { return 24 }
        if isLargePhone { return 22 }
        return 20
    }

    static var sectionSpacing: CGFloat {
        if isCompactPhone { return 22 }
        if isXLPhone { return 30 }
        if isLargePhone { return 28 }
        return 24
    }

    /// Keep a comfortable breathing room from the Dynamic Island and screen edges.
    static var pageHorizontalPadding: CGFloat {
        if isCompactPhone { return 16 }
        if isXLPhone { return 18 }
        if isLargePhone { return 16 }
        return 14
    }

    static var headerHorizontalPadding: CGFloat { pageHorizontalPadding + 2 }
    static var mapOverlayHorizontalPadding: CGFloat { isCompactPhone ? 14 : 18 }
    static var mapCardHeight: CGFloat { isXLPhone ? 300 : (isLargePhone ? 280 : 240) }

    static var heroCardHeight: CGFloat {
        if isCompactPhone { return 340 }
        if isXLPhone { return 500 }
        if isLargePhone { return 480 }
        return 440
    }

    static var cornerRadius: CGFloat { isXLPhone ? 26 : 22 }
}

struct ContentMaxWidthModifier: ViewModifier {
    var maxWidth: CGFloat = LayoutMetrics.contentMaxWidth

    func body(content: Content) -> some View {
        Group {
            if maxWidth.isFinite {
                content
                    .frame(maxWidth: maxWidth)
                    .frame(maxWidth: .infinity)
            } else {
                content.frame(maxWidth: .infinity)
            }
        }
    }
}

extension View {
    func contentMaxWidth(_ maxWidth: CGFloat = LayoutMetrics.contentMaxWidth) -> some View {
        modifier(ContentMaxWidthModifier(maxWidth: maxWidth))
    }
}

enum AppTheme {
    static let accent = Color(red: 0.36, green: 0.56, blue: 1.0)
    static let accentSecondary = Color(red: 0.40, green: 0.82, blue: 0.96)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let glow = Color(red: 0.54, green: 0.46, blue: 1.0)

    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.035, green: 0.045, blue: 0.10),
            Color(red: 0.075, green: 0.095, blue: 0.18),
            Color(red: 0.045, green: 0.06, blue: 0.125),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.15),
            Color.white.opacity(0.055),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = LayoutMetrics.cornerRadius
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
                                Color.white.opacity(0.07),
                                AppTheme.accent.opacity(0.10),
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
                                Color.white.opacity(0.58),
                                Color.white.opacity(0.12),
                                AppTheme.accent.opacity(0.38),
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
                                Color.white.opacity(0.055),
                                Color.clear,
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 240
                        )
                    )
                    .blur(radius: 12)
            }
            .shadow(color: .black.opacity(0.28), radius: 26, y: 12)
            .shadow(color: AppTheme.accent.opacity(0.16), radius: 18, y: 6)
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
