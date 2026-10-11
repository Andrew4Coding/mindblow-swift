import SwiftUI

struct MicrophoneAccessBanner: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Microphone is off", systemImage: "mic.slash.fill")
                .font(.gaegu(28, weight: .bold, relativeTo: .headline))
            Text("Mind Blow can't hear you blow. Hold the button below to inflate, or turn the microphone on in Settings.")
                .font(.gaegu(21, relativeTo: .subheadline))
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            .buttonStyle(.cartoon(fill: Palette.card, foreground: Palette.ink))
            .padding(.top, 4)
        }
        .foregroundStyle(Palette.onAccent)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cartoonCard(fill: Palette.sun, radius: 24)
    }
}

#Preview {
    MicrophoneAccessBanner()
        .padding()
}
