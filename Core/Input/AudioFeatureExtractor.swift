import AVFoundation
import Accelerate

nonisolated struct AudioFeatures: Equatable, Sendable {
    let rms: Float
    let highFrequencyEnergy: Float
}

nonisolated final class AudioFeatureExtractor: @unchecked Sendable {
    private static let cutoffFrequency: Float = 2000

    private let fftSize: Int
    private let halfSize: Int
    private let log2n: vDSP_Length
    private let fftSetup: FFTSetup
    private let window: UnsafeMutablePointer<Float>
    private let windowed: UnsafeMutablePointer<Float>
    private let realPart: UnsafeMutablePointer<Float>
    private let imagPart: UnsafeMutablePointer<Float>
    private let magnitudes: UnsafeMutablePointer<Float>

    init?(fftSize: Int = 1024) {
        let log2n = vDSP_Length(log2(Float(fftSize)))
        guard let setup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return nil }

        self.fftSize = fftSize
        self.halfSize = fftSize / 2
        self.log2n = log2n
        self.fftSetup = setup

        func buffer(_ count: Int) -> UnsafeMutablePointer<Float> {
            let pointer = UnsafeMutablePointer<Float>.allocate(capacity: count)
            pointer.initialize(repeating: 0, count: count)
            return pointer
        }
        window = buffer(fftSize)
        windowed = buffer(fftSize)
        realPart = buffer(fftSize / 2)
        imagPart = buffer(fftSize / 2)
        magnitudes = buffer(fftSize / 2)
        vDSP_hann_window(window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
    }

    deinit {
        vDSP_destroy_fftsetup(fftSetup)
        window.deallocate()
        windowed.deallocate()
        realPart.deallocate()
        imagPart.deallocate()
        magnitudes.deallocate()
    }

    func extract(from buffer: AVAudioPCMBuffer) -> AudioFeatures? {
        let frameLength = Int(buffer.frameLength)
        guard let samples = buffer.floatChannelData?[0], frameLength >= fftSize else { return nil }

        var rms: Float = 0
        vDSP_rmsqv(samples, 1, &rms, vDSP_Length(frameLength))

        vDSP_vmul(samples, 1, window, 1, windowed, 1, vDSP_Length(fftSize))

        var split = DSPSplitComplex(realp: realPart, imagp: imagPart)
        windowed.withMemoryRebound(to: DSPComplex.self, capacity: halfSize) {
            vDSP_ctoz($0, 2, &split, 1, vDSP_Length(halfSize))
        }
        vDSP_fft_zrip(fftSetup, &split, 1, log2n, FFTDirection(FFT_FORWARD))
        vDSP_zvabs(&split, 1, magnitudes, 1, vDSP_Length(halfSize))

        let binWidth = Float(buffer.format.sampleRate) / 2 / Float(halfSize)
        let firstBin = min(halfSize, Int(Self.cutoffFrequency / binWidth) + 1)
        var highFrequencySum: Float = 0
        vDSP_sve(magnitudes + firstBin, 1, &highFrequencySum, vDSP_Length(halfSize - firstBin))

        return AudioFeatures(rms: rms, highFrequencyEnergy: highFrequencySum / Float(fftSize))
    }
}
