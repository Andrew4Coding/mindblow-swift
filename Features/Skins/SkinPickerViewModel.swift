import Observation

@Observable
final class SkinPickerViewModel {
    var selection: TireSkin

    private let onConfirm: (TireSkin) -> Void

    init(currentSkin: TireSkin, onConfirm: @escaping (TireSkin) -> Void) {
        self.selection = currentSkin
        self.onConfirm = onConfirm
    }

    func confirm() {
        onConfirm(selection)
    }
}
