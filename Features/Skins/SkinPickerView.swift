import SwiftUI

struct SkinPickerView: View {
    @State private var viewModel: SkinPickerViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: SkinPickerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        SheetScaffold(
            title: "Choose Your Tire",
            leading: .close { dismiss() },
            trailing: .confirm {
                viewModel.confirm()
                dismiss()
            }
        ) {
            TabView(selection: $viewModel.selection) {
                ForEach(TireSkin.allCases) { skin in
                    VStack(spacing: 6) {
                        PhaseAnimator([0.35, 0.8]) { inflation in
                            TireGraphic(design: skin.design, inflation: inflation)
                        } animation: { _ in
                            .easeInOut(duration: 1.4)
                        }
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                        .background(alignment: .topLeading) {
                            SparkleShape().fill(Palette.sun)
                                .overlay(SparkleShape().stroke(Palette.ink, lineWidth: 2))
                                .frame(width: 28, height: 28)
                                .padding(14)
                        }
                        .background(alignment: .bottomTrailing) {
                            CloudShape().fill(Palette.softCard)
                                .frame(width: 64, height: 40)
                                .padding(12)
                        }
                        .padding(.vertical, 8)
                        .cartoonCard(fill: skin.backdrop, radius: 30)
                        .padding(.bottom, 10)

                        Text(skin.title)
                            .font(.gaegu(36, weight: .bold, relativeTo: .title2))
                            .foregroundStyle(Palette.ink)
                        Text(skin.detail)
                            .font(.gaegu(23, relativeTo: .subheadline))
                            .foregroundStyle(Palette.ink.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 44)
                    .accessibilityElement(children: .combine)
                    .tag(skin)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    SkinPickerView(viewModel: SkinPickerViewModel(currentSkin: .car) { _ in })
}

extension TireSkin {
    var backdrop: Color {
        switch self {
        case .car: Palette.sky
        case .truck: Palette.sun
        case .motor: Palette.pink
        case .bicycle: Palette.mint
        case .racing: Palette.coral
        case .tractor: Palette.lavender
        }
    }
}
