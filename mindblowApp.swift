import SwiftUI

@main
struct mindblowApp: App {
    @State private var detector = BlowDetector()
    @State private var viewModel = GameViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(detector: detector, viewModel: viewModel)
        }
    }
}
