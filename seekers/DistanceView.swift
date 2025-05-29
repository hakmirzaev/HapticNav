import SwiftUI
import ARKit
import RealityKit
import AVFoundation
import CoreHaptics

// MARK: - Audio Engine
class AudioEngine {
    let synthesizer = AVSpeechSynthesizer()
    private var lastAnnouncementTime: Date = Date()
    private let minimumAnnouncementInterval: TimeInterval = 5.0
    @Published var voiceLanguage: String = "en-US"
    
    func speak(_ message: String) {
        let currentTime = Date()
        guard currentTime.timeIntervalSince(lastAnnouncementTime) >= minimumAnnouncementInterval else {
            return
        }
        
        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = AVSpeechSynthesisVoice(language: voiceLanguage)
        utterance.rate = 0.5
        utterance.volume = 1.0
        synthesizer.speak(utterance)
        lastAnnouncementTime = currentTime
    }
    
    // Método para detener la voz
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

// MARK: - Haptic Engine
class HapticEngine {
    private var engine: CHHapticEngine?
    
    init() {
        prepareHapticEngine()
    }
    
    // Cambiar la visibilidad del método a internal o public
    func prepareHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            
            engine?.resetHandler = { [weak self] in
                print("Restarting Haptic Engine...")
                do {
                    try self?.engine?.start()
                } catch {
                    print("Failed to restart engine: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Failed to start haptic engine: \(error.localizedDescription)")
        }
    }
    
    func playObstacleWarning(intensity: Float) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = engine else { return }
        
        do {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error.localizedDescription)")
        }
    }
}


// MARK: - Obstacle Detection Manager
class ObstacleDetectionManager: NSObject, ObservableObject, ARSessionDelegate {
    var arView: ARView!
    let hapticEngine: HapticEngine
    let audioEngine: AudioEngine
    
    @Published var currentDistance: Double = 5.0
    @Published var obstacleDirection: String = "Clear"
    @Published var lowerHeightObstacleDetected: Bool = false
    
    private var hasAnnouncedObstacle: Bool = false
    private var hasAnnouncedLowerHeightObstacle: Bool = false
    private var lastObstacleDirection: String = "Clear"
    
    // Estados de audio y haptics
    var isAudioEnabled: Bool = true
    var isHapticEnabled: Bool = true
    
    override init() {
        hapticEngine = HapticEngine()
        audioEngine = AudioEngine()
        super.init()
        setupAR()
    }
    
    private func setupAR() {
        guard ARWorldTrackingConfiguration.isSupported else {
            audioEngine.speak(audioEngine.voiceLanguage == "en-US" ? "AR is not supported on this device" : "Bu qurilmada AR qo‘llab-quvvatlanmaydi")
            return
        }
        
        arView = ARView(frame: .zero)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        if type(of: configuration).supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics = .sceneDepth
        }
        
        arView.session.run(configuration)
        arView.session.delegate = self
        
