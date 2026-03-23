//
//  Currency.swift
//  Split Voyage Group Travel
//
//  Created by Shanique Beckford on 3/12/26.
//

import Foundation

enum Currency: String, CaseIterable, Codable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    case cad = "CAD"
    case aud = "AUD"
    case chf = "CHF"
    case cny = "CNY"
    case inr = "INR"
    case mxn = "MXN"
    case brl = "BRL"
    case krw = "KRW"
    case sgd = "SGD"
    case nzd = "NZD"
    case hkd = "HKD"
    case sek = "SEK"
    case nok = "NOK"
    case dkk = "DKK"
    case zar = "ZAR"
    case thb = "THB"
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy: return "¥"
        case .cad: return "CA$"
        case .aud: return "A$"
        case .chf: return "CHF"
        case .cny: return "¥"
        case .inr: return "₹"
        case .mxn: return "MX$"
        case .brl: return "R$"
        case .krw: return "₩"
        case .sgd: return "S$"
        case .nzd: return "NZ$"
        case .hkd: return "HK$"
        case .sek: return "kr"
        case .nok: return "kr"
        case .dkk: return "kr"
        case .zar: return "R"
        case .thb: return "฿"
        }
    }
    
    var name: String {
        switch self {
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .gbp: return "British Pound"
        case .jpy: return "Japanese Yen"
        case .cad: return "Canadian Dollar"
        case .aud: return "Australian Dollar"
        case .chf: return "Swiss Franc"
        case .cny: return "Chinese Yuan"
        case .inr: return "Indian Rupee"
        case .mxn: return "Mexican Peso"
        case .brl: return "Brazilian Real"
        case .krw: return "South Korean Won"
        case .sgd: return "Singapore Dollar"
        case .nzd: return "New Zealand Dollar"
        case .hkd: return "Hong Kong Dollar"
        case .sek: return "Swedish Krona"
        case .nok: return "Norwegian Krone"
        case .dkk: return "Danish Krone"
        case .zar: return "South African Rand"
        case .thb: return "Thai Baht"
        }
    }
    
    // Exchange rates relative to USD (base)
    // Note: In a production app, these would be fetched from an API
    // For privacy, we use hardcoded rates that users can manually update
    var rateToUSD: Double {
        switch self {
        case .usd: return 1.0
        case .eur: return 0.92
        case .gbp: return 0.79
        case .jpy: return 149.50
        case .cad: return 1.36
        case .aud: return 1.52
        case .chf: return 0.88
        case .cny: return 7.24
        case .inr: return 83.12
        case .mxn: return 17.05
        case .brl: return 4.97
        case .krw: return 1319.50
        case .sgd: return 1.34
        case .nzd: return 1.63
        case .hkd: return 7.82
        case .sek: return 10.36
        case .nok: return 10.58
        case .dkk: return 6.87
        case .zar: return 18.65
        case .thb: return 35.48
        }
    }
    
    // Convert amount from this currency to another currency
    func convert(amount: Double, to targetCurrency: Currency, useLiveRates: Bool = true) -> Double {
        // Try to use live rates if available and requested
        if useLiveRates {
            return ExchangeRateService.shared.convert(amount: amount, from: self, to: targetCurrency)
        }
        
        // Fall back to hardcoded rates
        let amountInUSD = amount / self.rateToUSD
        let convertedAmount = amountInUSD * targetCurrency.rateToUSD
        return convertedAmount
    }
    
    // Get current live rate if available, otherwise return hardcoded rate
    var currentRate: Double {
        ExchangeRateService.shared.getRate(for: self) ?? rateToUSD
    }
    
    // Format amount with currency symbol
    func format(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = symbol
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(symbol)\(String(format: "%.2f", amount))"
    }
}

// Helper extension for Trip to get formatted currency strings
extension Trip {
    func formatCurrency(_ amount: Double) -> String {
        currency.format(amount)
    }
    
    func convertAndFormat(_ amount: Double, from sourceCurrency: Currency) -> String {
        let converted = sourceCurrency.convert(amount: amount, to: currency)
        return currency.format(converted)
    }
}
