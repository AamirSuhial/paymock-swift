import Foundation

/// Defines a test scenario or outcome that PayMock can simulate.
public enum PayMockScenario: Hashable, Identifiable, Codable {
    case success(transactionId: String? = nil)
    case cancelled
    case insufficientFunds
    case cardExpired
    case timeout
    case networkError
    case partialBalance(availableAmount: Double)
    case customDecline(code: String, message: String)

    public var id: String {
        switch self {
        case .success(let txId): return "success_\(txId ?? "default")"
        case .cancelled: return "cancelled"
        case .insufficientFunds: return "insufficient_funds"
        case .cardExpired: return "card_expired"
        case .timeout: return "timeout"
        case .networkError: return "network_error"
        case .partialBalance(let amt): return "partial_\(amt)"
        case .customDecline(let code, _): return "decline_\(code)"
        }
    }

    public var title: String {
        switch self {
        case .success: return "Approve (Success)"
        case .cancelled: return "User Cancelled"
        case .insufficientFunds: return "Insufficient Balance"
        case .cardExpired: return "Card Expired"
        case .timeout: return "Session Timeout"
        case .networkError: return "Network Connection Error"
        case .partialBalance(let amt): return "Partial Balance (\(String(format: "%.2f", amt)))"
        case .customDecline(let code, _): return "Declined (\(code))"
        }
    }

    public var iconName: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .insufficientFunds: return "creditcard.trianglebadge.exclamationmark"
        case .cardExpired: return "calendar.badge.exclamationmark"
        case .timeout: return "hourglass.bottomhalf.filled"
        case .networkError: return "wifi.exclamationmark"
        case .partialBalance: return "piechart.fill"
        case .customDecline: return "exclamationmark.octagon.fill"
        }
    }

    public var description: String {
        switch self {
        case .success: return "Simulates an approved payment authorized by the customer."
        case .cancelled: return "Simulates customer tapping Cancel or Go Back in the wallet."
        case .insufficientFunds: return "Declines transaction because account balance is too low."
        case .cardExpired: return "Declines due to an expired stored payment instrument."
        case .timeout: return "Customer abandons the wallet flow and session expires."
        case .networkError: return "Simulates a gateway socket failure or bank downtime."
        case .partialBalance(let amt): return "Only \(amt) is covered (test split payment flow)."
        case .customDecline(_, let msg): return msg
        }
    }
}
