import Foundation
import Observation
import SwiftUI

enum GamePhase: Equatable {
    case awaitingStart
    case playing
    case finished
    case exploded
}

enum GameSheet: Hashable, Identifiable {
    case modeSelection
    case howToPlay
    case leaderboard
    case skins
    case settings
    case saveScore

    var id: Self { self }
}

@Observable
final class GameViewModel {
    private enum Tuning {
        static let inflationRatePerSecond = 15.0
        static let deflationRatePerSecond = 5.0
        static let deflationDelay = 1.0
        static let blowThreshold = 0.05
        static let minimumPSIToPass = 2.0
        static let manualInflateIntensity = 0.5
        static let manualPulseDuration = 0.3
        static let tickInterval: Duration = .milliseconds(50)
        static let maxTickDelta = 0.2
        static let celebrationDuration: Duration = .seconds(4)
    }

    private(set) var phase: GamePhase = .awaitingStart
    private(set) var gameMode: GameMode = .single
    private(set) var currentPSI = 0.0
    private(set) var maxPSI: Double
    private(set) var scorePercent = 0.0
    private(set) var highScore: Double
    private(set) var hasBlownOnce = false
    private(set) var currentPlayerIndex = 0
    private(set) var selectedSkin: TireSkin
    private(set) var isHoldingToInflate = false
    private(set) var explosionCount = 0
    private(set) var isCelebrating = false
    var activeSheet: GameSheet? = .modeSelection

    private let detector: BlowDetecting
    private let sound: SoundPlaying
    private let haptics: HapticsProviding
    private let preferences: PreferencesStoring
    private let pressureRange: ClosedRange<Double>
    private var timeSinceLastBlow = 0.0
    private var manualPulseRemaining = 0.0
    private var celebrationTask: Task<Void, Never>?
    private var needsResume = false

    init(
        detector: BlowDetecting,
        sound: SoundPlaying,
        haptics: HapticsProviding,
        preferences: PreferencesStoring,
        pressureRange: ClosedRange<Double> = 18...32
    ) {
        self.detector = detector
        self.sound = sound
        self.haptics = haptics
        self.preferences = preferences
        self.pressureRange = pressureRange
        self.maxPSI = Double.random(in: pressureRange)
        self.highScore = preferences.highScore
        self.selectedSkin = preferences.selectedSkin
        sound.startMusic()
    }

    var isTwoPlayerMode: Bool { gameMode == .twoPlayer }
    var currentPlayer: Int { currentPlayerIndex + 1 }
    var hasStartedGame: Bool { phase != .awaitingStart }
    var isExploded: Bool { phase == .exploded }
    var isFinished: Bool { phase == .finished || phase == .exploded }

    var normalizedPressure: Double {
        maxPSI == 0 ? 0 : min(1, currentPSI / maxPSI)
    }

    var scorePercentInt: Int { Int(scorePercent * 100) }

    var isHighScore: Bool {
        phase == .finished && scorePercent > 0 && scorePercent >= highScore
    }

    var inputState: BlowInputState { detector.state }
    var blowIntensity: Double { detector.state == .listening ? detector.intensity : 0 }

    var isPreparingInput: Bool { hasStartedGame && detector.state.isPreparing }
    var isMicrophoneUnavailable: Bool { hasStartedGame && detector.state.isTouchOnly }
    var canInflate: Bool { phase == .playing && detector.state.acceptsInput }
    var showsBlowPrompt: Bool { phase == .playing && detector.state == .listening && activeSheet == nil }
    var showsBlowGauge: Bool { phase == .playing && detector.state == .listening }

    var canPass: Bool {
        isTwoPlayerMode && phase == .playing && hasBlownOnce && currentPSI >= Tuning.minimumPSIToPass
    }

    var canEndRun: Bool {
        !isTwoPlayerMode && phase == .playing && hasBlownOnce
    }

    var canSaveScore: Bool {
        !isTwoPlayerMode && phase == .finished
    }

    func startGame(mode: GameMode) {
        gameMode = mode
        activeSheet = nil
        startNewSession()
    }

