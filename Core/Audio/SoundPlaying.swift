import Foundation

enum SoundEffect: Hashable {
    case explosion
    case deflating

    var resourceName: String {
        switch self {
        case .explosion: "explode"
        case .deflating: "deflating"
        }
    }

    var loops: Bool { self == .deflating }

    var volume: Float {
        switch self {
        case .explosion: 1.0
        case .deflating: 0.5
        }
    }
}

protocol SoundPlaying: AnyObject {
    var isMusicEnabled: Bool { get set }
    var isEffectsEnabled: Bool { get set }
    var musicVolume: Double { get set }
    var effectsVolume: Double { get set }

    func startMusic()
    func pauseMusic()
    func play(_ effect: SoundEffect)
    func stop(_ effect: SoundEffect)
}
