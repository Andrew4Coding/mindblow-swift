import SwiftUI

struct HowToPlay: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .center, spacing: 8) {

                    Image("ilustration-blow")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 150)
                    Text("Blow hard, but not too much!")
                }
            }
            .navigationTitle("How to Play?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Okay!") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HowToPlay()
}
