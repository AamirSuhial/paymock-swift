import SwiftUI
import PayMock

public struct CheckoutView: View {
    @State private var selectedBrand: PaymentBrand = .vipps
    @State private var amount: Double = 249.00
    @State private var currency: String = "NOK"

    // Testing Mode settings
    @State private var isHeadlessTestMode: Bool = false
    @State private var headlessScenario: PayMockScenario = .success()

    // Presentation state
    @State private var isProcessing: Bool = false
    @State private var lastResult: PayMockResult?

    public init() {}

    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Cart Summary Card
                    cartSummaryCard

                    // Payment Method Selector
                    paymentMethodPickerCard

                    // Test Mode Inspector Box
                    testModeInspectorCard

                    // Pay Button
                    payActionButton

                    // Last Result Inspector
                    if let result = lastResult {
                        resultInspectorCard(result)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationTitle("Checkout Demo")
            .payMockGlobalContainer() // Enables PayMock.present(...) popover anywhere
        }
    }

    // MARK: - Subviews

    private var cartSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ORDER SUMMARY")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Order #9281")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            HStack {
                Image(systemName: "bag.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading) {
                    Text("Salmon Poke Bowl + Drink")
                        .font(.headline)
                    Text("Delivered by FoodExpress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(String(format: "%.2f %@", amount, currency))
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
        .padding(16)
        .background(secondaryCardBackground)
        .cornerRadius(14)
    }

    private var paymentMethodPickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CHOOSE PAYMENT METHOD")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                ForEach([PaymentBrand.vipps, .paypay, .edenred, .ideal, .klarna, .twint]) { brand in
                    Button(action: {
                        selectedBrand = brand
                        currency = brand.defaultCurrency
                        if brand == .paypay { amount = 1650 }
                        else if brand == .edenred { amount = 28.50 }
                        else if brand == .ideal { amount = 22.00 }
                        else if brand == .twint { amount = 24.00 }
                        else { amount = 249.00 }
                    }) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(brand.brandColor)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: brand.badgeSymbol)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(brand.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)

                                Text(brand.region)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedBrand == brand {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.title3)
                            } else {
                                Circle()
                                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1.5)
                                    .frame(width: 20, height: 20)
                            }
                        }
                        .padding(12)
                        .background(selectedBrand == brand ? brand.brandColor.opacity(0.08) : secondaryCardBackground)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var testModeInspectorCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .foregroundColor(.orange)
                Text("PAYMOCK SETTINGS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
            }

            Toggle("Headless Mode (CI / Automation)", isOn: $isHeadlessTestMode)
                .font(.subheadline)
                .onChange(of: isHeadlessTestMode) { enabled in
                    if enabled {
                        PayMock.setPresetScenario(for: selectedBrand, scenario: headlessScenario)
                    } else {
                        PayMock.clearPresetScenarios()
                    }
                }

            if isHeadlessTestMode {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Pre-set Scenario (resolves with zero UI):")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Picker("Scenario", selection: $headlessScenario) {
                        Text("Approve (Success)").tag(PayMockScenario.success())
                        Text("User Cancelled").tag(PayMockScenario.cancelled)
                        Text("Insufficient Funds").tag(PayMockScenario.insufficientFunds)
                        Text("Card Expired").tag(PayMockScenario.cardExpired)
                        Text("Timeout").tag(PayMockScenario.timeout)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: headlessScenario) { scenario in
                        PayMock.setPresetScenario(for: selectedBrand, scenario: scenario)
                    }
                }
                .padding(.top, 4)
            } else {
                Text("Interactive Mode: Tapping Pay will pop up the branded PayMock sheet.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color.orange.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private var payActionButton: some View {
        Button(action: {
            executePayment()
        }) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                    Text("Processing...")
                        .fontWeight(.bold)
                } else {
                    Text("Pay with \(selectedBrand.displayName)")
                        .fontWeight(.bold)
                    Image(systemName: "arrow.right")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(selectedBrand.brandColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isProcessing)
    }

    private func resultInspectorCard(_ result: PayMockResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("HOST APP RECEIVED RESULT")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
            }

            switch result {
            case .success(let details):
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("Payment Approved!")
                            .font(.headline)
                            .foregroundColor(.green)
                        Text("TX: \(details.transactionId)")
                            .font(.caption)
                            .fontDesign(.monospaced)
                        Text("Token: \(details.token)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

            case .cancelled:
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    VStack(alignment: .leading) {
                        Text("Payment Cancelled")
                            .font(.headline)
                            .foregroundColor(.orange)
                        Text("Host app safely preserved cart state.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

            case .declined(let reason):
                HStack {
                    Image(systemName: "exclamationmark.octagon.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                    VStack(alignment: .leading) {
                        Text("Payment Declined")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(reason.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

            case .timeout:
                Text("Session Timed Out")
                    .font(.headline)
                    .foregroundColor(.gray)

            case .networkError:
                Text("Network Connection Error")
                    .font(.headline)
                    .foregroundColor(.red)
            }
        }
        .padding(14)
        .background(secondaryCardBackground)
        .cornerRadius(12)
    }

    private var secondaryCardBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.secondarySystemBackground)
        #elseif canImport(AppKit)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color.secondary.opacity(0.1)
        #endif
    }

    private func executePayment() {
        isProcessing = true

        Task {
            // Call the PayMock async API:
            let result = await PayMock.present(context: .init(
                brand: selectedBrand,
                amount: amount,
                currency: currency
            ))

            await MainActor.run {
                self.lastResult = result
                self.isProcessing = false
            }
        }
    }
}
