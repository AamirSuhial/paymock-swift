import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Main entry point for the PayMock SDK.
@MainActor
public final class PayMock: ObservableObject {
    public static let shared = PayMock()

    /// SDK Configuration
    public struct Configuration {
        public var enabledBrands: Set<PaymentBrand>
        public var autoInterceptOutboundURLs: Bool
        public var autoDispatchReturnURL: Bool
        public var simulateLatency: Bool
        public var latencySeconds: Double
        public var webhookEndpointURL: URL?
        public var webhookDelaySeconds: Double

        public init(
            enabledBrands: Set<PaymentBrand> = Set(PaymentBrand.allCases),
            autoInterceptOutboundURLs: Bool = true,
            autoDispatchReturnURL: Bool = true,
            simulateLatency: Bool = true,
            latencySeconds: Double = 0.6,
            webhookEndpointURL: URL? = nil,
            webhookDelaySeconds: Double = 0.3
        ) {
            self.enabledBrands = enabledBrands
            self.autoInterceptOutboundURLs = autoInterceptOutboundURLs
            self.autoDispatchReturnURL = autoDispatchReturnURL
            self.simulateLatency = simulateLatency
            self.latencySeconds = latencySeconds
            self.webhookEndpointURL = webhookEndpointURL
            self.webhookDelaySeconds = webhookDelaySeconds
        }
    }

    @Published public private(set) var isInitialized: Bool = false
    @Published public private(set) var config: Configuration = .init()

    /// Headless preset scenario overrides (keyed by brand). Used for CI / Automated Tests.
    private var presetScenarios: [PaymentBrand: PayMockScenario] = [:]

    /// Active context when presented
    @Published public var activeContext: PayMockContext?
    @Published public var isSheetPresented: Bool = false

    /// Continuations for async/await presentation
    private var activeContinuation: CheckedContinuation<PayMockResult, Never>?

    private init() {}

