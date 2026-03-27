import Foundation
import UIKit

enum HapticsManager {
    private static let impactGenerator = UIImpactFeedbackGenerator(
        style: .light
    )
    private static let heavyImpactGenerator = UIImpactFeedbackGenerator(
        style: .heavy
    )
    private static let explosionGenerator = UINotificationFeedbackGenerator()

    private static var hapticTimer: Timer?
    private static var currentProgress: Double = 0

    static func light(intensity: Double) {
        let clamped = max(0.1, min(intensity, 1.0))
        DispatchQueue.main.async {
            impactGenerator.prepare()
            impactGenerator.impactOccurred(intensity: CGFloat(clamped))
        }
    }

    static func explosion() {
        DispatchQueue.main.async {
            stopPressureHaptics()
            // Hard double vibration
            heavyImpactGenerator.prepare()
            heavyImpactGenerator.impactOccurred(intensity: 1.0)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                heavyImpactGenerator.impactOccurred(intensity: 1.0)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                heavyImpactGenerator.impactOccurred(intensity: 1.0)
            }

            explosionGenerator.prepare()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                explosionGenerator.notificationOccurred(.error)
            }
        }
    }

    // Dynamic pressure-based haptics that accelerate with pressure
    static func startPressureHaptics(progress: Double) {
        currentProgress = progress

        // If timer doesn't exist, create it
        if hapticTimer == nil {
            // Calculate interval: at 0% pressure = 0.25s, at 100% = 0.05s
            let interval = 0.25 - (progress * 0.2)

            hapticTimer = Timer.scheduledTimer(
                withTimeInterval: max(0.05, interval),
                repeats: true
            ) { _ in
                // Trigger haptic with intensity based on current progress
                let intensity = max(0.3, min(currentProgress, 1.0))
                DispatchQueue.main.async {
                    impactGenerator.prepare()
                    impactGenerator.impactOccurred(
                        intensity: CGFloat(intensity)
                    )
                }
            }
        } else {
            // Update progress for next calculation
            currentProgress = progress
        }
    }

    static func stopPressureHaptics() {
        hapticTimer?.invalidate()
        hapticTimer = nil
        currentProgress = 0
    }
}
