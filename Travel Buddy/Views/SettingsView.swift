//
//  SettingsView.swift
//  Travel Buddy
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var trips: [Trip]
    
    @AppStorage("defaultCurrency") private var defaultCurrency: String = "USD"
    @AppStorage("showDecimalPlaces") private var showDecimalPlaces: Int = 2
    @AppStorage("enableNotifications") private var enableNotifications = false
    @AppStorage("userName") private var userName: String = ""
    
    @State private var showingClearDataAlert = false
    @State private var showingExportAllData = false
    @State private var showingAbout = false
    @State private var editingUserName = false
    @State private var showingLanguageSelection = false
    @State private var showingExchangeRates = false
    
    @ObservedObject var localization = LocalizationManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                // User Profile Section
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue.gradient)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            if editingUserName {
                                TextField("Your Name", text: $userName)
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Text(userName.isEmpty ? "Tap to set your name" : userName)
                                    .font(.headline)
                                
                                Text("Device Owner")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            editingUserName.toggle()
                        } label: {
                            Text(editingUserName ? "Done" : "Edit")
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Profile")
                }
                
                // App Preferences
                Section {
                    // Language Selection
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showingLanguageSelection = true
                    } label: {
                        HStack {
                            Label("Language", systemImage: "globe")
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Text(localization.currentLanguage.flag)
                                Text(localization.currentLanguage.rawValue)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Picker("Default Currency", selection: $defaultCurrency) {
                        ForEach(Currency.allCases, id: \.rawValue) { currency in
                            Text("\(currency.symbol) \(currency.name)")
                                .tag(currency.rawValue)
                        }
                    }
                    
                    Picker("Decimal Places", selection: $showDecimalPlaces) {
                        Text("None (0)").tag(0)
                        Text("One (0.0)").tag(1)
                        Text("Two (0.00)").tag(2)
                    }
                    
                    Toggle("Enable Notifications", isOn: $enableNotifications)
                } header: {
                    Text("Preferences")
                } footer: {
                    Text("Default currency is used when creating new trips")
                }
                
                // Exchange Rates Section
                Section {
                    NavigationLink(destination: ExchangeRateSettingsView()) {
                        HStack {
                            Label("Exchange Rates", systemImage: "dollarsign.arrow.circlepath")
                            
                            Spacer()
                            
                            Text(ExchangeRateService.shared.lastUpdatedText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Currency")
                } footer: {
                    Text("View and update live exchange rates for currency conversion")
                }
                
                // Statistics
                Section {
                    HStack {
                        Label("Total Trips", systemImage: "airplane")
                        Spacer()
                        Text("\(trips.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("Total Expenses", systemImage: "receipt")
                        Spacer()
                        Text("\(totalExpensesCount)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("Total Spent", systemImage: "dollarsign.circle")
                        Spacer()
                        Text(formatTotalSpent())
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Statistics")
                }
                
                // Data Management
                Section {
                    NavigationLink(destination: DataStorageView()) {
                        Label("Storage & Privacy", systemImage: "internaldrive.fill")
                    }
                    
                    Button {
                        showingExportAllData = true
                    } label: {
                        Label("Export All Data", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive) {
                        showingClearDataAlert = true
                    } label: {
                        Label("Clear All Data", systemImage: "trash")
                    }
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("View where your data is stored and how it's protected. Export creates a backup of all your trips.")
                }
                
                // Privacy & Security
                Section {
                    HStack {
                        Label("Data Storage", systemImage: "lock.shield")
                        Spacer()
                        Text("Local Only")
                            .foregroundStyle(.green)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Label("Cloud Sync", systemImage: "icloud")
                        Spacer()
                        Text("Disabled")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    
                    HStack {
                        Label("Analytics", systemImage: "chart.bar")
                        Spacer()
                        Text("None")
                            .foregroundStyle(.green)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                } header: {
                    Text("Privacy & Security")
                } footer: {
                    Text("Your data stays on your device. No tracking, no cloud storage, complete privacy.")
                }
                
                // About
                Section {
                    Button {
                        showingAbout = true
                    } label: {
                        HStack {
                            Label("About Travel Buddy", systemImage: "info.circle")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                    
                    HStack {
                        Label("Version", systemImage: "number")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .safeAreaInset(edge: .bottom) {
                BannerViewContainer(bannerAdType: .randomAd)
                    .frame(height: 60)
                    .background(Color(.systemBackground))
            }
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All Data", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will permanently delete all trips, expenses, and payments. This action cannot be undone.")
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingExportAllData) {
                ExportAllDataView(trips: trips)
            }
            .sheet(isPresented: $showingLanguageSelection) {
                LanguageSelectionView()
            }
        }
    }
    
    private var totalExpensesCount: Int {
        trips.reduce(0) { $0 + $1.expenses.count }
    }
    
    private func formatTotalSpent() -> String {
        var totalsByGroup: [String: Double] = [:]
        
        for trip in trips {
            let currencyCode = trip.currencyCode
            let total = trip.totalExpenses
            totalsByGroup[currencyCode, default: 0] += total
        }
        
        if totalsByGroup.isEmpty {
            return "$0.00"
        }
        
        // Show the primary currency total
        let sorted = totalsByGroup.sorted { $0.value > $1.value }
        if let primary = sorted.first {
            let currency = Currency(rawValue: primary.key) ?? .usd
            return currency.format(primary.value)
        }
        
        return "$0.00"
    }
    
    private func clearAllData() {
        for trip in trips {
            modelContext.delete(trip)
        }
        
        // Reset user preferences
        userName = ""
        
        try? modelContext.save()
    }
}

// About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon
                    Image(systemName: "airplane.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(.blue.gradient)
                        .padding(.top, 32)
                    
                    VStack(spacing: 8) {
                        Text("Travel Buddy")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        AboutFeatureRow(icon: "person.2.fill", title: "Split Expenses", description: "Easily divide costs among travel buddies")
                        AboutFeatureRow(icon: "camera.fill", title: "Receipt Scanning", description: "OCR technology extracts amounts automatically")
                        AboutFeatureRow(icon: "dollarsign.circle.fill", title: "Track Payments", description: "Record settlements and balance tracking")
                        AboutFeatureRow(icon: "chart.bar.fill", title: "Smart Analytics", description: "Visual breakdowns and summaries")
                        AboutFeatureRow(icon: "banknote.fill", title: "Multi-Currency", description: "Support for 20+ currencies")
                        AboutFeatureRow(icon: "lock.shield.fill", title: "100% Private", description: "All data stored locally on device")
                        AboutFeatureRow(icon: "square.and.arrow.up.fill", title: "Share & Export", description: "QR codes, JSON, and CSV export")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Privacy Statement
                    VStack(spacing: 12) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.green)
                        
                        Text("Your Privacy Matters")
                            .font(.headline)
                        
                        Text("Travel Buddy stores all data locally on your device. No cloud services, no analytics, no tracking. Your trip data stays yours.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.vertical, 24)
                    
                    Text("© 2026 Travel Buddy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 32)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AboutFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }
}

// Export All Data View
struct ExportAllDataView: View {
    @Environment(\.dismiss) private var dismiss
    let trips: [Trip]
    
    @State private var shareItem: URL?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "tray.and.arrow.up.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue.gradient)
                    .padding(.top, 32)
                
                VStack(spacing: 8) {
                    Text("Export All Data")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Create a complete backup of all your trips")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("\(trips.count) trips")
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("\(trips.reduce(0) { $0 + $1.expenses.count }) expenses")
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("\(trips.reduce(0) { $0 + $1.travelBuddies.count }) travel buddies")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 32)
                
                Spacer()
                
                Button {
                    exportAllData()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export as JSON")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.gradient)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(item: Binding(
                get: { shareItem.map { ShareItemWrapper(url: $0) } },
                set: { shareItem = $0?.url }
            )) { item in
                ShareSheet(items: [item.url])
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func exportAllData() {
        do {
            let exportData = trips.map { TripExport.from(trip: $0) }
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            
            let jsonData = try encoder.encode(exportData)
            
            let fileName = "TravelBuddy_AllTrips_\(Date().timeIntervalSince1970).json"
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            try jsonData.write(to: fileURL)
            shareItem = fileURL
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

struct ShareItemWrapper: Identifiable {
    let id = UUID()
    let url: URL
}

#Preview {
    SettingsView()
        .modelContainer(for: [Trip.self, TravelBuddy.self, Expense.self])
}
