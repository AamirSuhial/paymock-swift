import SwiftUI

public extension View {
    /// Attaches the PayMock sheet to a specific view based on a binding.
    func payMockSheet(
        isPresented: Binding<Bool>,
        brand: PaymentBrand,
        amount: Double,
        currency: String? = nil,
        orderId: String = "ORD-\(Int.random(in: 10000...99999))",
        onResult: @escaping (PayMockResult) -> Void
    ) -> some View {
        let context = PayMockContext(
            brand: brand,
            amount: amount,
            currency: currency,
            orderId: orderId
        )

        return self.sheet(isPresented: isPresented) {
            PayMockSheetView(context: context) { scenario in
                let result = PayMock.shared.resolveResult(for: context, scenario: scenario)
                isPresented.wrappedValue = false
                onResult(result)
            }
        }
    }

    /// Attaches the global PayMock overlay to your app root window.
    /// When `PayMock.present(context:)` is called from anywhere, this sheet displays automatically.
    func payMockGlobalContainer() -> some View {
        self.modifier(PayMockGlobalContainerModifier())
    }
}

/// Modifier that listens to PayMock singleton presentations
public struct PayMockGlobalContainerModifier: ViewModifier {
    @ObservedObject private var payMock = PayMock.shared

    public init() {}

    public func body(content: Content) -> some View {
        content
            .sheet(isPresented: Binding(
                get: { payMock.isSheetPresented && payMock.activeContext != nil },
                set: { isPresenting in
                    if !isPresenting {
                        payMock.resolve(scenario: .cancelled)
                    }
                }
            )) {
                if let context = payMock.activeContext {
                    PayMockSheetView(context: context) { scenario in
                        payMock.resolve(scenario: scenario)
                    }
                }
            }
    }
}
