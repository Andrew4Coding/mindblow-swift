import SwiftUI

struct SkinModal: View {
    @Environment(\.dismiss) var dismiss
    var currentSkin: TireSkin
    var onSelect: (TireSkin) -> Void

    @State private var selectedSkinIndex: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ZStack {
                    ForEach(Array(TireSkin.allCases.enumerated()), id: \.element) { index, skin in
                        VStack(spacing: 12) {
                            Image(skin.imagePrefix)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 100)
                            Text(skin.rawValue)
                                .font(.title3.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .opacity(index == selectedSkinIndex ? 1 : 0)
                        .offset(x: CGFloat(index - selectedSkinIndex) * 300)
                    }
                }
                .frame(height: 180)
                .clipped()
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if value.translation.width < -threshold {
                                    selectedSkinIndex = (selectedSkinIndex + 1) % TireSkin.allCases.count
                                } else if value.translation.width > threshold {
                                    selectedSkinIndex = (selectedSkinIndex - 1 + TireSkin.allCases.count) % TireSkin.allCases.count
                                }
                            }
                        }
                )

                HStack(spacing: 8) {
                    ForEach(0..<TireSkin.allCases.count, id: \.self) { index in
                        Circle()
                            .fill(index == selectedSkinIndex ? Color.primary : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationTitle("Choose Your Tire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        let selectedSkin = TireSkin.allCases[selectedSkinIndex]
                        onSelect(selectedSkin)
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let index = TireSkin.allCases.firstIndex(of: currentSkin) {
                selectedSkinIndex = index
            }
        }
    }
}

#Preview {
    SkinModal(currentSkin: .car) { _ in }
}
