//
//  EditTripView.swift
//  Travel Buddy
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI
import SwiftData

struct EditTripView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var trip: Trip
    
    @State private var tripName: String
    @State private var startDate: Date
    @State private var endDate: Date?
    @State private var hasEndDate: Bool
    @State private var selectedCurrency: Currency
    @State private var animateHeader = false
    @State private var animateForm = false
    @State private var showCurrencyPicker = false
    
    init(trip: Trip) {
        self.trip = trip
        _tripName = State(initialValue: trip.name)
        _startDate = State(initialValue: trip.startDate)
        _endDate = State(initialValue: trip.endDate)
        _hasEndDate = State(initialValue: trip.endDate != nil)
        _selectedCurrency = State(initialValue: trip.currency)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.08),
                        Color.purple.opacity(0.06),
                        Color.pink.opacity(0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .scaleEffect(animateHeader ? 1.0 : 0.8)
                                
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .scaleEffect(animateHeader ? 1.0 : 0.8)
                            }
                            
                            Text("Edit Trip")
                                .font(.title)
                                .fontWeight(.bold)
                                .opacity(animateHeader ? 1.0 : 0.0)
                            
                            Text("Update your trip details")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .opacity(animateHeader ? 1.0 : 0.0)
                        }
                        .padding(.top, 20)
                        
                        // Form Section
                        VStack(spacing: 20) {
                            // Trip Name Card
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "text.cursor")
                                        .foregroundStyle(.blue)
                                    Text("Trip Name")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                
                                TextField("Enter trip name", text: $tripName)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                            .stroke(tripName.isEmpty ? Color.gray.opacity(0.2) : Color.blue, lineWidth: tripName.isEmpty ? 1 : 2)
                                    )
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                            )
                            .scaleEffect(animateForm ? 1.0 : 0.95)
                            .opacity(animateForm ? 1 : 0)
                            
                            // Date Card
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(.purple)
                                    Text("Trip Dates")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    if hasEndDate, endDate != nil {
                                        Text("\(calculateTripDuration()) days")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [.purple, .pink],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                            )
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "airplane.departure")
                                            .font(.caption)
                                            .foregroundStyle(.purple)
                                        Text("Start Date")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    
                                    DatePicker("", selection: $startDate, displayedComponents: .date)
                                        .datePickerStyle(.graphical)
                                        .tint(.purple)
                                        .onChange(of: startDate) { oldValue, newValue in
                                            if hasEndDate, let end = endDate, end < newValue {
                                                endDate = newValue
                                            }
                                        }
                                }
                                
                                Divider()
                                    .overlay(Color.purple.opacity(0.3))
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Toggle(isOn: $hasEndDate) {
                                            HStack {
                                                Image(systemName: hasEndDate ? "airplane.arrival" : "questionmark.circle")
                                                    .font(.caption)
                                                    .foregroundStyle(hasEndDate ? .purple : .secondary)
                                                Text("End Date")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                            }
                                        }
                                        .tint(.purple)
                                        .onChange(of: hasEndDate) { oldValue, newValue in
                                            if newValue && endDate == nil {
                                                endDate = startDate.addingTimeInterval(7 * 24 * 3600)
                                            }
                                        }
                                    }
                                    
                                    if hasEndDate {
                                        DatePicker("", selection: Binding(
                                            get: { endDate ?? startDate },
                                            set: { endDate = $0 }
                                        ), in: startDate..., displayedComponents: .date)
                                            .datePickerStyle(.graphical)
                                            .tint(.purple)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                            )
                            .scaleEffect(animateForm ? 1.0 : 0.95)
                            .opacity(animateForm ? 1 : 0)
                            
                            // Currency Card
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("Currency")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                
                                Button {
                                    UISelectionFeedbackGenerator().selectionChanged()
                                    showCurrencyPicker.toggle()
                                } label: {
                                    HStack {
                                        Text(selectedCurrency.symbol)
                                            .font(.title2)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(selectedCurrency.name)
                                                .font(.body)
                                                .fontWeight(.semibold)
                                            Text(selectedCurrency.rawValue)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.down")
                                            .foregroundStyle(.secondary)
                                            .rotationEffect(.degrees(showCurrencyPicker ? 180 : 0))
                                    }
                                    .foregroundStyle(.primary)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                    )
                                }
                                
                                if showCurrencyPicker {
                                    ScrollView {
                                        VStack(spacing: 8) {
                                            ForEach(Currency.allCases, id: \.self) { currency in
                                                Button {
                                                    UISelectionFeedbackGenerator().selectionChanged()
                                                    selectedCurrency = currency
                                                    showCurrencyPicker = false
                                                } label: {
                                                    HStack {
                                                        Text(currency.symbol)
                                                            .font(.title3)
                                                        
                                                        VStack(alignment: .leading, spacing: 2) {
                                                            Text(currency.name)
                                                                .font(.body)
                                                            Text(currency.rawValue)
                                                                .font(.caption)
                                                                .foregroundStyle(.secondary)
                                                        }
                                                        
                                                        Spacer()
                                                        
                                                        if currency == selectedCurrency {
                                                            Image(systemName: "checkmark.circle.fill")
                                                                .foregroundStyle(.green)
                                                        }
                                                    }
                                                    .foregroundStyle(.primary)
                                                    .padding(12)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(currency == selectedCurrency ? Color.green.opacity(0.1) : Color(.systemGray6))
                                                    )
                                                }
                                            }
                                        }
                                    }
                                    .frame(maxHeight: 300)
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                            )
                            .scaleEffect(animateForm ? 1.0 : 0.95)
                            .opacity(animateForm ? 1 : 0)
                        }
                        .padding(.horizontal, 24)
                        
                        // Save Button
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            saveTrip()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.headline)
                                Text("Save Changes")
                                    .fontWeight(.bold)
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                Group {
                                    if tripName.isEmpty {
                                        LinearGradient(
                                            colors: [.gray, .gray.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    } else {
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    }
                                }
                            )
                            .cornerRadius(20)
                            .shadow(color: tripName.isEmpty ? .clear : .blue.opacity(0.4), radius: 15, x: 0, y: 8)
                        }
                        .disabled(tripName.isEmpty)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    animateHeader = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        animateForm = true
                    }
                }
            }
        }
    }
    
    private func calculateTripDuration() -> Int {
        guard let end = endDate else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: end)
        return max((components.day ?? 0) + 1, 1)
    }
    
    private func saveTrip() {
        trip.name = tripName
        trip.startDate = startDate
        trip.endDate = hasEndDate ? endDate : nil
        trip.currency = selectedCurrency
        
        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            print("Error saving trip: \(error)")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

#Preview {
    let userID = UserManager.shared.currentUserID
    EditTripView(trip: Trip(name: "Paris Adventure", startDate: Date(), creatorID: userID, currency: .eur))
        .modelContainer(for: [Trip.self])
}
