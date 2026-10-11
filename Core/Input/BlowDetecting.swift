import Foundation

enum BlowInputState: Equatable {
    case idle
    case requestingPermission
    case calibrating
    case listening
    case denied
    case unavailable

    var isTouchOnly: Bool { self == .denied || self == .unavailable }
    var acceptsInput: Bool { self == .listening || isTouchOnly }
    var isPreparing: Bool { self == .requestingPermission || self == .calibrating }
}

protocol BlowDetecting: AnyObject {
    var state: BlowInputState { get }
    var intensity: Double { get }

    func start() async
    func stop()
}
