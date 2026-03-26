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
                    
                    HStack (spacing: 20) {
                        Image("ilustration-success")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 150)
                        Image("ilustration-explode")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 180)
                    }
                    
                    Text("*AI Generated")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Instructions")
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
