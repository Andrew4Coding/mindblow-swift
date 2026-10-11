import SwiftUI

struct HeaderAction {
    let systemImage: String
    let label: LocalizedStringKey
    var fill: Color = Palette.card
    var foreground: Color = Palette.ink
    var isEnabled = true
    let action: () -> Void
}

struct SheetScaffold<Content: View>: View {
    let title: LocalizedStringKey
    var leading: HeaderAction?
    var trailing: HeaderAction?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DoodleBackground())
        .cartoonSheet()
    }

    private var header: some View {
        HStack(spacing: 12) {
            slot(leading)
            Text(title)
                .font(.gaegu(34, weight: .bold, relativeTo: .title))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
                .accessibilityAddTraits(.isHeader)
            slot(trailing)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private func slot(_ action: HeaderAction?) -> some View {
        if let action {
            Button(action: action.action) {
                Label(action.label, systemImage: action.systemImage)
                    .labelStyle(.iconOnly)
                    .font(.system(size: 18, weight: .bold))
            }
            .buttonStyle(.cartoon(fill: action.fill, foreground: action.foreground, circular: true))
            .disabled(!action.isEnabled)
        } else {
            Color.clear.frame(width: 46, height: 46)
        }
    }
}

extension HeaderAction {
    static func close(_ action: @escaping () -> Void) -> HeaderAction {
        HeaderAction(systemImage: "xmark", label: "Close", action: action)
    }

    static func confirm(isEnabled: Bool = true, _ action: @escaping () -> Void) -> HeaderAction {
        HeaderAction(systemImage: "checkmark", label: "Done", fill: Palette.mint, foreground: Palette.onAccent, isEnabled: isEnabled, action: action)
    }
}

#Preview {
    SheetScaffold(title: "Settings", leading: .close {}, trailing: .confirm {}) {
        Spacer()
    }
}
