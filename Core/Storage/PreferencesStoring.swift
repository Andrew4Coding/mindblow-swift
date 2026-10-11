import Foundation

protocol PreferencesStoring: AnyObject {
    var highScore: Double { get set }
    var selectedSkin: TireSkin { get set }
    var isMusicEnabled: Bool { get set }
    var isSoundEffectsEnabled: Bool { get set }
    var isHapticsEnabled: Bool { get set }
}

final class UserDefaultsPreferencesStore: PreferencesStoring {
    private enum Key {
        static let highScore = "HighScorePercent"
        static let selectedSkin = "SelectedTireSkin"
        static let music = "MusicEnabled"
        static let soundEffects = "SoundEffectsEnabled"
        static let haptics = "HapticsEnabled"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var highScore: Double {
        get { defaults.double(forKey: Key.highScore) }
        set { defaults.set(newValue, forKey: Key.highScore) }
    }

    var selectedSkin: TireSkin {
        get {
            guard let data = defaults.data(forKey: Key.selectedSkin),
                let skin = try? JSONDecoder().decode(TireSkin.self, from: data)
            else { return .car }
            return skin
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            defaults.set(data, forKey: Key.selectedSkin)
        }
    }

    var isMusicEnabled: Bool {
        get { bool(Key.music) }
        set { defaults.set(newValue, forKey: Key.music) }
    }

    var isSoundEffectsEnabled: Bool {
        get { bool(Key.soundEffects) }
        set { defaults.set(newValue, forKey: Key.soundEffects) }
    }

    var isHapticsEnabled: Bool {
        get { bool(Key.haptics) }
        set { defaults.set(newValue, forKey: Key.haptics) }
    }

    private func bool(_ key: String) -> Bool {
        defaults.object(forKey: key) as? Bool ?? true
    }
}
