import Testing

@testable import MindBlow

@MainActor
struct GameViewModelTests {
    private func makeSUT(
        state: BlowInputState = .listening,
        intensity: Double = 0,
        highScore: Double = 0
    ) -> (GameViewModel, StubBlowDetector, InMemoryPreferencesStore, SilentSoundService, NoopHaptics) {
        let detector = StubBlowDetector(state: state, intensity: intensity)
        let preferences = InMemoryPreferencesStore(highScore: highScore)
        let sound = SilentSoundService()
        let haptics = NoopHaptics()
        let viewModel = GameViewModel(
            detector: detector,
            sound: sound,
            haptics: haptics,
            preferences: preferences,
            pressureRange: 20...20
        )
        return (viewModel, detector, preferences, sound, haptics)
    }

    @Test func startsAwaitingModeSelection() {
        let (viewModel, _, _, _, _) = makeSUT()
        #expect(viewModel.phase == .awaitingStart)
        #expect(viewModel.activeSheet == .modeSelection)
        #expect(!viewModel.canInflate)
    }

    @Test func startGameBeginsPlayingAndClosesSheet() {
        let (viewModel, _, _, _, _) = makeSUT()
        viewModel.startGame(mode: .twoPlayer)
        #expect(viewModel.phase == .playing)
        #expect(viewModel.isTwoPlayerMode)
        #expect(viewModel.activeSheet == nil)
    }

    @Test func blowingInflatesAndEventuallyExplodes() {
        let (viewModel, detector, _, sound, haptics) = makeSUT()
        viewModel.startGame(mode: .single)
        detector.intensity = 1

        viewModel.tick(deltaTime: 0.5)
        #expect(viewModel.currentPSI > 0)
        #expect(viewModel.hasBlownOnce)
        #expect(!viewModel.isExploded)

        for _ in 0..<10 { viewModel.tick(deltaTime: 0.5) }
        #expect(viewModel.isExploded)
        #expect(viewModel.currentPSI == viewModel.maxPSI)
        #expect(sound.played.contains(.explosion))
        #expect(haptics.explosionCount == 1)
        #expect(viewModel.explosionCount == 1)
    }

    @Test func idleTireDeflatesAfterDelayInSinglePlayer() {
        let (viewModel, detector, _, sound, _) = makeSUT()
        viewModel.startGame(mode: .single)
        detector.intensity = 0.5
        viewModel.tick(deltaTime: 0.5)
        let inflated = viewModel.currentPSI

        detector.intensity = 0
        viewModel.tick(deltaTime: 1.0)
        viewModel.tick(deltaTime: 0.5)
        #expect(viewModel.currentPSI < inflated)
        #expect(sound.played.contains(.deflating))
    }

    @Test func twoPlayerNeverDeflates() {
        let (viewModel, detector, _, _, _) = makeSUT()
        viewModel.startGame(mode: .twoPlayer)
        detector.intensity = 0.5
        viewModel.tick(deltaTime: 0.5)
        let inflated = viewModel.currentPSI

        detector.intensity = 0
        for _ in 0..<10 { viewModel.tick(deltaTime: 0.5) }
        #expect(viewModel.currentPSI == inflated)
    }

    @Test func finishingStoresNewHighScore() {
        let (viewModel, detector, preferences, _, _) = makeSUT(highScore: 0.1)
        viewModel.startGame(mode: .single)
        detector.intensity = 0.5
        viewModel.tick(deltaTime: 0.5)
        viewModel.finish()

        #expect(viewModel.phase == .finished)
        #expect(viewModel.scorePercent > 0.1)
        #expect(preferences.highScore == viewModel.scorePercent)
        #expect(viewModel.isHighScore)
        #expect(viewModel.canSaveScore)
    }

    @Test func cannotFinishBeforeBlowing() {
        let (viewModel, _, _, _, _) = makeSUT()
        viewModel.startGame(mode: .single)
        viewModel.finish()
        #expect(viewModel.phase == .playing)
    }

    @Test func twoPlayerPassSwitchesPlayerAfterMinimumPressure() {
        let (viewModel, detector, _, _, _) = makeSUT()
        viewModel.startGame(mode: .twoPlayer)
        #expect(!viewModel.canPass)

        detector.intensity = 0.5
        viewModel.tick(deltaTime: 0.5)
        #expect(viewModel.canPass)

        viewModel.finish()
        #expect(viewModel.currentPlayer == 2)
        #expect(!viewModel.hasBlownOnce)
        #expect(viewModel.phase == .playing)
    }

    @Test func holdingInflatesWithoutMicrophone() {
        let (viewModel, _, _, _, _) = makeSUT(state: .denied)
        viewModel.startGame(mode: .single)
        #expect(viewModel.isMicrophoneUnavailable)
        #expect(viewModel.canInflate)

        viewModel.beginHolding()
        viewModel.tick(deltaTime: 0.5)
        #expect(viewModel.currentPSI > 0)

        viewModel.endHolding()
        #expect(!viewModel.isHoldingToInflate)
    }

    @Test func doesNotInflateWhileCalibrating() {
        let (viewModel, detector, _, _, _) = makeSUT(state: .calibrating)
        viewModel.startGame(mode: .single)
        detector.intensity = 1
        viewModel.tick(deltaTime: 0.5)
        #expect(viewModel.currentPSI == 0)
        #expect(viewModel.isPreparingInput)
    }

    @Test func pumpOnceInflatesOnlyForTheBurstDuration() {
        let (viewModel, _, _, _, _) = makeSUT(state: .denied)
        viewModel.startGame(mode: .single)
        viewModel.pumpOnce()

        viewModel.tick(deltaTime: 0.2)
        let afterFirst = viewModel.currentPSI
        #expect(afterFirst > 0)

        viewModel.tick(deltaTime: 0.2)
        let afterSecond = viewModel.currentPSI
        #expect(afterSecond > afterFirst)

        viewModel.tick(deltaTime: 0.2)
        #expect(viewModel.currentPSI <= afterSecond)
    }

    @Test func selectingSkinPersistsAndChangesPumpRate() {
        let (viewModel, detector, preferences, _, _) = makeSUT()
        viewModel.selectSkin(.truck)
        #expect(preferences.selectedSkin == .truck)

        viewModel.startGame(mode: .single)
        detector.intensity = 1
        viewModel.tick(deltaTime: 0.1)
        #expect(abs(viewModel.currentPSI - 1 * 0.6 * 15 * 0.1) < 0.0001)
    }

    @Test func savingBestScoreTriggersCelebration() {
        let (viewModel, _, _, _, _) = makeSUT(highScore: 0.5)
        viewModel.didSaveScore(LeaderboardEntry(playerName: "A", score: 0.4))
        #expect(!viewModel.isCelebrating)
        viewModel.didSaveScore(LeaderboardEntry(playerName: "A", score: 0.5))
        #expect(viewModel.isCelebrating)
    }
}
