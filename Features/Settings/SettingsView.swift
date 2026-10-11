import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        SheetScaffold(title: "Settings", trailing: .confirm { dismiss() }) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    sectionTitle("Sound")
                    VStack(spacing: 14) {
                        Toggle("Music", isOn: $viewModel.isMusicEnabled)
                        Toggle("Sound Effects", isOn: $viewModel.isSoundEffectsEnabled)
                    }
                    .toggleStyle(CartoonToggleStyle())
                    .padding(16)
                    .cartoonCard(radius: 24)

                    Text("Sound plays even when your phone is on silent, because the game listens through the microphone.")
                        .font(.gaegu(20, relativeTo: .footnote))
                        .foregroundStyle(Palette.ink.opacity(0.65))
                        .padding(.horizontal, 6)

                    sectionTitle("Feedback")
                    Toggle("Haptics", isOn: $viewModel.isHapticsEnabled)
                        .toggleStyle(CartoonToggleStyle())
                        .padding(16)
                        .cartoonCard(radius: 24)

                    sectionTitle("About")
                    LabeledContent {
                        Text(viewModel.versionDescription)
                            .font(.gaegu(24, weight: .bold))
                            .foregroundStyle(Palette.ink.opacity(0.7))
                    } label: {
                        Text("Version")
                            .font(.gaegu(26, weight: .bold))
                            .foregroundStyle(Palette.ink)
                    }
                    .padding(16)
                    .cartoonCard(radius: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func sectionTitle(_ key: LocalizedStringKey) -> some View {
        HStack(spacing: 8) {
            SparkleShape()
                .fill(Palette.sun)
                .overlay(SparkleShape().stroke(Palette.ink, lineWidth: 2))
                .frame(width: 20, height: 20)
            Text(key)
                .font(.gaegu(28, weight: .bold, relativeTo: .title3))
                .foregroundStyle(Palette.ink)
        }
        .padding(.leading, 6)
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    let environment = AppEnvironment.stub()
    SettingsView(
        viewModel: SettingsViewModel(
            preferences: environment.preferences,
            sound: environment.sound,
            haptics: environment.haptics
        )
    )
}
