import CoreHaptics
import OSLog

final class CoreHapticsService: HapticsProviding {
    private static let pressureDuration: TimeInterval = 30

    var isEnabled: Bool {
        didSet {
            if !isEnabled { stopPressure() }
        }
    }

    private var engine: CHHapticEngine?
    private var pressurePlayer: CHHapticAdvancedPatternPlayer?
    private let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
        prepareEngine()
    }

    func updatePressure(progress: Double) {
        guard isEnabled, supportsHaptics else { return }
        let intensity = Float(min(1, max(0.1, progress)))
        let sharpness = Float(min(1, max(0, progress * 0.8)))

        do {
            if pressurePlayer == nil {
                pressurePlayer = try makePressurePlayer()
            }
            try pressurePlayer?.sendParameters(
                [
                    CHHapticDynamicParameter(
                        parameterID: .hapticIntensityControl,
                        value: intensity,
                        relativeTime: 0
                    ),
                    CHHapticDynamicParameter(
                        parameterID: .hapticSharpnessControl,
                        value: sharpness,
                        relativeTime: 0
                    ),
                ],
                atTime: CHHapticTimeImmediate
            )
        } catch {
            AppLog.haptics.debug("Pressure haptic ended: \(error.localizedDescription)")
            pressurePlayer = nil
        }
    }

    func stopPressure() {
        guard let player = pressurePlayer else { return }
        pressurePlayer = nil
        do {
            try player.stop(atTime: CHHapticTimeImmediate)
        } catch {
            AppLog.haptics.debug("Stopping the engine because the pressure player would not stop: \(error.localizedDescription)")
            engine?.stop()
        }
    }

    func explosion() {
        stopPressure()
        guard isEnabled, supportsHaptics else { return }

        let events = (0..<4).map { index in
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1),
                ],
                relativeTime: Double(index) * 0.1
            )
        }

        do {
            let engine = try runningEngine()
            let pattern = try CHHapticPattern(events: events, parameters: [])
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {
            AppLog.haptics.error("Explosion haptic failed: \(error.localizedDescription)")
        }
    }

    private func makePressurePlayer() throws -> CHHapticAdvancedPatternPlayer {
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0),
            ],
            relativeTime: 0,
            duration: Self.pressureDuration
        )
        let pattern = try CHHapticPattern(events: [event], parameters: [])
        let player = try runningEngine().makeAdvancedPlayer(with: pattern)
        try player.start(atTime: CHHapticTimeImmediate)
        return player
    }

    private func prepareEngine() {
        guard supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.isAutoShutdownEnabled = true
            Self.installHandlers(on: engine) { [weak self] in
                Task { @MainActor in self?.handleEngineReset() }
            }
            try engine.start()
            self.engine = engine
        } catch {
            AppLog.haptics.error("Haptic engine failed to start: \(error.localizedDescription)")
        }
    }

    private func runningEngine() throws -> CHHapticEngine {
        guard let engine else { throw CHHapticError(.engineNotRunning) }
        try engine.start()
        return engine
    }

    private func handleEngineReset() {
        pressurePlayer = nil
        engine = nil
        prepareEngine()
    }

    private nonisolated static func installHandlers(
        on engine: CHHapticEngine,
        onReset: @escaping @Sendable () -> Void
    ) {
        engine.resetHandler = onReset
        engine.stoppedHandler = { reason in
            AppLog.haptics.info("Haptic engine stopped: \(reason.rawValue)")
        }
    }
}
