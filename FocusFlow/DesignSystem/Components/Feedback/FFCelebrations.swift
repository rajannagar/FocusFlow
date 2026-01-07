import SwiftUI

// MARK: - Celebration Effects
// Confetti, success animations, achievement badges

// MARK: - FFConfettiView

struct FFConfettiView: View {
    @State private var particles: [FFConfettiParticle] = []
    let colors: [Color]
    let count: Int
    let isActive: Bool
    
    init(
        isActive: Bool = true,
        colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink, .cyan],
        count: Int = 50
    ) {
        self.isActive = isActive
        self.colors = colors
        self.count = count
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    FFConfettiPiece(particle: particle)
                }
            }
            .onAppear {
                if isActive {
                    createAndAnimateParticles(in: geo.size)
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    createAndAnimateParticles(in: geo.size)
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createAndAnimateParticles(in size: CGSize) {
        particles = (0..<count).map { _ in
            FFConfettiParticle(
                color: colors.randomElement() ?? .white,
                position: CGPoint(x: size.width / 2, y: -20),
                size: CGFloat.random(in: 6...12),
                rotation: 0,
                opacity: 1,
                shape: FFConfettiShape.allCases.randomElement() ?? .circle
            )
        }
        
        for i in particles.indices {
            let delay = Double.random(in: 0...0.5)
            let duration = Double.random(in: 2...3.5)
            
            withAnimation(.easeOut(duration: duration).delay(delay)) {
                particles[i].position = CGPoint(
                    x: CGFloat.random(in: -50...(size.width + 50)),
                    y: size.height + 100
                )
                particles[i].rotation = Double.random(in: 360...1080)
                particles[i].opacity = 0
            }
        }
        
        // Cleanup after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            particles.removeAll()
        }
    }
}

struct FFConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    var position: CGPoint
    let size: CGFloat
    var rotation: Double
    var opacity: Double
    let shape: FFConfettiShape
}

enum FFConfettiShape: CaseIterable {
    case circle, square, triangle, star
}

struct FFConfettiPiece: View {
    let particle: FFConfettiParticle
    
    var body: some View {
        Group {
            switch particle.shape {
            case .circle:
                Circle().fill(particle.color)
            case .square:
                Rectangle().fill(particle.color)
            case .triangle:
                Triangle().fill(particle.color)
            case .star:
                Star(corners: 5, smoothness: 0.45).fill(particle.color)
            }
        }
        .frame(width: particle.size, height: particle.size)
        .rotationEffect(.degrees(particle.rotation))
        .position(particle.position)
        .opacity(particle.opacity)
    }
}

// MARK: - Helper Shapes

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Star: Shape {
    let corners: Int
    let smoothness: Double
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * smoothness
        
        var path = Path()
        let angleIncrement = .pi * 2 / Double(corners * 2)
        
        for i in 0..<corners * 2 {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = Double(i) * angleIncrement - .pi / 2
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - FFSuccessPulse

struct FFSuccessPulse: View {
    let color: Color
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1
    
    var body: some View {
        Circle()
            .stroke(color, lineWidth: 3)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    scale = 2.5
                    opacity = 0
                }
            }
    }
}

// MARK: - FFCheckmarkAnimation

struct FFCheckmarkAnimation: View {
    @State private var isAnimating = false
    let color: Color
    let size: CGFloat
    
    init(color: Color = .green, size: CGFloat = 60) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)
                .scaleEffect(isAnimating ? 1 : 0)
            
            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(color)
                .scaleEffect(isAnimating ? 1 : 0)
            
            // Pulse rings
            ForEach(0..<2, id: \.self) { index in
                Circle()
                    .stroke(color.opacity(0.4), lineWidth: 2)
                    .frame(width: size, height: size)
                    .scaleEffect(isAnimating ? 1.5 + CGFloat(index) * 0.3 : 1)
                    .opacity(isAnimating ? 0 : 0.5)
            }
        }
        .onAppear {
            DS.Haptic.success()
            withAnimation(DS.Animation.bounce) {
                isAnimating = true
            }
        }
    }
}

// MARK: - FFAchievementBadge

struct FFAchievementBadge: View {
    let icon: String
    let title: String
    let subtitle: String?
    let color: Color
    
    @State private var isAnimating = false
    
    init(icon: String, title: String, subtitle: String? = nil, color: Color = .yellow) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            ZStack {
                // Glow rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(color.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                        .frame(width: 100 + CGFloat(i) * 20, height: 100 + CGFloat(i) * 20)
                        .scaleEffect(isAnimating ? 1.2 + CGFloat(i) * 0.1 : 0.8)
                        .opacity(isAnimating ? 0 : 1)
                }
                
                // Badge
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: color.opacity(0.5), radius: 20, y: 10)
                    .scaleEffect(isAnimating ? 1 : 0.5)
            }
            .frame(width: 150, height: 150)
            
            VStack(spacing: DS.Spacing.xxs) {
                Text(title)
                    .font(.system(size: DS.Font.headline, weight: .bold))
                    .foregroundColor(.white)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: DS.Font.footnote, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 20)
        }
        .onAppear {
            DS.Haptic.success()
            withAnimation(DS.Animation.bounce) {
                isAnimating = true
            }
        }
    }
}

// MARK: - FFCelebrationOverlay

struct FFCelebrationOverlay: View {
    @Binding var isShowing: Bool
    let type: CelebrationType
    
    enum CelebrationType {
        case goalComplete
        case streakAchieved(days: Int)
        case levelUp(level: Int)
        case custom(icon: String, title: String, subtitle: String?, color: Color)
    }
    
    var body: some View {
        ZStack {
            if isShowing {
                // Dimmed background
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(DS.Animation.smooth) {
                            isShowing = false
                        }
                    }
                
                // Confetti
                FFConfettiView(isActive: isShowing)
                
                // Badge
                celebrationContent
                    .transition(.ffScale)
            }
        }
        .animation(DS.Animation.bounce, value: isShowing)
    }
    
    @ViewBuilder
    private var celebrationContent: some View {
        switch type {
        case .goalComplete:
            FFAchievementBadge(
                icon: "target",
                title: "Goal Complete!",
                subtitle: "You crushed it today",
                color: .green
            )
        case .streakAchieved(let days):
            FFAchievementBadge(
                icon: "flame.fill",
                title: "\(days) Day Streak!",
                subtitle: "Keep the momentum going",
                color: .orange
            )
        case .levelUp(let level):
            FFAchievementBadge(
                icon: "star.fill",
                title: "Level \(level)!",
                subtitle: "You're unstoppable",
                color: .purple
            )
        case .custom(let icon, let title, let subtitle, let color):
            FFAchievementBadge(
                icon: icon,
                title: title,
                subtitle: subtitle,
                color: color
            )
        }
    }
}

// MARK: - View Extension

extension View {
    /// Show celebration overlay
    func ffCelebration(
        isShowing: Binding<Bool>,
        type: FFCelebrationOverlay.CelebrationType
    ) -> some View {
        self.overlay {
            FFCelebrationOverlay(isShowing: isShowing, type: type)
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var showCelebration = false
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: DS.Spacing.xxl) {
                    FFCheckmarkAnimation()
                    
                    FFPrimaryButton(title: "Celebrate!") {
                        showCelebration = true
                    }
                    .padding(.horizontal, DS.Spacing.xl)
                }
                .ffCelebration(isShowing: $showCelebration, type: .goalComplete)
            }
        }
    }
    
    return PreviewWrapper()
}
