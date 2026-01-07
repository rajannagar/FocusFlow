import SwiftUI

// MARK: - Flow Animations

/// Premium animations for Flow AI chat - Enhanced with micro-interactions

// MARK: - Streaming Text View

/// Displays text with character-by-character typing animation
struct FlowStreamingText: View {
    let fullText: String
    let theme: AppTheme
    var speed: Double = 0.02
    var onComplete: (() -> Void)?
    
    @State private var displayedText = ""
    @State private var isComplete = false
    @State private var showCursor = true
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Text(displayedText)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.95))
                .lineSpacing(4)
            
            // Blinking cursor
            if !isComplete {
                Text("|")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(theme.accentPrimary)
                    .opacity(showCursor ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: showCursor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            startTypingAnimation()
        }
        .onChange(of: fullText) { newText in
            // If text changes, restart animation
            displayedText = ""
            isComplete = false
            startTypingAnimation()
        }
    }
    
    private func startTypingAnimation() {
        showCursor = true
        
        let characters = Array(fullText)
        var currentIndex = 0
        
        Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { timer in
            if currentIndex < characters.count {
                displayedText.append(characters[currentIndex])
                currentIndex += 1
            } else {
                timer.invalidate()
                isComplete = true
                onComplete?()
            }
        }
    }
}

// MARK: - Advanced Typing Indicator with Phrases

/// Animated typing indicator with personality phrases (enhanced version)
/// Note: Basic FlowTypingIndicator is in FlowChatView.swift
struct FlowTypingIndicatorWithPhrases: View {
    let theme: AppTheme
    var showPhrase: Bool = true
    
    @State private var dotOpacities: [Double] = [0.3, 0.3, 0.3]
    @State private var currentPhrase: String = ""
    @State private var phraseOpacity: Double = 0
    
    private let phrases = [
        "Thinking...",
        "Let me check that...",
        "Working on it...",
        "Almost there...",
        "Processing...",
        "One moment...",
        "Looking into that...",
        "Analyzing...",
        "Computing...",
        "On it..."
    ]
    
    var body: some View {
        HStack(spacing: 8) {
            // Animated dots
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(theme.accentPrimary)
                        .frame(width: 8, height: 8)
                        .opacity(dotOpacities[index])
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
            )
            
            // Personality phrase
            if showPhrase {
                Text(currentPhrase)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .opacity(phraseOpacity)
            }
            
            Spacer()
        }
        .onAppear {
            startDotAnimation()
            if showPhrase {
                startPhraseRotation()
            }
        }
    }
    
    private func startDotAnimation() {
        // Cascading dot animation
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                dotOpacities[0] = dotOpacities[0] == 0.3 ? 1.0 : 0.3
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    dotOpacities[1] = dotOpacities[1] == 0.3 ? 1.0 : 0.3
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    dotOpacities[2] = dotOpacities[2] == 0.3 ? 1.0 : 0.3
                }
            }
        }
    }
    
    private func startPhraseRotation() {
        currentPhrase = phrases.randomElement() ?? "Thinking..."
        
        withAnimation(.easeIn(duration: 0.3)) {
            phraseOpacity = 1
        }
        
        // Rotate phrases every 2.5 seconds
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            withAnimation(.easeOut(duration: 0.2)) {
                phraseOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentPhrase = phrases.randomElement() ?? "Thinking..."
                withAnimation(.easeIn(duration: 0.3)) {
                    phraseOpacity = 1
                }
            }
        }
    }
}

// MARK: - Message Appear Animation

/// Wrapper view that adds slide-in animation to messages
struct FlowMessageAppear<Content: View>: View {
    let content: Content
    let delay: Double
    
    @State private var isVisible = false
    
    init(delay: Double = 0, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.delay = delay
    }
    
    var body: some View {
        content
            .offset(y: isVisible ? 0 : 20)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isVisible = true
                    }
                }
            }
    }
}

// MARK: - Pulse Glow Effect

/// Adds a subtle pulsing glow effect
struct FlowPulseGlow: ViewModifier {
    let color: Color
    @State private var isGlowing = false
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isGlowing ? 0.6 : 0.2), radius: isGlowing ? 15 : 8)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isGlowing = true
                }
            }
    }
}

