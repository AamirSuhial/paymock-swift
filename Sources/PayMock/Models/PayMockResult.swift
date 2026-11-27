import Foundation

/// The final outcome returned to the host application after the mock payment concludes.
public enum PayMockResult: Equatable {
    case success(TransactionDetails)
    case cancelled
    case declined(DeclineReason)
    case timeout
    case networkError

    public struct TransactionDetails: Equatable {
        public let transactionId: String
        public let token: String
        public let brand: PaymentBrand
        public let amount: Double
        public let currency: String
        public let rawQueryParameters: [String: String]

        public init(
            transactionId: String,
            token: String,
            brand: PaymentBrand,
            amount: Double,
            currency: String,
            rawQueryParameters: [String: String]
        ) {
            self.transactionId = transactionId
            self.token = token
            self.brand = brand
            self.amount = amount
            self.currency = currency
            self.rawQueryParameters = rawQueryParameters
        }
    }

    public enum DeclineReason: Equatable {
        case insufficientFunds
        case cardExpired
        case partialBalance(coveredAmount: Double, remainingAmount: Double)
        case custom(code: String, message: String)

        public var localizedDescription: String {
            switch self {
            case .insufficientFunds:
                return "The bank reported insufficient funds in the wallet."
            case .cardExpired:
                return "The registered payment method has expired."
            case .partialBalance(let covered, let remaining):
                return "Voucher only covers \(covered). Remaining \(remaining) requires secondary payment method."
            case .custom(let code, let message):
                return "[\(code)] \(message)"
            }
        }
    }
}

/// Parameters passed to present a mock payment session.
public struct PayMockContext: Equatable {
    public let brand: PaymentBrand
    public let amount: Double
    public let currency: String
    public let orderId: String
    public let returnURLScheme: String?
    public let metadata: [String: String]

    public init(
        brand: PaymentBrand,
        amount: Double,
        currency: String? = nil,
        orderId: String = "ORD-\(Int.random(in: 10000...99999))",
        returnURLScheme: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.brand = brand
        self.amount = amount
        self.currency = currency ?? brand.defaultCurrency
        self.orderId = orderId
        self.returnURLScheme = returnURLScheme
        self.metadata = metadata
    }
}
