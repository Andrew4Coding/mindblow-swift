import SwiftUI

struct BlowGaugeView: View {
    let blowIntensity: Double 

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Blow Power")
                    .font(.headline)
                Spacer()
                Text("\(Int(blowIntensity * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            ProgressView(value: blowIntensity, total: 1)
                .progressViewStyle(.linear)
                .tint(.blue)
                .animation(.easeOut(duration: 0.12), value: blowIntensity)
            HStack {
                Text("Soft")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Hard")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    BlowGaugeView(blowIntensity: 0.65)
        .padding()
}