extension View {
    func flowPulseGlow(color: Color) -> some View {
        modifier(FlowPulseGlow(color: color))
    }
}

// MARK: - Shimmer Effect

/// Adds a shimmering loading effect
struct FlowShimmer: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.6)
                    .offset(x: -geometry.size.width * 0.3 + phase * (geometry.size.width * 1.6))
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: phase)
                }
            )
            .mask(content)
            .onAppear {
                phase = 1
            }
    }
}

extension View {
    func flowShimmer() -> some View {
        modifier(FlowShimmer())
    }
}

// MARK: - Action Success Animation

/// Checkmark animation for successful actions
struct FlowActionSuccess: View {
    let theme: AppTheme
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(theme.accentPrimary.opacity(0.2))
                .frame(width: 60, height: 60)
                .scaleEffect(isAnimating ? 1.2 : 0)
                .opacity(isAnimating ? 0 : 1)
            
            Circle()
                .fill(theme.accentPrimary)
                .frame(width: 50, height: 50)
                .scaleEffect(isAnimating ? 1 : 0)
            
            Image(systemName: "checkmark")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(isAnimating ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Wave Animation

/// Animated waveform for voice input
struct FlowVoiceWave: View {
    let theme: AppTheme
    let isRecording: Bool
    
    @State private var heights: [CGFloat] = [20, 30, 25, 35, 20, 28, 22, 32, 26, 30]
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<10, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 4, height: heights[index])
                    .animation(
                        .easeInOut(duration: 0.3 + Double(index) * 0.05)
                        .repeatForever(autoreverses: true),
                        value: heights[index]
                    )
            }
        }
        .frame(height: 40)
        .onAppear {
            if isRecording {
                animateBars()
            }
        }
        .onChange(of: isRecording) { recording in
            if recording {
                animateBars()
            }
        }
    }
    
    private func animateBars() {
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { timer in
            if !isRecording {
                timer.invalidate()
                return
            }
            
            for i in 0..<heights.count {
                heights[i] = CGFloat.random(in: 10...40)
            }
        }
    }
}

// MARK: - Bounce Animation

/// Adds a subtle bounce on appearance
struct FlowBounce: ViewModifier {
    @State private var isBouncing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isBouncing ? 1 : 0.8)
            .opacity(isBouncing ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    isBouncing = true
                }
            }
    }
}

extension View {
    func flowBounce() -> some View {
        modifier(FlowBounce())
    }
}

// MARK: - Progress Ring

/// Animated circular progress indicator
struct FlowProgressRing: View {
    let progress: Double
    let theme: AppTheme
    let lineWidth: CGFloat
    
    @State private var animatedProgress: Double = 0
    
    init(progress: Double, theme: AppTheme, lineWidth: CGFloat = 6) {
        self.progress = progress
        self.theme = theme
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: [theme.accentPrimary, theme.accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newProgress in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newProgress
            }
        }
    }
}

// MARK: - Celebration Particles

/// Confetti-like particle animation for celebrations
struct FlowCelebration: View {
    let theme: AppTheme
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var rotation: Double
        var scale: CGFloat
        let color: Color
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: 8, height: 8)
                        .scaleEffect(particle.scale)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(x: particle.x, y: particle.y)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles(in: geometry.size)
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        let colors: [Color] = [
            theme.accentPrimary,
            theme.accentSecondary,
            .yellow,
            .orange,
            .pink
        ]
        
        particles = (0..<20).map { _ in
            Particle(
                x: size.width / 2,
                y: size.height / 2,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.5),
                color: colors.randomElement()!
            )
        }
    }
    
    private func animateParticles(in size: CGSize) {
        for i in particles.indices {
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 50...150)
            
            withAnimation(.easeOut(duration: 1.5)) {
                particles[i].x += cos(angle) * distance
                particles[i].y += sin(angle) * distance - 100
                particles[i].rotation += Double.random(in: 180...720)
                particles[i].scale = 0
            }
        }
    }
}

// MARK: - Premium Micro-Interactions

