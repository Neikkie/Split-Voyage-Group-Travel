//
//  ExchangeRateSettingsView.swift
//  Split Voyage Group Travel
//
//  Created by Shanique Beckford on 3/16/26.
//

import SwiftUI

struct ExchangeRateSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var rateService = ExchangeRateService.shared
    
    @State private var showingManualEntry = false
    @State private var selectedCurrency: Currency?
    @State private var manualRate: String = ""
    @State private var searchText = ""
    
    var filteredCurrencies: [Currency] {
        if searchText.isEmpty {
            return Currency.allCases
        }
        return Currency.allCases.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.05),
                        Color.purple.opacity(0.03),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Card
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue.opacity(0.2), .purple.opacity(0.15)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "dollarsign.arrow.circlepath")
                                    .font(.system(size: 40))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            VStack(spacing: 8) {
                                Text("Exchange Rates")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(rateService.lastUpdatedText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                if rateService.needsUpdate {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.caption2)
                                        Text("Rates may be outdated")
                                            .font(.caption2)
                                    }
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.orange.opacity(0.1))
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 20)
                        
                        // Update Button
                        Button {
                            Task {
                                await rateService.fetchRates()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                if rateService.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.title3)
                                }
                                Text(rateService.isLoading ? "Updating..." : "Update Rates from API")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(rateService.isLoading)
                        .padding(.horizontal)
                        
                        // Error message
                        if let error = rateService.error {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(error)
                                    .font(.caption)
                            }
                            .foregroundStyle(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.1))
                            )
                            .padding(.horizontal)
                        }
                        
                        // Currency Rates List
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Currency Rates")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                Text("Base: USD")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                ForEach(filteredCurrencies, id: \.self) { currency in
                                    CurrencyRateRow(
                                        currency: currency,
                                        rate: rateService.getRate(for: currency) ?? currency.rateToUSD,
                                        isLiveRate: rateService.getRate(for: currency) != nil,
                                        onEditTap: {
                                            selectedCurrency = currency
                                            manualRate = String(format: "%.4f", rateService.getRate(for: currency) ?? currency.rateToUSD)
                                            showingManualEntry = true
                                        }
                                    )
                                    
                                    if currency != filteredCurrencies.last {
                                        Divider()
                                            .padding(.leading, 68)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                            .padding(.horizontal)
                        }
                        .padding(.top, 8)
                        
                        // Info Card
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("About Exchange Rates")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text("Rates are fetched from exchangerate-api.io and cached for offline use. Tap any currency to set a manual rate.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
                .searchable(text: $searchText, prompt: "Search currencies")
            }
            .navigationTitle("Exchange Rates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingManualEntry) {
                if let currency = selectedCurrency {
                    ManualRateEntryView(
                        currency: currency,
                        currentRate: manualRate,
                        onSave: { newRate in
                            if let rate = Double(newRate) {
                                rateService.setManualRate(currency: currency.rawValue, rate: rate)
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Currency Rate Row
struct CurrencyRateRow: View {
    let currency: Currency
    let rate: Double
    let isLiveRate: Bool
    let onEditTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Currency Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.2), .purple.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Text(currency.symbol)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(currency.rawValue)
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    if isLiveRate {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                
                Text(currency.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.4f", rate))
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text("per USD")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Button {
                onEditTap()
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
        }
        .padding()
    }
}

// MARK: - Manual Rate Entry View
struct ManualRateEntryView: View {
    @Environment(\.dismiss) private var dismiss
    let currency: Currency
    @State var currentRate: String
    let onSave: (String) -> Void
    
    @State private var notes: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(currency.symbol)
                            .font(.title)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading) {
                            Text(currency.rawValue)
                                .font(.headline)
                            Text(currency.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Currency")
                }
                
                Section {
                    HStack {
                        Text("Rate")
                            .foregroundStyle(.secondary)
                        
                        TextField("0.0000", text: $currentRate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .focused($isFocused)
                    }
                    
                    HStack {
                        Text("Base")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("1 USD")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Exchange Rate")
                } footer: {
                    Text("Enter how many \(currency.rawValue) equals 1 USD")
                }
                
                Section {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                } footer: {
                    Text("Add a note about this manual rate (e.g., 'Airport rate' or 'Hotel exchange')")
                }
            }
            .navigationTitle("Set Manual Rate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(currentRate)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(currentRate.isEmpty || Double(currentRate) == nil)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}

#Preview {
    ExchangeRateSettingsView()
}
