import SwiftUI

/// The popover sheet presented over the merchant checkout to mimic the payment brand.
public struct PayMockSheetView: View {
    @ObservedObject private var payMock = PayMock.shared
    @State private var selectedScenario: PayMockScenario?
    @State private var isSimulating: Bool = false
    @State private var simulateDelay: Bool = true

    public let context: PayMockContext
    public let onSelect: (PayMockScenario) -> Void

    public init(context: PayMockContext, onSelect: @escaping (PayMockScenario) -> Void) {
        self.context = context
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 14)

            // Branded Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(context.brand.brandColor)
                        .frame(width: 44, height: 44)

                    Image(systemName: context.brand.badgeSymbol)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(context.brand.displayName)
                            .font(.headline)
                            .fontWeight(.bold)

                        Text("MOCK")
                            .font(.system(size: 10, weight: .heavy))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                    }

                    Text(context.brand.region)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.2f %@", context.amount, context.currency))
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(context.orderId)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            Divider()

            // Scrollable Scenarios List
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("SELECT TEST SCENARIO TO MIMIC")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                    VStack(spacing: 10) {
                        // 1. Success
                        scenarioRow(
                            scenario: .success(),
                            badgeColor: .green,
                            tintColor: context.brand.brandColor
                        )

                        // 2. User Cancelled
                        scenarioRow(
                            scenario: .cancelled,
                            badgeColor: .orange,
                            tintColor: .secondary
                        )

                        // 3. Insufficient Funds
                        scenarioRow(
                            scenario: .insufficientFunds,
                            badgeColor: .red,
                            tintColor: .secondary
                        )

                        // 4. Brand-Specific Scenario (Edenred voucher split)
                        if context.brand == .edenred {
                            scenarioRow(
                                scenario: .partialBalance(availableAmount: max(5.0, context.amount * 0.5)),
                                badgeColor: .purple,
                                tintColor: .secondary
                            )
                        }

                        // 5. Card Expired
                        scenarioRow(
                            scenario: .cardExpired,
                            badgeColor: .red,
                            tintColor: .secondary
                        )

                        // 6. Network Timeout / Bank Downtime
                        scenarioRow(
                            scenario: .networkError,
                            badgeColor: .gray,
                            tintColor: .secondary
                        )
                    }
                    .padding(.horizontal, 20)

                    // Options Box
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $simulateDelay) {
                            HStack(spacing: 6) {
                                Image(systemName: "timer")
                                    .font(.caption)
                                Text("Simulate realistic network delay (600ms)")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                }
                .padding(.bottom, 24)
            }

            // Bottom Actions / Status
            if isSimulating {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Emitting response to host app...")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 16)
            }
        }
        .background(sheetBackgroundColor)
        .cornerRadius(18)
        .accessibilityIdentifier("paymock_sheet")
    }

    private var sheetBackgroundColor: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemBackground)
        #elseif canImport(AppKit)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color.white
        #endif
    }

    @ViewBuilder
    private func scenarioRow(
        scenario: PayMockScenario,
        badgeColor: Color,
        tintColor: Color
    ) -> some View {
        Button(action: {
            handleSelection(scenario)
        }) {
            HStack(spacing: 14) {
                Image(systemName: scenario.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(badgeColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(scenario.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(scenario.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.secondary.opacity(0.06))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(isSimulating)
        .accessibilityIdentifier("paymock_btn_\(scenario.testId)")
    }

    private func handleSelection(_ scenario: PayMockScenario) {
        guard !isSimulating else { return }
        isSimulating = true

        if simulateDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                onSelect(scenario)
            }
        } else {
            onSelect(scenario)
        }
    }
}
