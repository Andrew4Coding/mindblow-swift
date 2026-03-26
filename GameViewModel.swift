import Foundation
import SwiftUI
import AVFoundation

@Observable
final class GameViewModel {
    var maxPSI: Double
    var currentPSI: Double = 0
    var isFinished: Bool = false
    var isExploded: Bool = false
    var scorePercent: Double = 0
    var highScore: Double
    var hasBlownOnce: Bool = false

    private let inflationRatePerSecond: Double = 15
    private let blowThreshold: Double = 0.05
    private let sessionRange: ClosedRange<Double>
    private let userDefaults: UserDefaults
    private let highScoreKey = "HighScorePercent"
    private var isBlowAudioPlaying = false
    private var lastLightHaptic: Date = .distantPast
    private var explosionPlayer: AVAudioPlayer?

    init(
        range: ClosedRange<Double> = 18...32,
        userDefaults: UserDefaults = .standard
    ) {
        self.sessionRange = range
        self.userDefaults = userDefaults
        self.highScore = userDefaults.double(forKey: highScoreKey)
        self.maxPSI = Double.random(in: range)
    }

    func startNewSession() {
        maxPSI = Double.random(in: sessionRange)
        currentPSI = 0
        isFinished = false
        isExploded = false
        scorePercent = 0
        hasBlownOnce = false
        stopBlowAudioLoop()
    }

    func update(blowIntensity: Double, deltaTime: Double, isCalibrated: Bool) {
        guard isCalibrated else {
            stopBlowAudioLoop()
            return
        }

        guard !isFinished else {
            stopBlowAudioLoop()
            return
        }

        if blowIntensity > blowThreshold {
            hasBlownOnce = true
            startBlowAudioLoop()
            let increment = blowIntensity * inflationRatePerSecond * deltaTime
            currentPSI += increment
            let progress = min(1, currentPSI / maxPSI)
            applyInflationHapticIfNeeded(progress: progress)
            if currentPSI >= maxPSI {
                triggerExplosion()
            }
        } else {
            stopBlowAudioLoop()
        }
    }

    func finish() {
        guard hasBlownOnce && !isFinished else { return }
        isFinished = true
        stopBlowAudioLoop()
        scorePercent = min(1, currentPSI / maxPSI)
        if scorePercent > highScore {
            highScore = scorePercent
            userDefaults.set(highScore, forKey: highScoreKey)
        }
    }

    func triggerExplosion() {
        isExploded = true
        isFinished = true
        currentPSI = maxPSI
        stopBlowAudioLoop()
        playExplosionSFX()
        HapticsManager.explosion()
    }

    private func applyInflationHapticIfNeeded(progress: Double) {
        let now = Date()
        if now.timeIntervalSince(lastLightHaptic) > 0.18 {
            lastLightHaptic = now
            let clamped = max(0.2, min(progress, 1.0))
            HapticsManager.light(intensity: clamped)
        }
    }

    // MARK: - Audio placeholders

    private func startBlowAudioLoop() {
        guard !isBlowAudioPlaying else { return }
        isBlowAudioPlaying = true
        // TODO: Start looping blow sound effect here.
    }

    private func stopBlowAudioLoop() {
        guard isBlowAudioPlaying else { return }
        isBlowAudioPlaying = false
        // TODO: Stop blow loop audio here.
    }

    private func playExplosionSFX() {
        guard let url = Bundle.main.url(forResource: "explode", withExtension: "mp3") else {
            print("explode.mp3 not found in bundle")
            return
        }

        do {
            if explosionPlayer == nil || explosionPlayer?.url != url {
                explosionPlayer = try AVAudioPlayer(contentsOf: url)
                explosionPlayer?.numberOfLoops = 0
                explosionPlayer?.prepareToPlay()
            }

            explosionPlayer?.currentTime = 0
            explosionPlayer?.setVolume(1.0, fadeDuration: 0)
            explosionPlayer?.play()
        } catch {
            print("Failed to play explosion sound: \(error)")
        }
    }
}
