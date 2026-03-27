import Foundation
import CoreHaptics

class HapticsManager {
    private static let shared = HapticsManager()
    private var engine: CHHapticEngine?
    private var pressurePlayer: CHHapticPatternPlayer?
    private var isSupported = false

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            isSupported = true
        } catch {
            print("Haptic Engine failed to start: \(error.localizedDescription)")
        }
    }

    private func playTransientHaptic(intensity: Float, sharpness: Float) {
        guard let engine = engine else { return }
        guard isSupported else { return }
        
        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensityParam, sharpnessParam],
            relativeTime: 0
        )
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play transient haptic: \(error.localizedDescription)")
        }
    }

    private func playContinuousHaptic(duration: TimeInterval, intensity: Float, sharpness: Float) {
        guard let engine = engine else { return }
        guard isSupported else { return }
        
        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensityParam, sharpnessParam],
            relativeTime: 0,
            duration: duration
        )
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            pressurePlayer = try engine.makePlayer(with: pattern)
            try pressurePlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play continuous haptic: \(error.localizedDescription)")
        }
    }

    // MARK: - Public API
    
    static func light(intensity: Double) {
        let clamped = Float(max(0.1, min(intensity, 1.0)))
        shared.playTransientHaptic(intensity: clamped, sharpness: 0.5)
    }

    static func explosion() {
        HapticsManager.stopPressureHaptics()
        
        guard let engine = shared.engine else { return }
        guard shared.isSupported else { return }
        
        // Create three rapid intense haptics followed by a final accent
        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        
        let event1 = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensityParam, sharpnessParam],
            relativeTime: 0
        )
        
        let event2 = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensityParam, sharpnessParam],
            relativeTime: 0.1
        )
        
        let event3 = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensityParam, sharpnessParam],
            relativeTime: 0.2
        )
        
        // Final accent with high sharpness
        let finalSharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let event4 = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensityParam, finalSharpnessParam],
            relativeTime: 0.3
        )
        
        do {
            let pattern = try CHHapticPattern(events: [event1, event2, event3, event4], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play explosion haptic: \(error.localizedDescription)")
        }
    }

    // Dynamic pressure-based haptics that accelerate with pressure
    static func startPressureHaptics(progress: Double) {
        let clamped = Float(max(0.1, min(progress, 1.0)))
        
        // Calculate duration: at 0% pressure = longer, at 100% = shorter
        // Using continuous haptics for smooth pressure feedback
        let duration: TimeInterval = 0.25 - (progress * 0.15)
        
        shared.playContinuousHaptic(
            duration: max(0.05, duration),
            intensity: clamped,
            sharpness: Float(progress * 0.8)
        )
    }

    static func stopPressureHaptics() {
        do {
            try shared.pressurePlayer?.stop(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to stop pressure haptic: \(error.localizedDescription)")
        }
        shared.pressurePlayer = nil
    }
}
