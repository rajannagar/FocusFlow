import SwiftUI
import UIKit

enum FFHaptics {
    static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func soft()  { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
}

// =========================================================
// MARK: - Premium Segmented Pill
// =========================================================

struct FFPillSegmented<Value: Hashable & CaseIterable & RawRepresentable>: View where Value.RawValue == String {
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(Value.allCases), id: \.self) { item in
                let isSelected = (item == selection)

                Button {
                    guard selection != item else { return }
                    FFHaptics.soft()
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                        selection = item
                    }
                } label: {
                    Text(item.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.75))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 999, style: .continuous)
                                .fill(isSelected ? Color.white.opacity(0.18) : Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                                        .stroke(Color.white.opacity(isSelected ? 0.18 : 0.10), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 999, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}

// =========================================================
// MARK: - Particle Field (subtle motion)
// =========================================================

struct FFParticleField: View {
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var s: CGFloat
        var o: Double
        var d: Double
    }

    @State private var particles: [Particle] = []
    @State private var animate = false

    let count: Int
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Circle()
                        .fill(color.opacity(p.o))
                        .frame(width: p.s, height: p.s)
                        .position(
                            x: p.x + (animate ? 6 : -6),
                            y: p.y + (animate ? -8 : 8)
                        )
                        .animation(.easeInOut(duration: p.d).repeatForever(autoreverses: true), value: animate)
                }
            }
            .onAppear {
                if particles.isEmpty {
                    var arr: [Particle] = []
                    for _ in 0..<count {
                        arr.append(
                            Particle(
                                x: .random(in: 0...geo.size.width),
                                y: .random(in: 0...geo.size.height),
                                s: .random(in: 2...5),
                                o: .random(in: 0.10...0.34),
                                d: .random(in: 3.0...6.0)
                            )
                        )
                    }
                    particles = arr
                }
                animate = true
            }
        }
        .allowsHitTesting(false)
    }
}

// =========================================================
// MARK: - Momentum Orb (size-controlled)
// =========================================================

struct FFMomentumOrb: View {
    let progress: Double   // 0...1
    let title: String
    let mainValue: String
    let subValue: String
    let accentA: Color
    let accentB: Color
    var size: CGFloat = 128

    @State private var spin = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(accentA.opacity(0.30))
                .blur(radius: 24)
                .scaleEffect(1.30)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            Color.white.opacity(0.06),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 12,
                        endRadius: 160
                    )
                )
                .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 1))

            FFParticleField(count: 12, color: .white)
                .clipShape(Circle())
                .opacity(0.85)

            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: 10)

            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    AngularGradient(colors: [accentA, accentB, accentA], center: .center),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: accentA.opacity(0.28), radius: 16, x: 0, y: 10)

            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.30),
                            Color.white.opacity(0.0)
                        ],
                        center: .center
                    ),
                    lineWidth: 8
                )
                .rotationEffect(.degrees(spin ? 360 : 0))
                .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: spin)
                .opacity(0.55)

            VStack(spacing: 7) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))

                Text(mainValue)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)

                Text(subValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.70))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Capsule(style: .continuous))
                    .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(pulse ? 1.02 : 0.98)
        .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: pulse)
        .onAppear {
            spin = true
            pulse = true
        }
    }
}