        audioEngine.speak(audioEngine.voiceLanguage == "en-US" ? "Navigation assistant ready" : "Navigatsiya yordamchisi tayyor")
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let depthMap = frame.sceneDepth?.depthMap else { return }
        processDepthMap(depthMap)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("AR Session failed: \(error.localizedDescription)")
        if isAudioEnabled {
            audioEngine.speak(audioEngine.voiceLanguage == "en-US" ? "Navigation system encountered an error" : "Navigatsiya tizimida xatolik yuz berdi")
        }
    }
    
    private func processDepthMap(_ depthMap: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else { return }
        let floatBuffer = baseAddress.assumingMemoryBound(to: Float32.self)
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)
        
        // Define regions for directional detection
        let regionWidth = width / 3
        var regionDepths: [String: Float] = [:]
        let regions = [
            "Left": 0..<regionWidth,
            "Center": regionWidth..<(2 * regionWidth),
            "Right": (2 * regionWidth)..<width
        ]
        
        // Track lower-height obstacles
        var lowerHeightObstacleDetected = false
        
        // Process each region at multiple heights (middle and lower)
        for (region, xRange) in regions {
            var totalDepth: Float = 0
            var samplesCount = 0
            
            for x in xRange {
                // Sample from multiple heights
                for y in [height / 2, height * 3 / 4] {
                    let offset = (y * bytesPerRow / MemoryLayout<Float32>.stride) + Int(x)
                    let depth = floatBuffer[offset]
                    
                    if depth > 0 && depth < 5.0 {
                        totalDepth += depth
                        samplesCount += 1
                        
                        // Check for lower-height obstacles
                        if y >= height * 3 / 4 && depth < 1.5 {
                            lowerHeightObstacleDetected = true
                        }
                    }
                }
            }
            
            if samplesCount > 0 {
                regionDepths[region] = totalDepth / Float(samplesCount)
            }
        }
        
        DispatchQueue.main.async {
            // Update overall distance and haptic feedback
            if let center = regionDepths["Center"] {
                self.currentDistance = Double(center)
                if self.isHapticEnabled {
                    self.provideFeedback(depth: Double(center))
                }
            }
            
            // Update obstacle direction
            if let left = regionDepths["Left"], let center = regionDepths["Center"], let right = regionDepths["Right"] {
                if center < 1.0 {
                    self.obstacleDirection = "Center"
                } else if left < 1.0 {
                    self.obstacleDirection = "Left"
                } else if right < 1.0 {
                    self.obstacleDirection = "Right"
                } else {
                    self.obstacleDirection = "Clear"
                }
                
                // Announce obstacle only if the direction has changed
                if self.obstacleDirection != self.lastObstacleDirection {
                    self.announceObstacle(direction: self.obstacleDirection)
                    self.lastObstacleDirection = self.obstacleDirection
                }
            }
            
            // Announce lower-height obstacles
            if lowerHeightObstacleDetected && !self.hasAnnouncedLowerHeightObstacle {
                if self.isAudioEnabled {
                    self.audioEngine.speak(self.audioEngine.voiceLanguage == "en-US" ? "Lower-height obstacle detected" : "Pastroq balandlikdagi to'siq aniqlandi")
                }
                self.hasAnnouncedLowerHeightObstacle = true
            } else if !lowerHeightObstacleDetected {
                self.hasAnnouncedLowerHeightObstacle = false
            }
        }
    }
    
    private func announceObstacle(direction: String) {
        guard direction != "Clear" else {
            hasAnnouncedObstacle = false // Reset announcement state
            return
        }
        
        guard !hasAnnouncedObstacle else { return } // Announce only once
        
        if isAudioEnabled {
            switch direction {
            case "Center":
                audioEngine.speak(audioEngine.voiceLanguage == "en-US" ? "Obstacle directly ahead" : "To'g'ridan-to'g'ri oldinda")
            case "Left":
                audioEngine.speak(audioEngine.voiceLanguage == "en-US" ? "Obstacle to your left" : "Chap tomoningizda to'siq")
            case "Right":
                audioEngine.speak(audioEngine.voiceLanguage == "en-US" ? "Obstacle to your right" : "O'ng tomoningizdagi to'siq")
            default:
                break
            }
        }
        
        hasAnnouncedObstacle = true // Mark as announced
    }
    
    private func provideFeedback(depth: Double) {
        // Haptic feedback intensity increases as obstacle gets closer
        let maxDistance: Double = 5.0
        let intensity = Float((maxDistance - min(depth, maxDistance)) / maxDistance)
        
        if isHapticEnabled {
            hapticEngine.playObstacleWarning(intensity: intensity)
        }
        
        // Audio feedback only within 2 meters
        if depth < 2.0 {
            if depth < 1.0 && isAudioEnabled {
                audioEngine.speak(audioEngine.voiceLanguage == "en-US" ? "Obstacle very close, proceed with caution" : "To'siq juda yaqin, ehtiyotkorlik bilan davom eting")
            } else if isAudioEnabled {
                audioEngine.speak(audioEngine.voiceLanguage == "en-US" ? "Obstacle detected at \(String(format: "%.1f", depth)) meters" : "\(String(format: "%.1f", depth)) metrda toʻsiq aniqlandi")
            }
        }
    }
    
    func stopSession() {
        arView.session.pause()
        if isAudioEnabled {
            audioEngine.speak(audioEngine.voiceLanguage == "en-US" ? "Navigation assistant stopped" : "Navigatsiya yordamchisi toʻxtadi")
        }
    }
}

// MARK: - Visual Overlay View
struct VisualOverlayView: View {
    @Binding var obstacleDirection: String
    @Binding var lowerHeightObstacleDetected: Bool

    var body: some View {
        ZStack {
            if obstacleDirection == "Left" {
                Text("⬅️").font(.largeTitle).foregroundColor(.red)
            } else if obstacleDirection == "Right" {
                Text("➡️").font(.largeTitle).foregroundColor(.red)
            } else if obstacleDirection == "Center" {
                Text("⬆️").font(.largeTitle).foregroundColor(.red)
            } else {
                Text("✔️ Clear").font(.largeTitle).foregroundColor(.green)
            }
            
            if lowerHeightObstacleDetected {
                Text("⚠️ Lower-height obstacle").font(.headline).foregroundColor(.orange)
            }
        }
    }
}

// MARK: - Content View
struct DistanceView: View {
    @ObservedObject var obstacleManager: ObstacleDetectionManager
    
    var body: some View {
        ZStack {
            ARViewContainer(obstacleManager: obstacleManager)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                VStack {
                    Text(String(format: "%.2f meters", obstacleManager.currentDistance))
                        .font(.title2)
                    
                    if obstacleManager.currentDistance < 1.0 {
                        Text("⚠️ Obstacle Nearby!")
                            .foregroundColor(.red)
                            .font(.headline)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                VisualOverlayView(obstacleDirection: $obstacleManager.obstacleDirection,
                                 lowerHeightObstacleDetected: $obstacleManager.lowerHeightObstacleDetected)
                    .padding()
                
                Text("Move the device around to detect obstacles")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
            }
            .padding()
        }
    }
}


// MARK: - ARViewContainer
struct ARViewContainer: UIViewRepresentable {
    var obstacleManager: ObstacleDetectionManager
    
    func makeUIView(context: Context) -> ARView {
        return obstacleManager.arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}
