import AVFoundation
import Accelerate
import Combine
import Foundation
import SwiftUI

@Observable
class BlowDetector {
    var blowIntensity: Float = 0.0
    var isCalibrated: Bool = false

    private let engine = AVAudioEngine()
    private var baseNoiseRMS: Float = 0.0
    private var baseHighFreqNoise: Float = 0.0

    private var calibrationFrames: Int = 0
    private let requiredCalibrationFrames = 40  
    private var previousIntensity: Float = 0.0

    private let fftSize = 1024
    private let log2n: vDSP_Length
    private let fftSetup: FFTSetup?

    init() {
        let calculatedLog2n = vDSP_Length(log2(Float(fftSize)))
        self.log2n = calculatedLog2n

        self.fftSetup = vDSP_create_fftsetup(
            calculatedLog2n,
            FFTRadix(kFFTRadix2)
        )

        setupMicrophone()
    }

    private func setupMicrophone() {
        #if os(iOS)
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(
                    .playAndRecord,
                    mode: .measurement,
                    options: [.duckOthers, .defaultToSpeaker]
                )
                try audioSession.setActive(true)

                audioSession.requestRecordPermission { [weak self] allowed in
                    DispatchQueue.main.async {
                        if allowed {
                            self?.startEngine()
                        }
                    }
                }
            } catch {
                print("Failed to set up audio session: \(error)")
            }
        #else
            // macOS simple setup
            startEngine()
        #endif
    }

    private func startEngine() {
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        let bufferSize = AVAudioFrameCount(fftSize)

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) {
            [weak self] buffer, time in
            self?.processAudio(buffer: buffer)
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            print("Error starting engine: \(error)")
        }
    }

    private func processAudio(buffer: AVAudioPCMBuffer) {
        let frameLength = Int(buffer.frameLength)
        guard let channelDataPtr = buffer.floatChannelData?[0],
            frameLength >= fftSize
        else { return }

        var rms: Float = 0
        vDSP_rmsqv(channelDataPtr, 1, &rms, vDSP_Length(frameLength))

        var window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))

        var windowedFrames = [Float](repeating: 0, count: fftSize)
        vDSP_vmul(
            channelDataPtr,
            1,
            window,
            1,
            &windowedFrames,
            1,
            vDSP_Length(fftSize)
        )

        let halfSize = fftSize / 2
        var realPart = [Float](repeating: 0, count: halfSize)
        var imagPart = [Float](repeating: 0, count: halfSize)
        var splitComplex = DSPSplitComplex(realp: &realPart, imagp: &imagPart)

        windowedFrames.withUnsafeBytes { ptr in
            let floatPtr = ptr.bindMemory(to: Float.self).baseAddress!
            floatPtr.withMemoryRebound(to: DSPComplex.self, capacity: halfSize)
            { complexPtr in
                vDSP_ctoz(
                    complexPtr,
                    2,
                    &splitComplex,
                    1,
                    vDSP_Length(halfSize)
                )
            }
        }

        if let setup = fftSetup {
            vDSP_fft_zrip(
                setup,
                &splitComplex,
                1,
                log2n,
                FFTDirection(FFT_FORWARD)
            )
        }

        var magnitudes = [Float](repeating: 0, count: halfSize)
        vDSP_zvabs(&splitComplex, 1, &magnitudes, 1, vDSP_Length(halfSize))

        var scale = 1.0 / Float(fftSize)
        var scaledMagnitudes = [Float](repeating: 0, count: halfSize)
        vDSP_vsmul(
            &magnitudes,
            1,
            &scale,
            &scaledMagnitudes,
            1,
            vDSP_Length(halfSize)
        )
        magnitudes = scaledMagnitudes

        let sampleRate = Float(buffer.format.sampleRate)
        let binWidth = (sampleRate / 2.0) / Float(halfSize)

        var highFreqEnergy: Float = 0
        for i in 0..<halfSize {
            let freq = Float(i) * binWidth
            if freq > 2000.0 {
                highFreqEnergy += magnitudes[i]
            }
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.analyzeSignal(rms: rms, highFreqEnergy: highFreqEnergy)
        }
    }

    private func analyzeSignal(rms: Float, highFreqEnergy: Float) {
        if !isCalibrated {
            baseNoiseRMS =
                (baseNoiseRMS * Float(calibrationFrames) + rms)
                / Float(calibrationFrames + 1)
            baseHighFreqNoise =
                (baseHighFreqNoise * Float(calibrationFrames) + highFreqEnergy)
                / Float(calibrationFrames + 1)
            calibrationFrames += 1
            if calibrationFrames >= requiredCalibrationFrames {
                isCalibrated = true
            }
            return
        }

        let isLoud = rms > (baseNoiseRMS * 1.5) + 0.01
        let hasHighFreqNoise = highFreqEnergy > (baseHighFreqNoise * 2.0) + 0.03
        var targetIntensity: Float = 0.0

        if isLoud && hasHighFreqNoise {
            let minEnergy: Float = baseHighFreqNoise + 0.03
            let maxEnergy: Float = 0.5
            let normalized =
                (highFreqEnergy - minEnergy) / (maxEnergy - minEnergy)
            targetIntensity = max(0.0, min(normalized, 1.0))
        }

        let alpha: Float = 0.2
        let smoothedIntensity =
            (previousIntensity * (1.0 - alpha)) + (targetIntensity * alpha)
        previousIntensity = smoothedIntensity

        withAnimation(.easeOut(duration: 0.1)) {
            self.blowIntensity = smoothedIntensity
        }
    }

    deinit {
        engine.stop()
        if let setup = fftSetup {
            vDSP_destroy_fftsetup(setup)
        }
    }
}
