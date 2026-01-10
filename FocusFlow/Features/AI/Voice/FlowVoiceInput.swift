import SwiftUI
import Speech
import AVFoundation
import Combine

// MARK: - Flow Voice Input

/// Enhanced Voice Manager for ChatGPT-like voice experience
/// Includes both speech-to-text and text-to-speech capabilities

@MainActor
final class FlowVoiceInputManager: ObservableObject {
    static let shared = FlowVoiceInputManager()
    
    // MARK: - Published State (Speech-to-Text)
    
    @Published private(set) var isListening = false
    @Published private(set) var isAuthorized = false
    @Published private(set) var transcribedText = ""
    @Published private(set) var error: VoiceInputError?
    @Published private(set) var audioLevel: Float = 0
    
    // MARK: - Published State (Text-to-Speech)
    
    @Published private(set) var isSpeaking = false
    @Published private(set) var speakingProgress: Float = 0
    @Published var isVoiceResponseEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isVoiceResponseEnabled, forKey: "flow_voice_response_enabled")
        }
    }
    
    // MARK: - Private Properties (Speech-to-Text)
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private var silenceTimer: Timer?
    private var lastTranscription: String = ""
    private var silenceDuration: TimeInterval = 0
    
    // MARK: - Private Properties (Text-to-Speech)
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var speechDelegate: FlowSpeechDelegate?
    private var currentUtterance: AVSpeechUtterance?
    
    // Voice settings
    private let preferredVoiceIdentifier = "com.apple.voice.premium.en-US.Samantha" // Premium Siri voice
    private let fallbackVoiceIdentifier = "com.apple.ttsbundle.Samantha-compact"
    
    // MARK: - Initialization
    
    private init() {
        // Initialize stored property first before calling any methods
        self.isVoiceResponseEnabled = UserDefaults.standard.bool(forKey: "flow_voice_response_enabled")
        
        // Now we can call setup methods
        setupSpeechRecognizer()
        setupSpeechSynthesizer()
    }
    
    // MARK: - Setup
    
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }
    
    private func setupSpeechSynthesizer() {
        speechDelegate = FlowSpeechDelegate(manager: self)
        speechSynthesizer.delegate = speechDelegate
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        // Request speech recognition permission
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        guard speechStatus == .authorized else {
            error = .notAuthorized
            return false
        }
        
        // Request microphone permission
        let micStatus = await AVAudioApplication.requestRecordPermission()
        
        guard micStatus else {
            error = .microphoneNotAuthorized
            return false
        }
        
        isAuthorized = true
        return true
    }
    
    // MARK: - Speech-to-Text (Recording Control)
    
    func startListening() async {
        if !isAuthorized {
            let granted = await requestAuthorization()
            if !granted { return }
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            error = .recognizerNotAvailable
            return
        }
        
        // Stop any TTS if playing
        stopSpeaking()
        
        // Stop any existing task
        await stopListening()
        
        // Configure audio session for recording
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = .audioSessionError
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            error = .requestCreationFailed
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        // Enable automatic punctuation if available
        if #available(iOS 16.0, *) {
            recognitionRequest.addsPunctuation = true
        }
        
        // Setup audio engine
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Reset silence detection
        lastTranscription = ""
        silenceDuration = 0
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            
            // Calculate audio level for visualization
            let level = self?.calculateAudioLevel(buffer: buffer) ?? 0
            DispatchQueue.main.async {
                self?.audioLevel = level
            }
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let newTranscription = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.transcribedText = newTranscription
                    
                    // Reset silence timer when we get new transcription
                    if newTranscription != self.lastTranscription {
                        self.lastTranscription = newTranscription
                        self.resetSilenceTimer()
                    }
                }
                
                // Check if recognition is final
                if result.isFinal {
                    Task { @MainActor in
                        self.invalidateSilenceTimer()
                    }
                }
            }
            
            if error != nil {
                Task { @MainActor in
                    self.invalidateSilenceTimer()
                    // Don't auto-stop on error, let user decide
                }
            }
        }
        
        // Start audio engine
        do {
            try audioEngine.start()
            isListening = true
            error = nil
            
            // Start silence detection
            startSilenceTimer()
        } catch {
            self.error = .audioEngineError
        }
    }
    
    func stopListening() async {
        invalidateSilenceTimer()
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        
        isListening = false
        audioLevel = 0
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    func clearTranscription() {
        transcribedText = ""
        lastTranscription = ""
    }
    
    // MARK: - Silence Detection
    
    private func startSilenceTimer() {
        invalidateSilenceTimer()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                // Check if audio level is low (silence)
                if self.audioLevel < 0.05 {
                    self.silenceDuration += 0.5
                } else {
                    self.silenceDuration = 0
                }
            }
        }
    }
    
    private func resetSilenceTimer() {
        silenceDuration = 0
    }
    
    private func invalidateSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        silenceDuration = 0
    }
    
    // MARK: - Text-to-Speech
    
    /// Speak text using natural voice (like ChatGPT voice mode)
    func speak(_ text: String, completion: (() -> Void)? = nil) {
        guard isVoiceResponseEnabled else {
            completion?()
            return
        }
        
        // Stop any current speech
        stopSpeaking()
        
        // Configure audio session for playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session for speech: \(error)")
            completion?()
            return
        }
        
        // Clean text for speech (remove markdown, emojis, etc.)
        let cleanedText = cleanTextForSpeech(text)
        
        guard !cleanedText.isEmpty else {
            completion?()
            return
        }
        
        // Create utterance
        let utterance = AVSpeechUtterance(string: cleanedText)
        
        // Use premium voice if available
        if let premiumVoice = AVSpeechSynthesisVoice(identifier: preferredVoiceIdentifier) {
            utterance.voice = premiumVoice
        } else if let fallbackVoice = AVSpeechSynthesisVoice(identifier: fallbackVoiceIdentifier) {
            utterance.voice = fallbackVoice
        } else {
            // Use best available English voice
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        // Configure speech parameters for natural sound
        utterance.rate = 0.52  // Slightly faster than default (0.5), natural pace
        utterance.pitchMultiplier = 1.05  // Slightly higher pitch for friendlier tone
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1
        
        currentUtterance = utterance
        speechDelegate?.completion = completion
        isSpeaking = true
        speakingProgress = 0
        
        speechSynthesizer.speak(utterance)
    }
    
    /// Stop current speech
    func stopSpeaking() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        speakingProgress = 0
        currentUtterance = nil
        speechDelegate?.completion = nil
    }
    
    /// Toggle voice response setting
    func toggleVoiceResponse() {
        isVoiceResponseEnabled.toggle()
        Haptics.impact(.light)
    }
    
    // MARK: - Helpers
    
    private func calculateAudioLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let frameCount = Int(buffer.frameLength)
        
        var sum: Float = 0
        for i in 0..<frameCount {
            sum += abs(channelData[i])
        }
        
        let average = sum / Float(frameCount)
        return min(1, average * 10) // Normalize to 0-1 range
    }
    
    /// Clean text for natural speech output
    private func cleanTextForSpeech(_ text: String) -> String {
        var cleaned = text
        
        // Remove markdown formatting
        cleaned = cleaned.replacingOccurrences(of: "**", with: "")
        cleaned = cleaned.replacingOccurrences(of: "__", with: "")
        cleaned = cleaned.replacingOccurrences(of: "*", with: "")
        cleaned = cleaned.replacingOccurrences(of: "_", with: "")
        cleaned = cleaned.replacingOccurrences(of: "`", with: "")
        cleaned = cleaned.replacingOccurrences(of: "#", with: "")
        
        // Remove bullet points
        cleaned = cleaned.replacingOccurrences(of: "• ", with: "")
        cleaned = cleaned.replacingOccurrences(of: "- ", with: "")
        
        // Remove emojis (they cause odd pauses in speech)
        cleaned = cleaned.unicodeScalars.filter { scalar in
            // Keep if not an emoji, or if it's a basic ASCII character
            !scalar.properties.isEmoji || scalar.value < 128
        }.map { String($0) }.joined()
        
        // Clean up multiple spaces/newlines
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Trim
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
    
    // MARK: - Internal Updates (called by delegate)
    
    fileprivate func updateSpeakingProgress(_ progress: Float) {
        speakingProgress = progress
    }
    
    fileprivate func didFinishSpeaking() {
        isSpeaking = false
        speakingProgress = 1.0
        currentUtterance = nil
        
        // Reset audio session
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}

// MARK: - Speech Delegate

private class FlowSpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    weak var manager: FlowVoiceInputManager?
    var completion: (() -> Void)?
    
    init(manager: FlowVoiceInputManager) {
        self.manager = manager
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            manager?.updateSpeakingProgress(0)
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let progress = Float(characterRange.location + characterRange.length) / Float(utterance.speechString.count)
        Task { @MainActor in
            manager?.updateSpeakingProgress(progress)
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            manager?.didFinishSpeaking()
            completion?()
            completion = nil
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            manager?.didFinishSpeaking()
            completion = nil
        }
    }
}

