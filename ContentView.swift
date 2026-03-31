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
    @State private var showHowToPlay = false
    @State private var showMenu = false
    @State private var shakeOffset: CGFloat = 0
    @State private var isHighScore = false
    @State private var hasStartedRecording = false
    @State private var needsInitialSetup = true
    @State private var showGameModeSelection = true
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        let normalizedPressure = min(
            1,
            viewModel.maxPSI == 0 ? 0 : viewModel.currentPSI / viewModel.maxPSI
        )
        let isCalibrating = !detector.isCalibrated

        ZStack(alignment: .bottom) {
            if hasStartedRecording && !isCalibrating && !viewModel.isExploded
                && !viewModel.isFinished
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
            VStack(spacing: 20) {
                HStack {
                    Button(action: {
                        showHowToPlay = true
                    }) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }

                    Spacer()

                    if viewModel.isTwoPlayerMode && !viewModel.isExploded {
                        Text("Player \(viewModel.currentPlayer)")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(20)
                    }

                    Spacer()

                    Button(action: {
                        showGameModeSelection = true
                    }) {
                        Image(systemName: "arrow.trianglehead.2.counterclockwise")
                            .font(.title2)
                            .foregroundColor(.blue)
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
                    hasStartedRecording: hasStartedRecording,
                    onTapExplosion: {
                        viewModel.triggerExplosion()
                    },
                    maxPSI: viewModel.maxPSI,
                    isFinished: viewModel.isFinished,
                    currentPlayer: viewModel.isTwoPlayerMode ? viewModel.currentPlayer : nil,
                    isOuterRingLocked: !viewModel.isOuterRingUnlocked
                )
                .frame(height: 320)

                VStack(spacing: 12) {
                    if detector.isCalibrated && !viewModel.isFinished
                        && !viewModel.isExploded
                    {
                        BlowGaugeView(
                            blowIntensity: Double(detector.blowIntensity)
                        )
                    }

                    VStack(spacing: 8) {
                        if viewModel.isExploded {
                            if viewModel.isTwoPlayerMode {
                                Text("Player \(viewModel.loserPlayer) Lose!")
                                    .font(.title2.bold())
                                    .foregroundColor(.red)
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                Text("Boom! Game Over")
                                    .font(.title2.bold())
                                    .foregroundColor(.red)
                                    .transition(.scale.combined(with: .opacity))
                            }
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

                    HStack(alignment: .center, spacing: 16) {
                        if viewModel.isTwoPlayerMode {
                            if viewModel.canPass && !viewModel.isFinished
                                && !viewModel.isExploded
                            {
                                Button(action: {
                                    viewModel.finish()
                                }) {
                                    Image(systemName: "checkmark")
                                        .symbolEffect(
                                            .bounce.up.byLayer,
                                            options: .repeat(.periodic(delay: 1.0))
                                        )
                                    Text("Pass")
                                        .font(.headline)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                            }
                        } else if viewModel.hasBlownOnce && !viewModel.isFinished
                            && !viewModel.isExploded
                        {
                            Button(action: {
                                viewModel.finish()
                            }) {
                                Image(systemName: "checkmark")
                                    .symbolEffect(
                                        .bounce.up.byLayer,
                                        options: .repeat(.periodic(delay: 1.0))
                                    )
                                Text("Had enough?")
                                    .font(.headline)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }

                        if viewModel.isFinished || viewModel.isExploded {
                            Button(action: {
                                viewModel.startNewSession()
                                detector.startRecording()
                            }) {
                                Image(
                                    systemName: "arrow.trianglehead.clockwise"
                                )
                                .symbolEffect(
                                    .rotate.clockwise.byLayer,
                                    options: .repeat(.continuous)
                                )
                                Text("Blow Again!")
                                    .font(.headline)
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    if hasStartedRecording && !detector.isCalibrated {
                        HStack(spacing: 12) {
                            Image(systemName: "waveform.badge.microphone")
                                .symbolEffect(
                                    .wiggle.byLayer,
                                    options: .repeat(.continuous)
                                )
                            Text("Calibrating background noise...")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                if !hasStartedRecording && needsInitialSetup {
                    Button(action: {
                        hasStartedRecording = true
                        needsInitialSetup = false
                        viewModel.startNewSession()
                        detector.startRecording()
                    }) {
                        Text("Start!")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                Spacer()
            }
            .padding(20)
            .frame(maxHeight: .infinity)
            .offset(x: shakeOffset)
            .onChange(of: viewModel.isExploded) { oldValue, newValue in
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
            .sheet(isPresented: $showHowToPlay) {
                HowToPlay()
                    .presentationDetents([.height(250)])
                    .background(.white)
            }
        }
        .overlay(ConfettiView(isPresented: $isHighScore))
        .sheet(isPresented: $showGameModeSelection) {
            GameModeSelectionView { mode in
                withAnimation(.easeOut) {
                    viewModel.gameMode = mode
                }
            } onRestart: {
                viewModel.startNewSession()
                detector.startRecording()
            }
            .presentationDetents([.height(300)])
            .background(.white)
            .interactiveDismissDisabled()
        }
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
