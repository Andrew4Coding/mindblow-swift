import Foundation

final class AppEnvironment {
    let preferences: PreferencesStoring
    let leaderboard: LeaderboardStoring
    let detector: BlowDetecting
    let sound: SoundPlaying
    let haptics: HapticsProviding

    init(
        preferences: PreferencesStoring,
        leaderboard: LeaderboardStoring,
        detector: BlowDetecting,
        sound: SoundPlaying,
        haptics: HapticsProviding
    ) {
        self.preferences = preferences
        self.leaderboard = leaderboard
        self.detector = detector
        self.sound = sound
        self.haptics = haptics
    }

    static func bootstrap() -> AppEnvironment {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return .stub()
        }
        #endif
        return .live()
    }

    static func live() -> AppEnvironment {
        AppAudioSession.activate()
        let preferences = UserDefaultsPreferencesStore()
        return AppEnvironment(
            preferences: preferences,
            leaderboard: UserDefaultsLeaderboardStore(),
            detector: MicrophoneBlowDetector(),
            sound: SoundService(
                isMusicEnabled: preferences.isMusicEnabled,
                isEffectsEnabled: preferences.isSoundEffectsEnabled
            ),
            haptics: CoreHapticsService(isEnabled: preferences.isHapticsEnabled)
        )
    }

    func makeGameViewModel() -> GameViewModel {
        GameViewModel(
            detector: detector,
            sound: sound,
            haptics: haptics,
            preferences: preferences
        )
    }
}
