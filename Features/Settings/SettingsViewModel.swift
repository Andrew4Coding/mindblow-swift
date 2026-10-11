import Foundation
import Observation

@Observable
final class SettingsViewModel {
    var isMusicEnabled: Bool {
        didSet {
            preferences.isMusicEnabled = isMusicEnabled
            sound.isMusicEnabled = isMusicEnabled
        }
    }

    var musicVolume: Double {
        didSet {
            preferences.musicVolume = musicVolume
            sound.musicVolume = musicVolume
        }
    }

    var effectsVolume: Double {
        didSet {
            preferences.effectsVolume = effectsVolume
            sound.effectsVolume = effectsVolume
        }
    }

    var isSoundEffectsEnabled: Bool {
        didSet {
            preferences.isSoundEffectsEnabled = isSoundEffectsEnabled
            sound.isEffectsEnabled = isSoundEffectsEnabled
        }
    }

    var isHapticsEnabled: Bool {
        didSet {
            preferences.isHapticsEnabled = isHapticsEnabled
            haptics.isEnabled = isHapticsEnabled
        }
    }

    private let preferences: PreferencesStoring
    private let sound: SoundPlaying
    private let haptics: HapticsProviding

    init(preferences: PreferencesStoring, sound: SoundPlaying, haptics: HapticsProviding) {
        self.preferences = preferences
        self.sound = sound
        self.haptics = haptics
        self.isMusicEnabled = preferences.isMusicEnabled
        self.musicVolume = preferences.musicVolume
        self.effectsVolume = preferences.effectsVolume
        self.isSoundEffectsEnabled = preferences.isSoundEffectsEnabled
        self.isHapticsEnabled = preferences.isHapticsEnabled
    }

    var versionDescription: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
