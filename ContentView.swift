import Combine
import SwiftUI
import UnionConfetti

struct ContentView: View {
    @State var detector: BlowDetector
    @State var viewModel: GameViewModel
    @State private var timer = Timer.publish(
        every: 0.05,
        on: .main,
        in: .common
    ).autoconnect()
    @State private var showHowToPlay = true
    @State private var showMenu = false
    @State private var shakeOffset: CGFloat = 0
    @State private var isHighScore = false
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        let normalizedPressure = min(
            1,
            viewModel.maxPSI == 0 ? 0 : viewModel.currentPSI / viewModel.maxPSI
        )
        let isCalibrating = !detector.isCalibrated

        ZStack(alignment: .bottom) {
            if !isCalibrating && !viewModel.isExploded && !viewModel.isFinished
                && !showHowToPlay
            {
                VStack(spacing: 10) {
                    Text("Blow Here")
                    Image(systemName: "chevron.down.2")
                        .symbolEffect(
                            .wiggle.byLayer,
                            options: .repeat(.continuous)
                        )
                }
            }
            VStack {
                HStack {
                    Button(action: {
                        showHowToPlay = true
                    }) {
                        Spacer()
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        showMenu = true
                    }) {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .popover(isPresented: $showMenu) {
                        VStack(spacing: 12) {
                            Button(action: {
                                detector.calibrate()
                                showMenu = false
                            }) {
                                HStack {
                                    Image(systemName: "waveform.circle")
                                    Text("Recalibrate Background Noise")
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Divider()
                            
                            Button(action: {
                                exit(0)
                            }) {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                    Text("Exit App")
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .foregroundColor(.red)
                        }
                        .padding(20)
                        .presentationCompactAdaptation(.popover)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 16)

                Spacer()

                TireView(
                    progress: normalizedPressure,
                    isExploded: viewModel.isExploded,
                    isCalibrating: isCalibrating,
                    hasBlownOnce: viewModel.hasBlownOnce,
                    onTapExplosion: {
                        viewModel.triggerExplosion()
                    }
                )
                .frame(height: 320)

                VStack(spacing: 12) {
                    if detector.isCalibrated {
                        BlowGaugeView(
                            blowIntensity: Double(detector.blowIntensity)
                        )
                    }

                    VStack(spacing: 8) {
                        if viewModel.isExploded {
                            Text("Boom! Game Over")
                                .font(.title2.bold())
                                .foregroundColor(.red)
                                .transition(.scale.combined(with: .opacity))
                        } else if viewModel.isFinished {
                            VStack(spacing: 4) {
                                Text(
                                    "Score: \(Int(viewModel.scorePercent * 100))%"
                                )
                                .font(.title.bold())
                                if viewModel.scorePercent >= viewModel.highScore
                                    && viewModel.scorePercent > 0
                                {
                                    Text("High score!")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                }
                            }
                            .transition(.opacity)
                        }
                    }

                    HStack(spacing: 16) {
                        if viewModel.hasBlownOnce && !viewModel.isFinished
                            && !viewModel.isExploded
                        {
                            Button(action: {
                                viewModel.finish()
                            }) {
                                Text("Finish")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }

                        if viewModel.isFinished || viewModel.isExploded {
                            Button(action: {
                                viewModel.startNewSession()
                            }) {
                                Text("Restart")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    if !detector.isCalibrated {
                        HStack (spacing: 12) {
                            Image(systemName: "waveform.badge.microphone")
                                .symbolEffect(.wiggle.byLayer, options: .repeat(.continuous))
                            Text("Calibrating background noise...")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        
                    }
                }
                Spacer()
            }
            .padding(20)
            .frame(maxHeight: .infinity)
            .offset(x: shakeOffset)
            .onChange(of: viewModel.isExploded) { newValue in
                if newValue {
                    triggerShake()
                }
            }
            .onReceive(timer) { _ in
                viewModel.update(
                    blowIntensity: Double(detector.blowIntensity),
                    deltaTime: 0.05,
                    isCalibrated: detector.isCalibrated
                )
            }
            .onAppear {
                viewModel.startNewSession()
            }
            .sheet(isPresented: $showHowToPlay) {
                HowToPlay()
                    .presentationDetents([.medium])
                    .background(.white)
            }
        }
        .overlay(ConfettiView(isPresented: $isHighScore))
    }
    
    private func triggerShake() {
        let shakeAnimation = Animation.easeInOut(duration: 0.05)
        
        for i in 0..<6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                withAnimation(shakeAnimation) {
                    shakeOffset = (i % 2 == 0) ? 10 : -10
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(shakeAnimation) {
                shakeOffset = 0
            }
        }
    }
}

#Preview {
    ContentView(detector: BlowDetector(), viewModel: GameViewModel())
}
