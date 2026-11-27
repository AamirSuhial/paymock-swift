import XCTest
@testable import PayMock

final class PayMockTests: XCTestCase {

    @MainActor
    func testBrandProperties() {
        let vipps = PaymentBrand.vipps
        XCTAssertEqual(vipps.displayName, "Vipps MobilePay")
        XCTAssertEqual(vipps.defaultCurrency, "NOK")

        let paypay = PaymentBrand.paypay
        XCTAssertEqual(paypay.displayName, "PayPay")
        XCTAssertEqual(paypay.defaultCurrency, "JPY")

        let edenred = PaymentBrand.edenred
        XCTAssertEqual(edenred.defaultCurrency, "EUR")
    }

    @MainActor
    func testHeadlessSuccessScenario() async {
        PayMock.initialize()
        let brand = PaymentBrand.vipps
        PayMock.setPresetScenario(for: brand, scenario: .success(transactionId: "TX_TEST_123"))

        let context = PayMockContext(brand: brand, amount: 249.00, currency: "NOK")
        let result = await PayMock.present(context: context)

        switch result {
        case .success(let details):
            XCTAssertEqual(details.transactionId, "TX_TEST_123")
            XCTAssertEqual(details.brand, .vipps)
            XCTAssertEqual(details.amount, 249.00)
            XCTAssertEqual(details.currency, "NOK")
            XCTAssertEqual(details.rawQueryParameters["status"], "SUCCESS")
        default:
            XCTFail("Expected .success result but got \(result)")
        }

        PayMock.clearPresetScenarios()
    }

    @MainActor
    func testHeadlessCancelledScenario() async {
        PayMock.initialize()
        let brand = PaymentBrand.paypay
        PayMock.setPresetScenario(for: brand, scenario: .cancelled)

        let context = PayMockContext(brand: brand, amount: 1500, currency: "JPY")
        let result = await PayMock.present(context: context)

        XCTAssertEqual(result, .cancelled)
        PayMock.clearPresetScenarios()
    }

    @MainActor
    func testEdenredPartialBalanceDecline() async {
        PayMock.initialize()
        let brand = PaymentBrand.edenred
        PayMock.setPresetScenario(for: brand, scenario: .partialBalance(availableAmount: 15.00))

        let context = PayMockContext(brand: brand, amount: 30.00, currency: "EUR")
        let result = await PayMock.present(context: context)

        switch result {
        case .declined(let reason):
            switch reason {
            case .partialBalance(let covered, let remaining):
                XCTAssertEqual(covered, 15.00)
                XCTAssertEqual(remaining, 15.00)
            default:
                XCTFail("Expected .partialBalance decline reason")
            }
        default:
            XCTFail("Expected .declined result")
        }

        PayMock.clearPresetScenarios()
    }

    @MainActor
    func testMaestroLaunchOverridesAndOutboundURLInterception() async {
        PayMock.initialize(config: .init(autoDispatchReturnURL: false, simulateLatency: false))
        PayMock.shared.loadLaunchOverrides(
            arguments: ["App", "-PAYMOCK_FORCE_VIPPS", "cancelled"],
            environment: ["PAYMOCK_LATENCY": "0"]
        )

        let url = URL(string: "vippsMT://pay?orderId=ORD-555&amount=249.00&returnUrl=myapp://cb")!
        let result = await PayMock.handleOutboundURL(url)
        XCTAssertEqual(result, .cancelled)

        let unknownUrl = URL(string: "https://example.com/home")!
        let ignored = await PayMock.handleOutboundURL(unknownUrl)
        XCTAssertNil(ignored)

        PayMock.clearPresetScenarios()
    }
}
