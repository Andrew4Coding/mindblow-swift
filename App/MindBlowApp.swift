import SwiftUI

@main
struct MindBlowApp: App {
    private let environment = AppEnvironment.bootstrap()

    var body: some Scene {
        WindowGroup {
            GameView(environment: environment)
        }
    }
}