// MARK: - Error Types

enum VoiceInputError: LocalizedError {
    case notAuthorized
    case microphoneNotAuthorized
    case recognizerNotAvailable
    case requestCreationFailed
    case audioSessionError
    case audioEngineError
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition not authorized"
        case .microphoneNotAuthorized:
            return "Microphone access not authorized"
        case .recognizerNotAvailable:
            return "Speech recognizer not available"
        case .requestCreationFailed:
            return "Failed to create recognition request"
        case .audioSessionError:
            return "Audio session configuration failed"
        case .audioEngineError:
            return "Audio engine failed to start"
        }
    }
}

// MARK: - Voice Input View

struct FlowVoiceInputView: View {
    @ObservedObject var voiceManager: FlowVoiceInputManager
    let theme: AppTheme
    var onTranscriptionComplete: ((String) -> Void)?
    var onCancel: (() -> Void)?
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Listening...")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    onCancel?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            
            // Voice visualization
            voiceVisualization
            
            // Transcribed text
            if !voiceManager.transcribedText.isEmpty {
                Text(voiceManager.transcribedText)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .frame(minHeight: 50)
            } else {
                Text("Say something...")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal)
                    .frame(minHeight: 50)
            }
            
            // Action buttons
            HStack(spacing: 16) {
                // Cancel button
                Button {
                    onCancel?()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, DS.Spacing.xxl)
                        .padding(.vertical, DS.Spacing.md)
                        .background(Color.white.opacity(DS.Glass.borderMedium))
                        .cornerRadius(25)
                }
                
                // Send button
                if !voiceManager.transcribedText.isEmpty {
                    Button {
                        onTranscriptionComplete?(voiceManager.transcribedText)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 14, weight: .bold))
                            Text("Send")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, DS.Spacing.xxl)
                        .padding(.vertical, DS.Spacing.md)
                        .background(
                            LinearGradient(
                                colors: [theme.accentPrimary, theme.accentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                    }
                }
            }
            
            // Error message
            if let error = voiceManager.error {
                Text(error.localizedDescription)
                    .font(.system(size: 13))
                    .foregroundColor(.red.opacity(0.8))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.08).opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.accentPrimary.opacity(0.3), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var voiceVisualization: some View {
        ZStack {
            // Outer pulse rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(theme.accentPrimary.opacity(0.2 - Double(index) * 0.06), lineWidth: 2)
                    .frame(width: 100 + CGFloat(index * 30), height: 100 + CGFloat(index * 30))
                    .scaleEffect(voiceManager.isListening ? 1 + CGFloat(voiceManager.audioLevel) * 0.3 : 1)
                    .animation(.easeInOut(duration: 0.3), value: voiceManager.audioLevel)
            }
            
            // Center microphone button
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.accentPrimary, theme.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: theme.accentPrimary.opacity(0.4), radius: 15)
                
                Image(systemName: voiceManager.isListening ? "mic.fill" : "mic")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
        }
        .frame(height: 180)
    }
}

