import SwiftUI
import PayMock

@main
struct PayMockExampleApp: App {
    init() {
        // Initialize PayMock in test/debug mode
        PayMock.initialize(config: .init(
            simulateLatency: true,
            latencySeconds: 0.5
        ))
    }

    var body: some Scene {
        WindowGroup {
            CheckoutView()
        }
    }
}
