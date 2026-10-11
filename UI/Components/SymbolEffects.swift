import SwiftUI

extension View {
    @ViewBuilder
    func wigglingSymbol(isActive: Bool) -> some View {
        if #available(iOS 18, *) {
            symbolEffect(.wiggle.byLayer, options: .repeat(.continuous), isActive: isActive)
        } else {
            symbolEffect(.pulse, isActive: isActive)
        }
    }

    @ViewBuilder
    func bouncingSymbol(isActive: Bool) -> some View {
        if #available(iOS 18, *) {
            symbolEffect(.bounce.up.byLayer, options: .repeat(.periodic(delay: 1)), isActive: isActive)
        } else {
            symbolEffect(.pulse, isActive: isActive)
        }
    }
}
