import Foundation

protocol HapticsProviding: AnyObject {
    var isEnabled: Bool { get set }

    func updatePressure(progress: Double)
    func stopPressure()
    func explosion()
}
