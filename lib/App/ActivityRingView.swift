import SwiftUI

struct ActivityRingView: View {
    var stepProgress: CGFloat
    var calorieProgress: CGFloat
    var lineWidthOuter: CGFloat = 22
    var lineWidthInner: CGFloat = 16

    var body: some View {
        ZStack {
            RingTrack(diameter: 220, lineWidth: lineWidthOuter)
            RingTrack(diameter: 220 - (lineWidthOuter + 10) * 2, lineWidth: lineWidthInner)

            RingProgress(
                progress: min(1, max(0, stepProgress)),
                diameter: 220,
                lineWidth: lineWidthOuter,
                gradient: [AppTheme.accent, AppTheme.glow]
            )
            RingProgress(
                progress: min(1, max(0, calorieProgress)),
                diameter: 220 - (lineWidthOuter + 10) * 2,
                lineWidth: lineWidthInner,
                gradient: [AppTheme.accentSecondary, Color(red: 0.2, green: 0.85, blue: 0.75)]
            )
        }
        .frame(width: 240, height: 240)
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