/// Smooth scale button style for Flow actions
struct FlowScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Depth press button style for important actions
struct FlowDepthPressStyle: ButtonStyle {
    let theme: AppTheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(
                color: theme.accentPrimary.opacity(configuration.isPressed ? 0.2 : 0.4),
                radius: configuration.isPressed ? 4 : 12,
                y: configuration.isPressed ? 2 : 6
            )
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed {
                    Haptics.impact(.light)
                }
            }
    }
}

/// Floating animation for subtle movement
struct FlowFloat: ViewModifier {
    @State private var offset: CGFloat = 0
    let amplitude: CGFloat
    let duration: Double
    
    init(amplitude: CGFloat = 5, duration: Double = 2) {
        self.amplitude = amplitude
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    offset = amplitude
                }
            }
    }
}

extension View {
    func flowFloat(amplitude: CGFloat = 5, duration: Double = 2) -> some View {
        modifier(FlowFloat(amplitude: amplitude, duration: duration))
    }
}

/// Gradient border animation
struct FlowAnimatedBorder: ViewModifier {
    let theme: AppTheme
    let lineWidth: CGFloat
    @State private var rotation: Double = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        AngularGradient(
                            colors: [
                                theme.accentPrimary,
                                theme.accentSecondary,
                                theme.accentPrimary.opacity(0.5),
                                theme.accentPrimary
                            ],
                            center: .center,
                            angle: .degrees(rotation)
                        ),
                        lineWidth: lineWidth
                    )
            )
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

extension View {
    func flowAnimatedBorder(theme: AppTheme, lineWidth: CGFloat = 2) -> some View {
        modifier(FlowAnimatedBorder(theme: theme, lineWidth: lineWidth))
    }
}

/// Morphing blob background
struct FlowMorphingBlob: View {
    let color: Color
    @State private var morph = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.3))
                .scaleEffect(morph ? 1.2 : 0.9)
                .blur(radius: 30)
            
            Circle()
                .fill(color.opacity(0.2))
                .scaleEffect(morph ? 0.9 : 1.15)
                .blur(radius: 25)
                .offset(x: morph ? 15 : -15, y: morph ? -10 : 10)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                morph = true
            }
        }
    }
}

/// Card flip animation
struct FlowFlip<Front: View, Back: View>: View {
    let front: Front
    let back: Back
    @Binding var isFlipped: Bool
    
    init(isFlipped: Binding<Bool>, @ViewBuilder front: () -> Front, @ViewBuilder back: () -> Back) {
        self._isFlipped = isFlipped
        self.front = front()
        self.back = back()
    }
    
    var body: some View {
        ZStack {
            front
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 0 : 1)
            
            back
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1 : 0)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isFlipped)
    }
}

/// Typewriter cursor
struct FlowCursor: View {
    let color: Color
    @State private var isVisible = true
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 2, height: 18)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isVisible.toggle()
                }
            }
    }
}

/// Ripple effect on tap
struct FlowRipple: ViewModifier {
    let color: Color
    @State private var isRippling = false
    @State private var tapLocation: CGPoint = .zero
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isRippling {
                        Circle()
                            .fill(color.opacity(0.3))
                            .frame(width: 20, height: 20)
                            .scaleEffect(isRippling ? 10 : 0)
                            .opacity(isRippling ? 0 : 1)
                            .position(tapLocation)
                            .animation(.easeOut(duration: 0.5), value: isRippling)
                    }
                }
            )
            .onTapGesture { location in
                tapLocation = location
                isRippling = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isRippling = false
                }
            }
    }
}

extension View {
    func flowRipple(color: Color = .white) -> some View {
        modifier(FlowRipple(color: color))
    }
}

/// Number counter animation
struct FlowCounterText: View {
    let value: Int
    let font: Font
    let color: Color
    
    @State private var displayValue: Int = 0
    
    var body: some View {
        Text("\(displayValue)")
            .font(font)
            .foregroundColor(color)
            .contentTransition(.numericText())
            .onAppear {
                animateCount(to: value)
            }
            .onChange(of: value) { newValue in
                animateCount(to: newValue)
            }
    }
    
    private func animateCount(to target: Int) {
        let steps = min(abs(target - displayValue), 20)
        let stepValue = Double(target - displayValue) / Double(max(steps, 1))
        
        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.03) {
                withAnimation(.easeOut(duration: 0.1)) {
                    displayValue = displayValue + Int(stepValue)
                }
            }
        }
        
        // Ensure we hit exact target
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(steps) * 0.03) {
            withAnimation {
                displayValue = target
            }
        }
    }
}

