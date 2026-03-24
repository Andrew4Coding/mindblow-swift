import SwiftUI
import Combine

struct ContentView: View {
    @State var detector: BlowDetector
    @State var viewModel: GameViewModel
    @State private var timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        let normalizedPressure = min(1, viewModel.maxPSI == 0 ? 0 : viewModel.currentPSI / viewModel.maxPSI)

        ZStack(alignment: .bottom) {
            VStack(spacing: 24) {
                Text("Target max: \(Int(viewModel.maxPSI)) psi")
                    .font(.headline)

                TireView(progress: normalizedPressure, isExploded: viewModel.isExploded)
                    .frame(height: 320)
                    .padding(.horizontal, 24)

                BlowGaugeView(blowIntensity: Double(detector.blowIntensity))

                VStack(spacing: 8) {
                    Text("Pressure: \(viewModel.currentPSI, specifier: "%.1f") / \(viewModel.maxPSI, specifier: "%.0f") psi")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if viewModel.isExploded {
                        Text("Boom! Tire exploded")
                            .font(.title2.bold())
                            .foregroundColor(.red)
                            .transition(.scale.combined(with: .opacity))
                    } else if viewModel.isFinished {
                        VStack(spacing: 4) {
                            Text("Score: \(Int(viewModel.scorePercent * 100))%")
                                .font(.title.bold())
                            if viewModel.scorePercent >= viewModel.highScore && viewModel.scorePercent > 0 {
                                Text("High score!")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                        }
                        .transition(.opacity)
                    }
                }

                HStack(spacing: 16) {
                    if viewModel.hasBlownOnce && !viewModel.isFinished && !viewModel.isExploded {
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
            }
            .padding()
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

            if !detector.isCalibrated {
                Text("Calibrating... please stay quiet")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 8)
            }
        }
    }
}

#Preview {
    ContentView(detector: BlowDetector(), viewModel: GameViewModel())
}