    /// Initializes PayMock with given configuration and loads any Maestro / CI launch overrides.
    public static func initialize(config: Configuration = .init()) {
        shared.config = config
        shared.isInitialized = true
        shared.loadLaunchOverrides()
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

    /// Parses launch arguments and environment variables (e.g. from Maestro or XCUITest).
    /// Supports `-PAYMOCK_FORCE_VIPPS cancelled` or `PAYMOCK_FORCE_VIPPS=cancelled` and `PAYMOCK_LATENCY=0`.
    public func loadLaunchOverrides(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        if let latencyStr = environment["PAYMOCK_LATENCY"], let latency = Double(latencyStr) {
            config.latencySeconds = latency
            config.simulateLatency = latency > 0
        }

        for brand in PaymentBrand.allCases {
            let key = "PAYMOCK_FORCE_\(brand.rawValue.uppercased())"
            if let envValue = environment[key] {
                presetScenarios[brand] = PayMockScenario.from(string: envValue)
            } else if let idx = arguments.firstIndex(of: "-\(key)"), idx + 1 < arguments.count {
                presetScenarios[brand] = PayMockScenario.from(string: arguments[idx + 1])
            }
        }
    }

    /// Attempts to intercept an outbound payment URL (e.g., `vippsMT://pay?amount=249&orderId=123&returnUrl=myapp://cb`).
    /// Returns `nil` if the URL does not match an enabled payment brand.
    public static func handleOutboundURL(_ url: URL) async -> PayMockResult? {
        guard shared.config.autoInterceptOutboundURLs,
              let scheme = url.scheme?.lowercased() else {
            return nil
        }

        guard let brand = shared.config.enabledBrands.first(where: {
            let brandScheme = $0.defaultScheme
                .replacingOccurrences(of: "://", with: "")
                .lowercased()
            return brandScheme == scheme || $0.rawValue.lowercased() == scheme
        }) else {
            return nil
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []
        func param(_ names: String...) -> String? {
            queryItems.first(where: { item in names.contains(where: { $0.caseInsensitiveCompare(item.name) == .orderedSame }) })?.value
        }

        let amount = Double(param("amount") ?? "") ?? 0.0
        let currency = param("currency") ?? brand.defaultCurrency
        let orderId = param("orderId", "order_id") ?? "ORD-\(Int.random(in: 10000...99999))"
        let returnUrl = param("returnUrl", "return_url", "callback", "redirect_uri")

        let context = PayMockContext(
            brand: brand,
            amount: amount,
            currency: currency,
            orderId: orderId,
            returnURLScheme: returnUrl
        )
        return await present(context: context)
    }

    /// Programmatic async presentation of the PayMock sheet.
    public static func present(context: PayMockContext) async -> PayMockResult {
        // Check for headless scenario override (for CI)
        if let preset = shared.presetScenario(for: context.brand) {
            if shared.config.simulateLatency {
                try? await Task.sleep(nanoseconds: UInt64(shared.config.latencySeconds * 1_000_000_000))
            }
            let result = shared.resolveResult(for: context, scenario: preset)
            shared.finalizeResolution(context: context, result: result)
            return result
        }

        // Guard against concurrent presentation leaking an existing continuation
        guard shared.activeContinuation == nil else {
            return .cancelled
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

        finalizeResolution(context: context, result: result)

        // Resume continuation if any
        let continuation = activeContinuation
        activeContinuation = nil
        continuation?.resume(returning: result)
    }

    /// Dispatches deep-link return URL and optional staging webhook.
    private func finalizeResolution(context: PayMockContext, result: PayMockResult) {
        if config.autoDispatchReturnURL, let returnURL = context.returnURLScheme {
            dispatchReturnURL(baseURLString: returnURL, result: result)
        }
        if let webhookURL = config.webhookEndpointURL {
            dispatchWebhook(to: webhookURL, context: context, result: result)
        }
    }

    private func dispatchReturnURL(baseURLString: String, result: PayMockResult) {
        guard var components = URLComponents(string: baseURLString) else { return }
        var items = components.queryItems ?? []

        switch result {
        case .success(let details):
            items.append(URLQueryItem(name: "status", value: "SUCCESS"))
            items.append(URLQueryItem(name: "transactionId", value: details.transactionId))
            items.append(URLQueryItem(name: "token", value: details.token))
        case .cancelled:
            items.append(URLQueryItem(name: "status", value: "CANCELLED"))
            items.append(URLQueryItem(name: "error", value: "USER_ABORTED"))
        case .declined(let reason):
            items.append(URLQueryItem(name: "status", value: "DECLINED"))
            items.append(URLQueryItem(name: "error", value: reason.localizedDescription))
        case .timeout:
            items.append(URLQueryItem(name: "status", value: "TIMEOUT"))
        case .networkError:
            items.append(URLQueryItem(name: "status", value: "NETWORK_ERROR"))
        }

        components.queryItems = items
        guard let finalURL = components.url else { return }

        #if canImport(UIKit)
        DispatchQueue.main.async {
            UIApplication.shared.open(finalURL)
        }
        #endif
    }

    private func dispatchWebhook(to webhookURL: URL, context: PayMockContext, result: PayMockResult) {
        let delay = config.webhookDelaySeconds
        let status: String
        var transactionId: String?
        switch result {
        case .success(let details):
            status = "AUTHORIZED"
            transactionId = details.transactionId
        case .cancelled:
            status = "CANCELLED"
        case .declined:
            status = "DECLINED"
        case .timeout:
            status = "EXPIRED"
        case .networkError:
            status = "FAILED"
        }

        let payload: [String: Any] = [
            "event": "payment.\(status.lowercased())",
            "brand": context.brand.rawValue,
            "orderId": context.orderId,
            "amount": context.amount,
            "currency": context.currency,
            "status": status,
            "transactionId": transactionId ?? ""
        ]

        Task.detached {
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            var request = URLRequest(url: webhookURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("PayMock-Swift/1.0", forHTTPHeaderField: "User-Agent")
            request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
            _ = try? await URLSession.shared.data(for: request)
        }
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
