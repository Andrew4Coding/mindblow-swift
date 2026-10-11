import Testing

@testable import MindBlow

struct BlowEstimatorTests {
    private let quiet = AudioFeatures(rms: 0.01, highFrequencyEnergy: 0.01)
    private let loudBlow = AudioFeatures(rms: 0.3, highFrequencyEnergy: 0.4)

    private func calibrated() -> BlowEstimator {
        var estimator = BlowEstimator(requiredCalibrationFrames: 5)
        for _ in 0..<5 { _ = estimator.process(quiet) }
        return estimator
    }

    @Test func reportsZeroUntilCalibrated() {
        var estimator = BlowEstimator(requiredCalibrationFrames: 5)
        for _ in 0..<4 {
            #expect(estimator.process(loudBlow) == 0)
            #expect(!estimator.isCalibrated)
        }
        _ = estimator.process(loudBlow)
        #expect(estimator.isCalibrated)
    }

    @Test func ignoresBackgroundNoiseAfterCalibration() {
        var estimator = calibrated()
        #expect(estimator.process(quiet) == 0)
    }

    @Test func detectsBlowAndSmoothsIntensity() {
        var estimator = calibrated()
        let first = estimator.process(loudBlow)
        let second = estimator.process(loudBlow)
        #expect(first > 0)
        #expect(second > first)
        #expect(second <= 1)
    }

    @Test func intensityDecaysWhenBlowStops() {
        var estimator = calibrated()
        for _ in 0..<20 { _ = estimator.process(loudBlow) }
        let peak = estimator.process(loudBlow)
        let after = estimator.process(quiet)
        #expect(after < peak)
    }

    @Test func resetRequiresRecalibration() {
        var estimator = calibrated()
        estimator.reset()
        #expect(!estimator.isCalibrated)
    }
}
