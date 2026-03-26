import SwiftUI

struct BlowGaugeView: View {
    let blowIntensity: Double

    var body: some View {
        ProgressView(value: blowIntensity, total: 1)
            .progressViewStyle(.linear)
            .tint(.orange)
            .animation(.easeOut(duration: 0.12), value: blowIntensity)
    }
}

#Preview {
    BlowGaugeView(blowIntensity: 0.65)
        .padding()
}
