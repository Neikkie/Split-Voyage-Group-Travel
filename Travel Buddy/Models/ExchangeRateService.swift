//
//  ExchangeRateService.swift
//  Split Voyage Group Travel
//
//  Created by Shanique Beckford on 3/16/26.
//

import Foundation
import SwiftData
import Combine

/// Service for fetching and caching exchange rates
@MainActor
class ExchangeRateService: ObservableObject {
    static let shared = ExchangeRateService()
    
    @Published var rates: [String: Double] = [:]
    @Published var lastUpdated: Date?
    @Published var isLoading = false
    @Published var error: String?
    
    private let apiKey = "free" // Using free tier of exchangerate-api.io
    private let baseURL = "https://api.exchangerate-api.com/v4/latest"
    private let cacheKey = "cachedExchangeRates"
    private let lastUpdateKey = "lastExchangeRateUpdate"
    
    private init() {
        loadCachedRates()
        
        // Auto-fetch if rates are stale (older than 24 hours)
        if needsUpdate {
            Task {
                await fetchRates()
            }
        }
    }
    
    /// Fetch latest rates from API
    func fetchRates(baseCurrency: String = "USD") async {
        isLoading = true
        error = nil
        
        guard let url = URL(string: "\(baseURL)/\(baseCurrency)") else {
            error = "Invalid API URL"
            isLoading = false
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                error = "Failed to fetch rates: Invalid response"
                isLoading = false
                return
            }
            
            let result = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
            
            rates = result.rates
            lastUpdated = Date()
            
            // Cache the rates
            cacheRates()
            
            isLoading = false
        } catch {
            self.error = "Failed to fetch rates: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    /// Load rates from cache
    private func loadCachedRates() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            rates = decoded
        }
        
        if let timestamp = UserDefaults.standard.object(forKey: lastUpdateKey) as? Date {
            lastUpdated = timestamp
        }
    }
    
    /// Cache rates to UserDefaults
    private func cacheRates() {
        if let encoded = try? JSONEncoder().encode(rates) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
        
        if let lastUpdated = lastUpdated {
            UserDefaults.standard.set(lastUpdated, forKey: lastUpdateKey)
        }
    }
    
    /// Set manual rate for a currency
    func setManualRate(currency: String, rate: Double) {
        rates[currency] = rate
        lastUpdated = Date()
        cacheRates()
    }
    
    /// Convert amount between currencies
    func convert(amount: Double, from: Currency, to: Currency) -> Double {
        // If we have live rates, use them
        if !rates.isEmpty {
            let fromRate = rates[from.rawValue] ?? from.rateToUSD
            let toRate = rates[to.rawValue] ?? to.rateToUSD
            
            // Convert to USD first, then to target
            let amountInUSD = amount / fromRate
            return amountInUSD * toRate
        }
        
        // Fall back to hardcoded rates
        return from.convert(amount: amount, to: to)
    }
    
    /// Get rate for a specific currency
    func getRate(for currency: Currency) -> Double? {
        rates[currency.rawValue]
    }
    
    /// Check if rates need updating (older than 24 hours)
    var needsUpdate: Bool {
        guard let lastUpdated = lastUpdated else { return true }
        return Date().timeIntervalSince(lastUpdated) > 24 * 60 * 60
    }
    
    /// Format last updated time
    var lastUpdatedText: String {
        guard let lastUpdated = lastUpdated else {
            return "Never updated"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Updated \(formatter.localizedString(for: lastUpdated, relativeTo: Date()))"
    }
}

/// Response model for exchange rate API
struct ExchangeRateResponse: Codable {
    let base: String
    let date: String
    let rates: [String: Double]
}

/// SwiftData model for storing manual rate overrides
@Model
final class ManualExchangeRate {
    var currencyCode: String
    var rate: Double
    var updatedAt: Date
    var notes: String
    
    init(currencyCode: String, rate: Double, notes: String = "") {
        self.currencyCode = currencyCode
        self.rate = rate
        self.updatedAt = Date()
        self.notes = notes
    }
}