    func startNewSession() {
        maxPSI = Double.random(in: pressureRange)
        currentPSI = 0
        scorePercent = 0
        hasBlownOnce = false
        currentPlayerIndex = 0
        timeSinceLastBlow = 0
        manualPulseRemaining = 0
        isHoldingToInflate = false
        phase = .playing
        haptics.stopPressure()
        sound.stop(.deflating)
        startDetector()
    }

    func tick(deltaTime: Double) {
        guard canInflate else {
            haptics.stopPressure()
            return
        }

        let isManual = isHoldingToInflate || manualPulseRemaining > 0
        manualPulseRemaining = max(0, manualPulseRemaining - deltaTime)
        let blow = blowIntensity

        if blow > Tuning.blowThreshold || isManual {
            hasBlownOnce = true
            timeSinceLastBlow = 0
            sound.stop(.deflating)
            let intensity = max(blow, isManual ? Tuning.manualInflateIntensity : 0)
            currentPSI += intensity * selectedSkin.pumpMultiplier * Tuning.inflationRatePerSecond * deltaTime
            haptics.updatePressure(progress: normalizedPressure)
            if currentPSI >= maxPSI {
                triggerExplosion()
            }
        } else {
            if !isTwoPlayerMode {
                timeSinceLastBlow += deltaTime
                if timeSinceLastBlow >= Tuning.deflationDelay && currentPSI > 0 {
                    currentPSI = max(0, currentPSI - Tuning.deflationRatePerSecond * deltaTime)
                    sound.play(.deflating)
                } else {
                    sound.stop(.deflating)
                }
            }
            haptics.stopPressure()
        }
    }

    func finish() {
        if isTwoPlayerMode {
            guard canPass else { return }
            currentPlayerIndex = currentPlayerIndex == 0 ? 1 : 0
            hasBlownOnce = false
            isHoldingToInflate = false
            sound.stop(.deflating)
        } else {
            guard canEndRun else { return }
            phase = .finished
            isHoldingToInflate = false
            haptics.stopPressure()
            sound.stop(.deflating)
            scorePercent = normalizedPressure
            if scorePercent > highScore {
                highScore = scorePercent
                preferences.highScore = scorePercent
            }
        }
    }

    func triggerExplosion() {
        guard phase == .playing else { return }
        phase = .exploded
        explosionCount += 1
        isHoldingToInflate = false
        currentPSI = maxPSI
        sound.play(.explosion)
        sound.stop(.deflating)
        haptics.explosion()
    }

    func beginHolding() {
        guard canInflate else { return }
        isHoldingToInflate = true
    }

    func endHolding() {
        isHoldingToInflate = false
    }

    func pumpOnce() {
        guard canInflate else { return }
        manualPulseRemaining = Tuning.manualPulseDuration
    }

    func selectSkin(_ skin: TireSkin) {
        selectedSkin = skin
        preferences.selectedSkin = skin
    }

    func didSaveScore(_ entry: LeaderboardEntry) {
        guard entry.score >= highScore else { return }
        celebrate()
    }

    func present(_ sheet: GameSheet) {
        activeSheet = sheet
    }

    func scenePhaseDidChange(_ scenePhase: ScenePhase) {
        switch scenePhase {
        case .background:
            endHolding()
            haptics.stopPressure()
            sound.stop(.deflating)
            sound.pauseMusic()
            if hasStartedGame {
                needsResume = true
                detector.stop()
            }
        case .active:
            sound.startMusic()
            if needsResume {
                needsResume = false
                startDetector()
            }
        default:
            break
        }
    }

    func runLoop() async {
        let clock = ContinuousClock()
        var last = clock.now
        while !Task.isCancelled {
            do {
                try await clock.sleep(for: Tuning.tickInterval)
            } catch {
                return
            }
            let now = clock.now
            let delta = min(Tuning.maxTickDelta, last.duration(to: now).seconds)
            last = now
            tick(deltaTime: delta)
        }
    }

    private func startDetector() {
        Task { await detector.start() }
    }

    private func celebrate() {
        celebrationTask?.cancel()
        isCelebrating = true
        celebrationTask = Task { [weak self] in
            try? await Task.sleep(for: Tuning.celebrationDuration)
            guard !Task.isCancelled else { return }
            self?.isCelebrating = false
        }
    }
}
