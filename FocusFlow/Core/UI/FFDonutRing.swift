import SwiftUI

// =========================================================
// MARK: - FFDonutRing
// =========================================================

/// Premium donut ring used in Progress (and safe to reuse elsewhere).
struct FFDonutRing: View {
    let progress: Double          // 0...1
    let accentA: Color
    let accentB: Color
    let centerTop: String
    let centerBottom: String

    var size: CGFloat = 78
    var lineWidth: CGFloat = 10

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [accentA, accentB, accentA]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: accentA.opacity(0.25), radius: 10, x: 0, y: 6)

            VStack(spacing: 2) {
                Text(centerTop)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text(centerBottom)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.65))
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue(centerTop)
    }
}
