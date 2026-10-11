import Foundation

final class InMemoryPreferencesStore: PreferencesStoring {
    var highScore: Double
    var selectedSkin: TireSkin
    var isMusicEnabled: Bool
    var musicVolume: Double
    var effectsVolume: Double
    var isSoundEffectsEnabled: Bool
    var isHapticsEnabled: Bool

    init(
        highScore: Double = 0,
        selectedSkin: TireSkin = .car,
        isMusicEnabled: Bool = true,
        musicVolume: Double = 0.5,
        effectsVolume: Double = 1,
        isSoundEffectsEnabled: Bool = true,
        isHapticsEnabled: Bool = true
    ) {
        self.highScore = highScore
        self.selectedSkin = selectedSkin
        self.isMusicEnabled = isMusicEnabled
        self.musicVolume = musicVolume
        self.effectsVolume = effectsVolume
        self.isSoundEffectsEnabled = isSoundEffectsEnabled
        self.isHapticsEnabled = isHapticsEnabled
    }
}

final class InMemoryLeaderboardStore: LeaderboardStoring {
    private var storage: [LeaderboardEntry]

    init(entries: [LeaderboardEntry] = []) {
        storage = entries
    }

    func entries() -> [LeaderboardEntry] { storage }
    func add(_ entry: LeaderboardEntry) { storage.append(entry) }
    func removeAll() { storage = [] }
}

@Observable
final class StubBlowDetector: BlowDetecting {
    var state: BlowInputState
    var intensity: Double
    private(set) var startCount = 0
    private(set) var stopCount = 0

    init(state: BlowInputState = .listening, intensity: Double = 0) {
        self.state = state
        self.intensity = intensity
    }

    func start() async {
        startCount += 1
        if state == .idle { state = .listening }
    }

    func stop() {
        stopCount += 1
    }
}

final class SilentSoundService: SoundPlaying {
    var isMusicEnabled = true
    var isEffectsEnabled = true
    var musicVolume = 0.5
    var effectsVolume = 1.0
    private(set) var played: [SoundEffect] = []
    private(set) var stopped: [SoundEffect] = []

    func startMusic() {}
    func pauseMusic() {}
    func play(_ effect: SoundEffect) { played.append(effect) }
    func stop(_ effect: SoundEffect) { stopped.append(effect) }
}

final class NoopHaptics: HapticsProviding {
    var isEnabled = true
    private(set) var pressureUpdates: [Double] = []
    private(set) var explosionCount = 0
    private(set) var stopCount = 0

    func updatePressure(progress: Double) { pressureUpdates.append(progress) }
    func stopPressure() { stopCount += 1 }
    func explosion() { explosionCount += 1 }
}

extension AppEnvironment {
    static func stub(
        preferences: PreferencesStoring = InMemoryPreferencesStore(),
        leaderboard: LeaderboardStoring = InMemoryLeaderboardStore(),
        detector: BlowDetecting = StubBlowDetector()
    ) -> AppEnvironment {
        AppEnvironment(
            preferences: preferences,
            leaderboard: leaderboard,
            detector: detector,
            sound: SilentSoundService(),
            haptics: NoopHaptics()
        )
    }
}

extension GameViewModel {
    static func preview(
        phase: GamePhase = .playing,
        mode: GameMode = .single,
        detector: BlowDetecting = StubBlowDetector()
    ) -> GameViewModel {
        let viewModel = GameViewModel(
            detector: detector,
            sound: SilentSoundService(),
            haptics: NoopHaptics(),
            preferences: InMemoryPreferencesStore(highScore: 0.6),
            pressureRange: 20...20
        )
        viewModel.startGame(mode: mode)
        switch phase {
        case .awaitingStart, .playing:
            break
        case .finished:
            viewModel.pumpOnce()
            viewModel.tick(deltaTime: 0.3)
            viewModel.finish()
        case .exploded:
            viewModel.triggerExplosion()
        }
        return viewModel
    }
}
