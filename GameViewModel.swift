import AVFoundation
import Foundation
import SwiftUI

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
    private let deflationRatePerSecond: Double = 5
    private let deflationDelay: Double = 1.0
    private var timeSinceLastBlow: Double = 0
    private let sessionRange: ClosedRange<Double>
    private let userDefaults: UserDefaults
    private let highScoreKey = "HighScorePercent"
    private var explosionPlayer: AVAudioPlayer?
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var deflatingPlayer: AVAudioPlayer?

    init(
        range: ClosedRange<Double> = 18...32,
        userDefaults: UserDefaults = .standard
    ) {
        self.sessionRange = range
        self.userDefaults = userDefaults
        self.highScore = userDefaults.double(forKey: highScoreKey)
        self.maxPSI = Double.random(in: range)
        
        startBackgroundMusic()
    }

    func startNewSession() {
        maxPSI = Double.random(in: sessionRange)
        currentPSI = 0
        isFinished = false
        isExploded = false
        scorePercent = 0
        hasBlownOnce = false
        timeSinceLastBlow = 0
        HapticsManager.stopPressureHaptics()
    }

    func update(blowIntensity: Double, deltaTime: Double, isCalibrated: Bool) {
        guard isCalibrated else {
            HapticsManager.stopPressureHaptics()
            return
        }

        guard !isFinished else {
            HapticsManager.stopPressureHaptics()
            return
        }

        if blowIntensity > blowThreshold {
            hasBlownOnce = true
            timeSinceLastBlow = 0
            stopDeflatingSound()
            let increment = blowIntensity * inflationRatePerSecond * deltaTime
            currentPSI += increment
            let progress = min(1, currentPSI / maxPSI)
            HapticsManager.startPressureHaptics(progress: progress)
            if currentPSI >= maxPSI {
                triggerExplosion()
            }
        } else {
            timeSinceLastBlow += deltaTime
            if timeSinceLastBlow >= deflationDelay && currentPSI > 0 {
                let deflation = deflationRatePerSecond * deltaTime
                currentPSI = max(0, currentPSI - deflation)
                playDeflatingSound()
            } else {
                stopDeflatingSound()
            }
            HapticsManager.stopPressureHaptics()
        }
    }

    func finish() {
        guard hasBlownOnce && !isFinished else { return }
        withAnimation {
            isFinished = true
        }
        HapticsManager.stopPressureHaptics()
        scorePercent = min(1, currentPSI / maxPSI)
        if scorePercent > highScore {
            highScore = scorePercent
            userDefaults.set(highScore, forKey: highScoreKey)
        }
    }

    func triggerExplosion() {
        isExploded = true
        withAnimation {
            isFinished = true
        }
        currentPSI = maxPSI
        playExplosionSFX()
        stopDeflatingSound()
        HapticsManager.explosion()
    }

    private func playDeflatingSound() {
        guard
            let url = Bundle.main.url(
                forResource: "deflating",
                withExtension: "mp3"
            )
        else {
            print("deflating.mp3 not found in bundle")
            return
        }

        do {
            if deflatingPlayer == nil || deflatingPlayer?.url != url {
                deflatingPlayer = try AVAudioPlayer(contentsOf: url)
                deflatingPlayer?.numberOfLoops = -1
                deflatingPlayer?.volume = 0.5
                deflatingPlayer?.prepareToPlay()
            }

            if !(deflatingPlayer?.isPlaying ?? false) {
                deflatingPlayer?.currentTime = 0
                deflatingPlayer?.play()
            }
        } catch {
            print("Failed to play deflating sound: \(error)")
        }
    }

    private func stopDeflatingSound() {
        if deflatingPlayer?.isPlaying == true {
            deflatingPlayer?.stop()
        }
    }

    // MARK: - Audio

    private func playExplosionSFX() {
        guard
            let url = Bundle.main.url(
                forResource: "explode",
                withExtension: "mp3"
            )
        else {
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
            explosionPlayer?.setVolume(1, fadeDuration: 0)
            explosionPlayer?.play()
        } catch {
            print("Failed to play explosion sound: \(error)")
        }
    }

    private func startBackgroundMusic() {
        guard
            let url = Bundle.main.url(
                forResource: "bgmusic",
                withExtension: "mp3"
            )
        else {
            print("bgmusic.mp3 not found in bundle")
            return
        }

        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.numberOfLoops = -1
            backgroundMusicPlayer?.volume = 0.2
            backgroundMusicPlayer?.prepareToPlay()
            backgroundMusicPlayer?.play()
        } catch {
            print("Failed to play background music: \(error)")
        }
    }
}
