import SwiftUI

struct GameView: View {
    private let environment: AppEnvironment

    @State private var viewModel: GameViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(environment: AppEnvironment) {
        self.environment = environment
        _viewModel = State(initialValue: environment.makeGameViewModel())
    }

    var body: some View {
        VStack(spacing: 8) {
            topBar
            content
        }
        .background(DoodleBackground())
        .overlay {
            if viewModel.isCelebrating && !reduceMotion {
                ConfettiView()
            }
        }
        .sheet(item: $viewModel.activeSheet) { sheet in
            sheetContent(sheet)
        }
        .task { await viewModel.runLoop() }
        .onChange(of: scenePhase) { _, newPhase in viewModel.scenePhaseDidChange(newPhase) }
        .onChange(of: viewModel.phase) { _, newPhase in announce(newPhase) }
    }

    private var content: some View {
        VStack(spacing: 20) {
            if viewModel.isMicrophoneUnavailable {
                MicrophoneAccessBanner()
            }

            TireView(
                progress: viewModel.normalizedPressure,
                isExploded: viewModel.isExploded,
                isFinished: viewModel.isFinished,
                hasBlownOnce: viewModel.hasBlownOnce,
                skin: viewModel.selectedSkin
            )
            .frame(maxHeight: .infinity)
            .frame(minHeight: 200)

            VStack(spacing: 12) {
                if viewModel.showsBlowGauge {
                    BlowGaugeView(blowIntensity: viewModel.blowIntensity)
                }
                status
            }
            .animation(.easeOut(duration: 0.2), value: viewModel.phase)

            GameControlsView(viewModel: viewModel)

            blowPrompt
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .keyframeAnimator(
            initialValue: 0.0,
            trigger: reduceMotion ? 0 : viewModel.explosionCount
        ) { view, offset in
            view.offset(x: offset)
        } keyframes: { _ in
            KeyframeTrack {
                LinearKeyframe(10, duration: 0.05)
                LinearKeyframe(-10, duration: 0.05)
                LinearKeyframe(10, duration: 0.05)
                LinearKeyframe(-10, duration: 0.05)
                LinearKeyframe(10, duration: 0.05)
                LinearKeyframe(0, duration: 0.05)
            }
        }
    }

    @ViewBuilder
    private var status: some View {
        switch viewModel.phase {
        case .exploded:
            Group {
                if viewModel.isTwoPlayerMode {
                    Text("Player \(viewModel.currentPlayer) loses!")
                } else {
                    Text("Boom! Game over")
                }
            }
            .font(.gaegu(38, weight: .bold, relativeTo: .title))
            .foregroundStyle(Palette.coral)
            .transition(.scale.combined(with: .opacity))
        case .finished:
            VStack(spacing: 4) {
                OutlinedText("Score: \(viewModel.scorePercentInt)%", size: 46)
                if viewModel.isHighScore {
                    Text("New high score!")
                        .font(.gaegu(26, weight: .bold, relativeTo: .headline))
                        .foregroundStyle(Palette.onAccent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 2)
                        .cartoonSurface(Capsule(), fill: Palette.sun, lineWidth: 1.5, lift: 2)
                }
            }
            .transition(.opacity)
        case .playing where viewModel.isPreparingInput:
            Label("Calibrating background noise…", systemImage: "waveform.badge.microphone")
                .font(.gaegu(22, relativeTo: .footnote))
                .foregroundStyle(Palette.ink.opacity(0.7))
                .wigglingSymbol(isActive: !reduceMotion)
        default:
            EmptyView()
        }
    }

    private var blowPrompt: some View {
        VStack(spacing: 6) {
            Text("Blow here")
                .font(.gaegu(30, weight: .bold, relativeTo: .headline))
            Image(systemName: "chevron.down.2")
                .font(.system(size: 20, weight: .heavy))
                .wigglingSymbol(isActive: !reduceMotion)
        }
        .foregroundStyle(Palette.ink.opacity(0.75))
        .opacity(viewModel.showsBlowPrompt ? 1 : 0)
        .animation(.easeOut(duration: 0.2), value: viewModel.showsBlowPrompt)
        .accessibilityHidden(true)
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            iconButton("How to Play", systemImage: "questionmark", fill: Palette.sky) {
                viewModel.present(.howToPlay)
            }

            Spacer(minLength: 4)
            title
            Spacer(minLength: 4)

            iconButton("Leaderboard", systemImage: "trophy.fill", fill: Palette.sun) {
                viewModel.present(.leaderboard)
            }

            Menu {
                Button("Change Mode", systemImage: "arrow.trianglehead.2.counterclockwise") {
                    viewModel.present(.modeSelection)
                }
                Button("Choose Tire", systemImage: "tire") {
                    viewModel.present(.skins)
                }
                .disabled(viewModel.phase == .playing && viewModel.hasBlownOnce)
                Button("Settings", systemImage: "gearshape") {
                    viewModel.present(.settings)
                }
            } label: {
                Label("More", systemImage: "ellipsis")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 18, weight: .bold))
            }
            .menuStyle(.button)
            .buttonStyle(.cartoon(fill: Palette.card, foreground: Palette.ink, circular: true))
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var title: some View {
        if viewModel.isTwoPlayerMode && viewModel.hasStartedGame && !viewModel.isExploded {
            Text("Player \(viewModel.currentPlayer)")
                .font(.gaegu(28, weight: .bold, relativeTo: .headline))
                .foregroundStyle(Palette.onAccent)
                .padding(.horizontal, 16)
                .padding(.vertical, 2)
                .cartoonSurface(Capsule(), fill: Palette.pink, lineWidth: 1.5, lift: 2)
        } else {
            OutlinedText("Mindblow", size: 38)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func iconButton(
        _ label: LocalizedStringKey,
        systemImage: String,
        fill: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(label, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .font(.system(size: 18, weight: .bold))
        }
        .buttonStyle(.cartoon(fill: fill, circular: true))
    }

    @ViewBuilder
    private func sheetContent(_ sheet: GameSheet) -> some View {
        switch sheet {
        case .modeSelection:
            GameModeSelectionView(canDismiss: viewModel.hasStartedGame) { mode in
                viewModel.startGame(mode: mode)
            }
            .interactiveDismissDisabled(!viewModel.hasStartedGame)
        case .howToPlay:
            HowToPlayView()
        case .leaderboard:
            LeaderboardView(viewModel: LeaderboardViewModel(store: environment.leaderboard))
        case .skins:
            SkinPickerView(
                viewModel: SkinPickerViewModel(currentSkin: viewModel.selectedSkin) { skin in
                    viewModel.selectSkin(skin)
                }
            )
        case .settings:
            SettingsView(
                viewModel: SettingsViewModel(
                    preferences: environment.preferences,
                    sound: environment.sound,
                    haptics: environment.haptics
                )
            )
        case .saveScore:
            SaveScoreView(
                viewModel: SaveScoreViewModel(
                    score: viewModel.scorePercent,
                    store: environment.leaderboard
                ) { entry in
                    viewModel.didSaveScore(entry)
                }
            )
        }
    }

    private func announce(_ phase: GamePhase) {
        switch phase {
        case .exploded:
            AccessibilityNotification.Announcement(String(localized: "Boom! Game over")).post()
        case .finished:
            AccessibilityNotification.Announcement(
                String(localized: "Score: \(viewModel.scorePercentInt)%")
            ).post()
        default:
            break
        }
    }
}

#Preview("Playing") {
    GameView(environment: .stub())
}
