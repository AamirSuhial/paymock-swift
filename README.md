# PayMockKit for Swift (iOS)

> **Zero-Friction In-App Mock Testing for 100+ Global Payment Methods and Local Wallets.**

PayMock eliminates the nightmare of testing complex mobile payment flows (app-switches, third-party redirects, TestFlight dependency). Instead of switching out to external bank apps, PayMock intercepts the payment call right inside your host app and presents a **branded popover sheet** allowing you or your QA team to mimic **Success, Cancellation, Insufficient Funds, Voucher Splits, and Timeouts** in seconds.

---

## 🚀 Features

- **In-App Popover Simulator:** Stays 100% inside your app. No TestFlight apps, no companion apps, and no physical device farms needed.
- **10+ Pre-Configured Global Brands (Expandable to 100+):**
  - **Nordics:** Vipps MobilePay, Swish
  - **Europe:** iDEAL / Wero, TWINT (Switzerland), BLIK (Poland)
  - **Asia-Pacific:** PayPay (Japan), GrabPay
  - **LATAM:** Pix (Brazil)
  - **Vouchers / Meal Benefits:** Edenred Ticket Restaurant (with partial balance split test)
  - **BNPL:** Klarna
- **Zero-Code Interception:** Automatically intercepts outbound payment URLs in `DEBUG` builds.
- **Headless Mode for CI:** Pre-set desired scenarios in unit/UI tests without presenting any UI.
- **Async/Await & SwiftUI Ready:** First-class support for modern Swift concurrency and SwiftUI view modifiers.

---

## 📦 Installation

Add PayMock to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/paymock-swift.git", from: "1.0.0")
]
```

Or in Xcode: **File > Add Package Dependencies...** and point to the repository.

---

## 🛠 Quickstart

### 1. Initialize on App Launch (Debug Only)
```swift
import SwiftUI
#if DEBUG
import PayMock
#endif

@main
struct MyApp: App {
    init() {
        #if DEBUG
        PayMock.initialize(config: .init(
            simulateLatency: true,
            latencySeconds: 0.6
        ))
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .payMockGlobalContainer() // Enables in-app popovers globally
        }
    }
}
```

### 2. Presenting Mock Payments (Async/Await)
```swift
Task {
    let result = await PayMock.present(context: .init(
        brand: .vipps,
        amount: 249.00,
        currency: "NOK"
    ))

    switch result {
    case .success(let details):
        print("Payment Approved! TX ID: \(details.transactionId), Token: \(details.token)")

    case .cancelled:
        print("User cancelled payment in Vipps.")

    case .declined(let reason):
        print("Declined: \(reason.localizedDescription)")

    case .timeout:
        print("Wallet session timed out.")

    case .networkError:
        print("Network error.")
    }
}
```

### 3. SwiftUI View Modifier
```swift
struct MyCheckoutView: View {
    @State private var showMockSheet = false

    var body: some View {
        Button("Pay with PayPay") {
            showMockSheet = true
        }
        .payMockSheet(
            isPresented: $showMockSheet,
            brand: .paypay,
            amount: 1500,
            currency: "JPY"
        ) { result in
            handleResult(result)
        }
    }
}
```

---

## 🤖 Automated CI / Headless Mode

For automated UI tests (XCTest, Maestro, Appium), bypass the interactive popover by setting a pre-determined scenario:

```swift
// In your test case:
func testVippsCancellation() async {
    // 1. Force the outcome:
    PayMock.setPresetScenario(for: .vipps, scenario: .cancelled)

    // 2. Execute checkout:
    let result = await PayMock.present(context: .init(brand: .vipps, amount: 249.00))

    // 3. Assert:
    XCTAssertEqual(result, .cancelled)
}
```

---

## 📂 Project Structure

```
paymock-swift/
├── Package.swift
├── Sources/
│   └── PayMock/
│       ├── Core/PayMock.swift
│       ├── Models/
│       │   ├── PaymentBrand.swift
│       │   ├── PayMockScenario.swift
│       │   └── PayMockResult.swift
│       └── UI/
│           ├── PayMockSheetView.swift
│           └── SwiftUI+PayMock.swift
├── Examples/
│   └── PayMockExample/
│       └── Sources/
│           ├── App.swift
│           └── CheckoutView.swift
└── Tests/
    └── PayMockTests/
        └── PayMockTests.swift
```