/// Staggered appear animation for lists
struct FlowStaggeredAppear: ViewModifier {
    let index: Int
    let baseDelay: Double
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: isVisible ? 0 : 20)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(baseDelay + Double(index) * 0.05)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func flowStaggeredAppear(index: Int, baseDelay: Double = 0) -> some View {
        modifier(FlowStaggeredAppear(index: index, baseDelay: baseDelay))
    }
}

/// Breathing glow effect
struct FlowBreathingGlow: ViewModifier {
    let color: Color
    let intensity: CGFloat
    @State private var isBreathing = false
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isBreathing ? Double(intensity) : Double(intensity) * 0.3), radius: isBreathing ? 20 : 8)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isBreathing = true
                }
            }
    }
}

extension View {
    func flowBreathingGlow(color: Color, intensity: CGFloat = 0.6) -> some View {
        modifier(FlowBreathingGlow(color: color, intensity: intensity))
    }
}

/// Elastic scale animation
struct FlowElasticScale: ViewModifier {
    @State private var scale: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.interpolatingSpring(stiffness: 200, damping: 10)) {
                    scale = 1
                }
            }
    }
}

extension View {
    func flowElasticScale() -> some View {
        modifier(FlowElasticScale())
    }
}

/// Slide and fade transition
extension AnyTransition {
    static var flowSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
            removal: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95))
        )
    }
    
    static var flowFade: AnyTransition {
        .opacity.combined(with: .scale(scale: 0.98))
    }
    
    static var flowPop: AnyTransition {
        .scale(scale: 0.8).combined(with: .opacity)
    }
}

// MARK: - AI Thinking Animation

/// Premium AI thinking animation with neural network effect
struct FlowNeuralThinking: View {
    let theme: AppTheme
    @State private var nodes: [NeuralNode] = []
    @State private var connections: [NeuralConnection] = []
    
    struct NeuralNode: Identifiable {
        let id = UUID()
        var position: CGPoint
        var opacity: Double
        var scale: CGFloat
    }
    
    struct NeuralConnection: Identifiable {
        let id = UUID()
        var start: CGPoint
        var end: CGPoint
        var opacity: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Connections
                ForEach(connections) { connection in
                    Path { path in
                        path.move(to: connection.start)
                        path.addLine(to: connection.end)
                    }
                    .stroke(theme.accentPrimary.opacity(connection.opacity * 0.3), lineWidth: 1)
                }
                
                // Nodes
                ForEach(nodes) { node in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [theme.accentPrimary, theme.accentSecondary.opacity(0.5)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 6
                            )
                        )
                        .frame(width: 12, height: 12)
                        .scaleEffect(node.scale)
                        .opacity(node.opacity)
                        .position(node.position)
                }
            }
            .onAppear {
                createNetwork(in: geometry.size)
                animateNetwork()
            }
        }
        .frame(height: 60)
    }
    
    private func createNetwork(in size: CGSize) {
        // Create nodes
        let nodeCount = 8
        nodes = (0..<nodeCount).map { i in
            NeuralNode(
                position: CGPoint(
                    x: CGFloat(i) / CGFloat(nodeCount - 1) * size.width,
                    y: CGFloat.random(in: 15...(size.height - 15))
                ),
                opacity: 0.3,
                scale: 0.8
            )
        }
        
        // Create connections
        connections = []
        for i in 0..<nodes.count {
            for j in (i+1)..<min(i+3, nodes.count) {
                connections.append(NeuralConnection(
                    start: nodes[i].position,
                    end: nodes[j].position,
                    opacity: 0.2
                ))
            }
        }
    }
    
    private func animateNetwork() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            // Randomly pulse nodes
            for i in nodes.indices {
                if Bool.random() {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        nodes[i].opacity = Double.random(in: 0.4...1.0)
                        nodes[i].scale = CGFloat.random(in: 0.8...1.3)
                    }
                }
            }
            
            // Pulse random connections
            for i in connections.indices {
                if Bool.random() {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        connections[i].opacity = Double.random(in: 0.1...0.6)
                    }
                }
            }
        }
    }
}