// MARK: - Compact Voice Button

struct FlowVoiceButton: View {
    @ObservedObject var voiceManager: FlowVoiceInputManager
    let theme: AppTheme
    var onTap: (() -> Void)?
    
    @State private var isPulsing = false
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            ZStack {
                // Pulse effect when listening
                if voiceManager.isListening {
                    Circle()
                        .fill(theme.accentPrimary.opacity(0.3))
                        .frame(width: 44, height: 44)
                        .scaleEffect(isPulsing ? 1.3 : 1)
                        .opacity(isPulsing ? 0 : 0.5)
                        .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: isPulsing)
                }
                
                Circle()
                    .fill(
                        voiceManager.isListening
                            ? LinearGradient(
                                colors: [theme.accentPrimary, theme.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.15), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: 36, height: 36)
                
                Image(systemName: voiceManager.isListening ? "mic.fill" : "mic")
                    .font(.system(size: 16))
                    .foregroundColor(voiceManager.isListening ? .white : .white.opacity(0.7))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if voiceManager.isListening {
                isPulsing = true
            }
        }
        .onChange(of: voiceManager.isListening) { _, listening in
            isPulsing = listening
        }
    }
}

// MARK: - Premium Voice Gate

struct FlowVoiceGateView: View {
    let theme: AppTheme
    var onUpgrade: (() -> Void)?
    var onDismiss: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(theme.accentPrimary.opacity(0.2))
                    .frame(width: 70, height: 70)
                
                Image(systemName: "mic.badge.plus")
                    .font(.system(size: 30))
                    .foregroundColor(theme.accentPrimary)
            }
            
            // Title
            Text("Voice Input")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            // Description
            Text("Speak to Flow and get things done hands-free. Voice input is a Pro feature.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Upgrade button
            Button {
                onUpgrade?()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                    Text("Upgrade to Pro")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [theme.accentPrimary, theme.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            // Dismiss
            Button {
                onDismiss?()
            } label: {
                Text("Maybe Later")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.08).opacity(0.95))
        )
    }
}
