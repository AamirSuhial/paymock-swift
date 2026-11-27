import Foundation
import SwiftUI

/// Represents a supported local payment method or digital wallet brand.
public enum PaymentBrand: String, CaseIterable, Identifiable, Codable {
    case vipps = "vipps"
    case paypay = "paypay"
    case edenred = "edenred"
    case ideal = "ideal"
    case twint = "twint"
    case blik = "blik"
    case klarna = "klarna"
    case swish = "swish"
    case pix = "pix"
    case grabpay = "grabpay"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .vipps: return "Vipps MobilePay"
        case .paypay: return "PayPay"
        case .edenred: return "Edenred Ticket Restaurant"
        case .ideal: return "iDEAL / Wero"
        case .twint: return "TWINT"
        case .blik: return "BLIK"
        case .klarna: return "Klarna"
        case .swish: return "Swish"
        case .pix: return "Pix"
        case .grabpay: return "GrabPay"
        }
    }

    public var region: String {
        switch self {
        case .vipps: return "Nordics (NO / DK / FI)"
        case .paypay: return "Japan"
        case .edenred: return "Global / Europe & LATAM"
        case .ideal: return "Netherlands & EU"
        case .twint: return "Switzerland"
        case .blik: return "Poland"
        case .klarna: return "Global (BNPL)"
        case .swish: return "Sweden"
        case .pix: return "Brazil"
        case .grabpay: return "Southeast Asia"
        }
    }

    public var defaultCurrency: String {
        switch self {
        case .vipps: return "NOK"
        case .paypay: return "JPY"
        case .edenred: return "EUR"
        case .ideal: return "EUR"
        case .twint: return "CHF"
        case .blik: return "PLN"
        case .klarna: return "EUR"
        case .swish: return "SEK"
        case .pix: return "BRL"
        case .grabpay: return "SGD"
        }
    }

    public var badgeSymbol: String {
        switch self {
        case .vipps: return "iphone.radiowaves.left.and.right"
        case .paypay: return "qrcode"
        case .edenred: return "fork.knife.circle.fill"
        case .ideal: return "building.columns.fill"
        case .twint: return "arrow.left.arrow.right.circle.fill"
        case .blik: return "number.circle.fill"
        case .klarna: return "creditcard.circle.fill"
        case .swish: return "arrow.triangle.swap"
        case .pix: return "bolt.shield.fill"
        case .grabpay: return "car.circle.fill"
        }
    }

    public var brandColor: Color {
        switch self {
        case .vipps: return Color(red: 1.0, green: 0.36, blue: 0.16) // #FF5B29
        case .paypay: return Color(red: 0.88, green: 0.14, blue: 0.18) // #E0242E
        case .edenred: return Color(red: 0.91, green: 0.20, blue: 0.20) // #E83333
        case .ideal: return Color(red: 0.80, green: 0.05, blue: 0.45) // #CC0D73
        case .twint: return Color(red: 0.0, green: 0.65, blue: 0.38) // #00A661
        case .blik: return Color(red: 0.91, green: 0.33, blue: 0.13) // #E85421
        case .klarna: return Color(red: 1.0, green: 0.70, blue: 0.78) // #FFB3C7
        case .swish: return Color(red: 0.14, green: 0.54, blue: 0.84) // #248AD6
        case .pix: return Color(red: 0.19, green: 0.69, blue: 0.62) // #32B09F
        case .grabpay: return Color(red: 0.0, green: 0.69, blue: 0.31) // #00B14F
        }
    }

    public var defaultScheme: String {
        switch self {
        case .vipps: return "vippsMT://"
        case .paypay: return "paypay://"
        case .edenred: return "edenred://"
        case .ideal: return "ideal://"
        case .twint: return "twint://"
        case .blik: return "blik://"
        case .klarna: return "klarna://"
        case .swish: return "swish://"
        case .pix: return "pix://"
        case .grabpay: return "grabpay://"
        }
    }
}
