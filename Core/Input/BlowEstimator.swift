import Foundation

nonisolated struct BlowEstimator: Sendable {
    private let requiredCalibrationFrames: Int
    private let smoothing: Float = 0.2

    private var baseNoiseRMS: Float = 0
    private var baseHighFrequencyNoise: Float = 0
    private var calibrationFrames = 0
    private var previousIntensity: Float = 0

    var isCalibrated: Bool { calibrationFrames >= requiredCalibrationFrames }

    init(requiredCalibrationFrames: Int = 40) {
        self.requiredCalibrationFrames = requiredCalibrationFrames
    }

    mutating func reset() {
        self = BlowEstimator(requiredCalibrationFrames: requiredCalibrationFrames)
    }

    mutating func process(_ features: AudioFeatures) -> Float {
        guard isCalibrated else {
            let count = Float(calibrationFrames)
            baseNoiseRMS = (baseNoiseRMS * count + features.rms) / (count + 1)
            baseHighFrequencyNoise =
                (baseHighFrequencyNoise * count + features.highFrequencyEnergy) / (count + 1)
            calibrationFrames += 1
            return 0
        }

        let isLoud = features.rms > baseNoiseRMS * 1.5 + 0.01
        let hasHighFrequencyNoise =
            features.highFrequencyEnergy > baseHighFrequencyNoise * 2 + 0.03

        var target: Float = 0
        if isLoud && hasHighFrequencyNoise {
            let minEnergy = baseHighFrequencyNoise + 0.03
            let maxEnergy: Float = 0.5
            target = max(0, min((features.highFrequencyEnergy - minEnergy) / (maxEnergy - minEnergy), 1))
        }

        previousIntensity = previousIntensity * (1 - smoothing) + target * smoothing
        return previousIntensity
    }
}
