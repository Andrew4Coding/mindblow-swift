import SwiftUI

struct CartoonSurface<S: Shape>: ViewModifier {
    let shape: S
    let fill: Color
    var pressed = false
    var lineWidth: CGFloat = 1.5
    var lift: CGFloat = 2

    func body(content: Content) -> some View {
        content
            .background(shape.fill(fill))
            .overlay(shape.stroke(Palette.ink, lineWidth: lineWidth))
            .offset(y: pressed ? lift : 0)
            .background(shape.fill(Palette.ink).offset(y: lift))
    }
}

extension View {
    func cartoonSurface<S: Shape>(
        _ shape: S,
        fill: Color,
        pressed: Bool = false,
        lineWidth: CGFloat = 1.5,
        lift: CGFloat = 4
    ) -> some View {
        modifier(CartoonSurface(shape: shape, fill: fill, pressed: pressed, lineWidth: lineWidth, lift: lift))
    }

    func cartoonCard(fill: Color = Palette.card, radius: CGFloat = 28) -> some View {
        cartoonSurface(RoundedRectangle(cornerRadius: radius, style: .continuous), fill: fill)
    }

    func cartoonSheet() -> some View {
        presentationBackground(Palette.cream)
            .presentationCornerRadius(36)
            .presentationDragIndicator(.hidden)
    }
}

struct CartoonButtonStyle: ButtonStyle {
    var fill: Color = Palette.mint
    var foreground: Color = Palette.onAccent
    var circular = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.gaegu(24, weight: .bold))
            .foregroundStyle(foreground)
            .padding(circular ? EdgeInsets() : EdgeInsets(top: 8, leading: 22, bottom: 8, trailing: 22))
            .frame(minWidth: circular ? 46 : nil, minHeight: circular ? 46 : 44)
            .cartoonSurface(
                circular ? AnyShape(Circle()) : AnyShape(Capsule()),
                fill: fill,
                pressed: configuration.isPressed
            )
            .padding(.bottom, 2)
            .opacity(isEnabled ? 1 : 0.45)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == CartoonButtonStyle {
    static func cartoon(
        fill: Color = Palette.mint,
        foreground: Color = Palette.onAccent,
        circular: Bool = false
    ) -> CartoonButtonStyle {
        CartoonButtonStyle(fill: fill, foreground: foreground, circular: circular)
    }
}

struct CartoonToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.6)) {
                configuration.isOn.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                configuration.label
                    .font(.gaegu(26, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                track(isOn: configuration.isOn)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(.switch)
        }
    }

    private func track(isOn: Bool) -> some View {
        Capsule()
            .fill(isOn ? Palette.mint : Palette.softCard)
            .overlay(Capsule().stroke(Palette.ink, lineWidth: 1.5))
            .frame(width: 60, height: 34)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(Palette.card)
                    .overlay(Circle().stroke(Palette.ink, lineWidth: 1.5))
                    .frame(width: 26, height: 26)
                    .padding(3)
            }
    }
}

struct OutlinedText: View {
    let text: LocalizedStringKey
    var size: CGFloat = 40
    var fill: Color = Palette.ink

    init(_ text: LocalizedStringKey, size: CGFloat = 40, fill: Color = Palette.ink) {
        self.text = text
        self.size = size
        self.fill = fill
    }

    var body: some View {
        Text(text)
            .font(.gaegu(size, weight: .bold, relativeTo: .largeTitle))
            .foregroundStyle(fill)
            .multilineTextAlignment(.center)
    }
}

struct DoodleBackground: View {
    var body: some View {
        Palette.cream
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 24) {
        OutlinedText("Mindblow")
        Button("Pass") {}.buttonStyle(.cartoon())
        Toggle("Music", isOn: .constant(true)).toggleStyle(CartoonToggleStyle()).padding()
            .cartoonCard()
            .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DoodleBackground())
}
