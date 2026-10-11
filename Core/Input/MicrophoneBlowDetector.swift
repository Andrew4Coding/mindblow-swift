import AVFoundation
import OSLog

@Observable
final class MicrophoneBlowDetector: BlowDetecting {
    private(set) var state: BlowInputState = .idle
    private(set) var intensity: Double = 0

    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private let extractor = AudioFeatureExtractor()
    @ObservationIgnored private var estimator = BlowEstimator()
    @ObservationIgnored private var isTapInstalled = false
    @ObservationIgnored private var isStartRequested = false
    @ObservationIgnored private var observers: [any NSObjectProtocol] = []

    func start() async {
        guard state == .idle || state.isTouchOnly else { return }
        isStartRequested = true
        state = .requestingPermission

        guard await requestPermission() else {
            state = .denied
            return
        }
        guard isStartRequested else {
            state = .idle
            return
        }

        do {
            AppAudioSession.activate()
            estimator.reset()
            intensity = 0
            try startEngine()
            observeSystemEvents()
            state = .calibrating
        } catch {
            AppLog.input.error("Microphone engine failed to start: \(error.localizedDescription)")
            teardownEngine()
            state = .unavailable
        }
    }

    func stop() {
        isStartRequested = false
        removeObservers()
        teardownEngine()
        intensity = 0
        if state != .denied { state = .idle }
    }

    private func requestPermission() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: true
        case .denied: false
        case .undetermined: await AVAudioApplication.requestRecordPermission()
        @unknown default: false
        }
    }

    private func startEngine() throws {
        guard let extractor else { throw DetectorError.extractorUnavailable }
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else { throw DetectorError.noInput }

        input.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: format,
            block: Self.makeTapHandler(extractor: extractor) { [weak self] features in
                Task { @MainActor in self?.handle(features) }
            }
        )
        isTapInstalled = true

        engine.prepare()
        try engine.start()
    }

    private func teardownEngine() {
        if isTapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            isTapInstalled = false
        }
        engine.stop()
    }

    private func handle(_ features: AudioFeatures) {
        guard state == .calibrating || state == .listening else { return }
        let value = estimator.process(features)
        intensity = Double(value)
        if state == .calibrating && estimator.isCalibrated {
            state = .listening
        }
    }

    private func observeSystemEvents() {
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default
        observers = [
            center.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: AVAudioSession.sharedInstance(),
                queue: .main
            ) { [weak self] note in
                let rawType = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
                MainActor.assumeIsolated { self?.handleInterruption(rawType: rawType) }
            },
            center.addObserver(
                forName: .AVAudioEngineConfigurationChange,
                object: engine,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.restart() }
            },
        ]
    }

    private func removeObservers() {
        observers.forEach(NotificationCenter.default.removeObserver)
        observers = []
    }

    private func handleInterruption(rawType: UInt?) {
        guard let rawType, let type = AVAudioSession.InterruptionType(rawValue: rawType) else { return }
        switch type {
        case .began:
            teardownEngine()
            intensity = 0
            state = .idle
        case .ended:
            restart()
        @unknown default:
            break
        }
    }

    private func restart() {
        guard isStartRequested else { return }
        removeObservers()
        teardownEngine()
        state = .idle
        Task { await start() }
    }

    private nonisolated static func makeTapHandler(
        extractor: AudioFeatureExtractor,
        deliver: @escaping @Sendable (AudioFeatures) -> Void
    ) -> AVAudioNodeTapBlock {
        { buffer, _ in
            guard let features = extractor.extract(from: buffer) else { return }
            deliver(features)
        }
    }

    private enum DetectorError: Error {
        case extractorUnavailable
        case noInput
    }
}
