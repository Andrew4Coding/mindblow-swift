import SwiftUI

struct HoldToInflateButton: View {
    let isEnabled: Bool
    let onPressChanged: (Bool) -> Void
    let onActivate: () -> Void

    @State private var isPressed = false

    var body: some View {
        Label("Hold to Inflate", systemImage: "wind")
            .font(.gaegu(26, weight: .bold))
            .foregroundStyle(Palette.onAccent)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .frame(minHeight: 48)
            .cartoonSurface(Capsule(), fill: Palette.sky, pressed: isPressed)
            .padding(.bottom, 4)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isPressed)
            .contentShape(.capsule)
            .opacity(isEnabled ? 1 : 0.45)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in setPressed(true) }
                    .onEnded { _ in setPressed(false) },
                isEnabled: isEnabled
            )
            .onChange(of: isEnabled) { _, enabled in if !enabled { setPressed(false) } }
            .onDisappear { setPressed(false) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Hold to inflate")
            .accessibilityHint("Double-tap for a short burst of air. Use this instead of blowing.")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(.default, onActivate)
    }

    private func setPressed(_ pressed: Bool) {
        guard pressed != isPressed else { return }
        isPressed = pressed
        onPressChanged(pressed)
    }
}

#Preview {
    HoldToInflateButton(isEnabled: true, onPressChanged: { _ in }, onActivate: {})
        .padding()
}
