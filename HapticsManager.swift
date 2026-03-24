import Foundation
import UIKit

enum HapticsManager {
    static func light(intensity: Double) {
        let clamped = max(0.1, min(intensity, 1.0))
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: CGFloat(clamped))
    }

    static func explosion() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}
