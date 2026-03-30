import SwiftUI

struct ActivityRingView: View {
    var stepProgress: CGFloat
    var calorieProgress: CGFloat
    /// 1.0 = base size (~240pt); scales up on larger widths.
    var scale: CGFloat = 1.0

    private var lineWidthOuter: CGFloat { 22 * scale }
    private var lineWidthInner: CGFloat { 16 * scale }
    private var baseDiameter: CGFloat { 220 * scale }

    var body: some View {
        let innerDiameter = baseDiameter - (lineWidthOuter + 10 * scale) * 2
        ZStack {
            RingTrack(diameter: baseDiameter, lineWidth: lineWidthOuter)
            RingTrack(diameter: innerDiameter, lineWidth: lineWidthInner)

            RingProgress(
                progress: min(1, max(0, stepProgress)),
                diameter: baseDiameter,
                lineWidth: lineWidthOuter,
                gradient: [AppTheme.accent, AppTheme.glow]
            )
            RingProgress(
                progress: min(1, max(0, calorieProgress)),
                diameter: innerDiameter,
                lineWidth: lineWidthInner,
                gradient: [AppTheme.accentSecondary, Color(red: 0.2, green: 0.85, blue: 0.75)]
            )
        }
        .frame(width: 240 * scale, height: 240 * scale)
    }
}

private struct RingTrack: View {
    var diameter: CGFloat
    var lineWidth: CGFloat

    var body: some View {
        Circle()
            .stroke(Color.white.opacity(0.08), lineWidth: lineWidth)
            .frame(width: diameter, height: diameter)
    }
}

private struct RingProgress: View {
    var progress: CGFloat
    var diameter: CGFloat
    var lineWidth: CGFloat
    var gradient: [Color]

    var body: some View {
        Circle()
            .trim(from: 0, to: progress)
            .stroke(
                AngularGradient(colors: gradient + [gradient[0]], center: .center),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .frame(width: diameter, height: diameter)
            .shadow(color: gradient[0].opacity(0.35), radius: 10, y: 4)
    }
}
