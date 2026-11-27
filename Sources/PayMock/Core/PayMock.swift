import Foundation
import SwiftUI

/// Main entry point for the PayMock SDK.
@MainActor
public final class PayMock: ObservableObject {
    public static let shared = PayMock()

    /// SDK Configuration
    public struct Configuration {
        public var enabledBrands: Set<PaymentBrand>
        public var autoInterceptOutboundURLs: Bool
        public var simulateLatency: Bool
        public var latencySeconds: Double

        public init(
            enabledBrands: Set<PaymentBrand> = Set(PaymentBrand.allCases),
            autoInterceptOutboundURLs: Bool = true,
            simulateLatency: Bool = true,
            latencySeconds: Double = 0.6
        ) {
            self.enabledBrands = enabledBrands
            self.autoInterceptOutboundURLs = autoInterceptOutboundURLs
            self.simulateLatency = simulateLatency
            self.latencySeconds = latencySeconds
        }
    }

    @Published public private(set) var isInitialized: Bool = false
    @Published public private(set) var config: Configuration = .init()

    /// Headless preset scenario overrides (keyed by brand rawValue). Used for CI / Automated Tests.
    private var presetScenarios: [PaymentBrand: PayMockScenario] = [:]

    /// Active context when presented
    @Published public var activeContext: PayMockContext?
    @Published public var isSheetPresented: Bool = false

    /// Continuations for async/await presentation
    private var activeContinuation: CheckedContinuation<PayMockResult, Never>?

    private init() {}

    /// Initializes PayMock with given configuration.
    public static func initialize(config: Configuration = .init()) {
        shared.config = config
        shared.isInitialized = true
    }

    /// Sets a pre-determined scenario for automated tests / headless CI.
    /// When set, calling `present` resolves immediately with this scenario without presenting any UI.
    public static func setPresetScenario(for brand: PaymentBrand, scenario: PayMockScenario?) {
        shared.presetScenarios[brand] = scenario
    }

    /// Clears all headless overrides.
    public static func clearPresetScenarios() {
        shared.presetScenarios.removeAll()
    }

    /// Returns the preset scenario for a brand if configured.
    public func presetScenario(for brand: PaymentBrand) -> PayMockScenario? {
        presetScenarios[brand]
    }

    /// Programmatic async presentation of the PayMock sheet.
    public static func present(context: PayMockContext) async -> PayMockResult {
        // Check for headless scenario override (for CI)
        if let preset = shared.presetScenario(for: context.brand) {
            if shared.config.simulateLatency {
                try? await Task.sleep(nanoseconds: UInt64(shared.config.latencySeconds * 1_000_000_000))
            }
            return shared.resolveResult(for: context, scenario: preset)
        }

        return await withCheckedContinuation { continuation in
            shared.activeContinuation = continuation
            shared.activeContext = context
            shared.isSheetPresented = true
        }
    }

    /// Resolves the current active presentation with a chosen scenario.
    public func resolve(scenario: PayMockScenario) {
        guard let context = activeContext else { return }
        let result = resolveResult(for: context, scenario: scenario)

        // Dismiss sheet
        isSheetPresented = false
        activeContext = nil

        // Resume continuation if any
        let continuation = activeContinuation
        activeContinuation = nil
        continuation?.resume(returning: result)
    }

    /// Constructs the PayMockResult from a given scenario and context.
    public func resolveResult(for context: PayMockContext, scenario: PayMockScenario) -> PayMockResult {
        switch scenario {
        case .success(let customTxId):
            let txId = customTxId ?? "TX_\(context.brand.rawValue.uppercased())_\(Int.random(in: 100000...999999))"
            let token = "tok_\(context.brand.rawValue)_\(UUID().uuidString.prefix(8).lowercased())"
            let rawParams: [String: String] = [
                "status": "SUCCESS",
                "orderId": context.orderId,
                "transactionId": txId,
                "token": token,
                "amount": String(format: "%.2f", context.amount),
                "currency": context.currency
            ]
            return .success(.init(
                transactionId: txId,
                token: token,
                brand: context.brand,
                amount: context.amount,
                currency: context.currency,
                rawQueryParameters: rawParams
            ))

        case .cancelled:
            return .cancelled

        case .insufficientFunds:
            return .declined(.insufficientFunds)

        case .cardExpired:
            return .declined(.cardExpired)

        case .partialBalance(let available):
            let remaining = max(0, context.amount - available)
            return .declined(.partialBalance(coveredAmount: available, remainingAmount: remaining))

        case .customDecline(let code, let message):
            return .declined(.custom(code: code, message: message))

        case .timeout:
            return .timeout

        case .networkError:
            return .networkError
        }
    }
}
