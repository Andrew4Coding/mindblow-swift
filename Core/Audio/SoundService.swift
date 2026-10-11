import AVFoundation
import OSLog

enum AppAudioSession {
    static func activate() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [.mixWithOthers, .defaultToSpeaker]
            )
            try session.setActive(true)
            try session.setAllowHapticsAndSystemSoundsDuringRecording(true)
        } catch {
            AppLog.audio.error("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
}

final class SoundService: SoundPlaying {
    private static let musicGain: Float = 0.4

    var isMusicEnabled: Bool {
        didSet {
            guard isMusicEnabled != oldValue else { return }
            isMusicEnabled ? startMusic() : pauseMusic()
        }
    }

    var isEffectsEnabled: Bool {
        didSet {
            if !isEffectsEnabled { effectPlayers.values.forEach { $0.stop() } }
        }
    }

    var musicVolume: Double {
        didSet { musicPlayer?.volume = Float(musicVolume) * Self.musicGain }
    }

    var effectsVolume: Double {
        didSet {
            for (effect, player) in effectPlayers {
                player.volume = effect.volume * Float(effectsVolume)
            }
        }
    }

    private var effectPlayers: [SoundEffect: AVAudioPlayer] = [:]
    private var musicPlayer: AVAudioPlayer?

    init(isMusicEnabled: Bool, isEffectsEnabled: Bool, musicVolume: Double = 0.5, effectsVolume: Double = 1) {
        self.isMusicEnabled = isMusicEnabled
        self.isEffectsEnabled = isEffectsEnabled
        self.musicVolume = musicVolume
        self.effectsVolume = effectsVolume
    }

    func startMusic() {
        guard isMusicEnabled else { return }
        if musicPlayer == nil {
            musicPlayer = makePlayer(resource: "bgmusic", loops: true, volume: Float(musicVolume) * Self.musicGain)
        }
        guard let musicPlayer, !musicPlayer.isPlaying else { return }
        musicPlayer.play()
    }

    func pauseMusic() {
        musicPlayer?.pause()
    }

    func play(_ effect: SoundEffect) {
        guard isEffectsEnabled, let player = effectPlayer(for: effect) else { return }
        if effect.loops {
            guard !player.isPlaying else { return }
        }
        player.currentTime = 0
        player.play()
    }

    func stop(_ effect: SoundEffect) {
        guard let player = effectPlayers[effect], player.isPlaying else { return }
        player.stop()
    }

    private func effectPlayer(for effect: SoundEffect) -> AVAudioPlayer? {
        if let existing = effectPlayers[effect] { return existing }
        guard
            let player = makePlayer(
                resource: effect.resourceName,
                loops: effect.loops,
                volume: effect.volume * Float(effectsVolume)
            )
        else { return nil }
        effectPlayers[effect] = player
        return player
    }

    private func makePlayer(resource: String, loops: Bool, volume: Float) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "mp3") else {
            AppLog.audio.error("Missing audio resource \(resource).mp3")
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = loops ? -1 : 0
            player.volume = volume
            player.prepareToPlay()
            return player
        } catch {
            AppLog.audio.error("Failed to load \(resource).mp3: \(error.localizedDescription)")
            return nil
        }
    }
}
