import Foundation
import UIKit

enum HapticsManager {
    private static let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let explosionGenerator = UINotificationFeedbackGenerator()

    static func light(intensity: Double) {
        let clamped = max(0.1, min(intensity, 1.0))
        DispatchQueue.main.async {
            impactGenerator.prepare()
            impactGenerator.impactOccurred(intensity: CGFloat(clamped))
        }
    }

    static func explosion() {
        DispatchQueue.main.async {
            explosionGenerator.prepare()
            explosionGenerator.notificationOccurred(.error)
        }
    }
}
