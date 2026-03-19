//
//  AddTripItemView.swift
//  Travel Buddy
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI
import SwiftData

struct AddTripItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var trip: Trip
    
    @State private var selectedType: TripItemType = .activity
    @State private var name = ""
    @State private var notes = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var location = ""
    @State private var cost = ""
    @State private var isPaid = false
    @State private var confirmationNumber = ""
    
    // Animation states
    @State private var animateHeader = false
    @State private var animateFields = false
    @State private var showSuccessAnimation = false
    @State private var showAddToExpensesPrompt = false
    @State private var savedItem: TripItem?
    
    // Accommodation specific
    @State private var address = ""
    @State private var checkInTime = Date()
    @State private var checkOutTime = Date()
    
    // Flight specific
    @State private var airline = ""
    @State private var flightNumber = ""
    @State private var departureAirport = ""
    @State private var arrivalAirport = ""
    @State private var departureTime = Date()
    @State private var arrivalTime = Date()
    
    // Activity/Restaurant specific
    @State private var reservationTime = Date()
    @State private var phoneNumber = ""
    @State private var website = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                // Info banner
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Quick Save Available")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Fill in what you know now and add details later by editing")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                )
                
                Section {
                    Picker("Type", selection: $selectedType) {
                        ForEach(TripItemType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    HStack {
                        Image(systemName: selectedType.icon)
                            .foregroundStyle(.blue)
                        Text("Select Item Type")
                    }
                } footer: {
                    Text("Choose the type of reservation or booking you want to add")
                        .font(.caption)
                }
                
                switch selectedType {
                case .accommodation:
                    accommodationFields
                case .flight:
                    flightFields
                case .transportation:
                    transportationFields
                case .activity:
                    activityFields
                case .restaurant:
                    restaurantFields
                }
                
                if selectedType == .activity {
                    // Enhanced Payment section for activities
                    Section {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.green.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "dollarsign.circle.fill")
                                        .foregroundStyle(.green)
                                }
                                
                                HStack {
                                    Text(trip.currency.symbol)
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                    TextField("0.00", text: $cost)
                                        .keyboardType(.decimalPad)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                }
                            }
                            
                            Divider()
                            
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isPaid ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: isPaid ? "checkmark.seal.fill" : "clock.fill")
                                        .foregroundStyle(isPaid ? .green : .gray)
                                        .symbolEffect(.bounce, value: isPaid)
                                }
                                
                                Toggle(isOn: $isPaid) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Payment Status")
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                        Text(isPaid ? "Paid" : "Pending")
                                            .font(.caption)
                                            .foregroundStyle(isPaid ? .green : .secondary)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "number.circle.fill")
                                        .foregroundStyle(.blue)
                                        .symbolEffect(.pulse, value: confirmationNumber)
                                }
                                
                                TextField("Confirmation #", text: $confirmationNumber)
                                    .font(.body)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.characters)
                            }
                        }
                        .padding(.vertical, 4)
                        .opacity(animateFields ? 1.0 : 0.0)
                        .offset(x: animateFields ? 0 : -20)
                    } header: {
                        Label("Booking Details", systemImage: "creditcard.fill")
                            .foregroundStyle(.green)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    } footer: {
                        Text("Add cost and confirmation number for your booking")
                            .font(.caption)
                    }
                    
                    // Enhanced Notes section for activities
                    Section {
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.orange.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "note.text")
                                    .foregroundStyle(.orange)
                            }
                            
                            TextField("Special instructions, tips, what to bring...", text: $notes, axis: .vertical)
                                .font(.body)
                                .lineLimit(3...6)
                        }
                        .padding(.vertical, 4)
                        .opacity(animateFields ? 1.0 : 0.0)
                        .offset(x: animateFields ? 0 : -20)
                    } header: {
                        Label("Notes (Optional)", systemImage: "pencil")
                            .foregroundStyle(.orange)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    } footer: {
                        Text("Add any important reminders or details about this activity")
                            .font(.caption)
                    }
                } else {
                    // Standard payment section for other types
                    Section {
                        HStack {
                            Text(trip.currency.symbol)
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $cost)
                                .keyboardType(.decimalPad)
                        }
                        
                        Toggle(isOn: $isPaid) {
                            HStack {
                                Text("Paid")
                                if isPaid {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.caption)
                                }
                            }
                        }
                        
                        TextField("Confirmation Number (Optional)", text: $confirmationNumber)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                    } header: {
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .foregroundStyle(.green)
                            Text("Payment & Confirmation")
                        }
                    } footer: {
                        Text("Add your booking confirmation number to keep all details organized")
                            .font(.caption)
                    }
                    
                    Section {
                        TextField("Additional notes or special instructions...", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                    } header: {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundStyle(.orange)
                            Text("Notes")
                        }
                    }
                }
            }
            .navigationTitle("Add \(selectedType.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        addTripItem()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
            
                // Success Animation Overlay
                if showSuccessAnimation {
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                            
                            Text("Activity Added!")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(30)
                        .shadow(color: .green.opacity(0.5), radius: 20, x: 0, y: 10)
                        .scaleEffect(showSuccessAnimation ? 1.0 : 0.5)
                        .opacity(showSuccessAnimation ? 1.0 : 0.0)
                        
                        Spacer()
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .alert("Add to Expenses?", isPresented: $showAddToExpensesPrompt) {
                Button("Yes, Add to Expenses") {
                    createExpenseFromItem()
                    dismissAfterSave()
                }
                Button("No, Just Itinerary") {
                    dismissAfterSave()
                }
            } message: {
                if let item = savedItem {
                    Text("This \(item.type.rawValue) costs \(trip.currency.format(item.cost)). Would you like to add it to your expenses for tracking and splitting with buddies?")
                }
            }
        }
    }
    
    private func dismissAfterSave() {
        if selectedType == .activity {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showSuccessAnimation = true
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        }
    }
    
    private func createExpenseFromItem() {
        guard let item = savedItem else { return }
        
        // Create an expense from the trip item
        let expense = Expense(
            name: item.name,
            totalAmount: item.cost,
            date: item.startDate,
            participantIDs: trip.travelBuddies.map { $0.id },
            splitType: .equal,
            paidByBuddyID: nil  // User can set this later
        )
        
        expense.trip = trip
        
        // Create splits for each buddy
        for buddy in trip.travelBuddies {
            let split = ExpenseSplit(
                buddyID: buddy.id,
                amount: expense.amountPerPerson(),
                amountPaid: 0,
                isPaidInFull: false
            )
            split.expense = expense
            expense.splits.append(split)
        }
        
        modelContext.insert(expense)
        trip.expenses.append(expense)
        
        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            print("Error creating expense from itinerary item: \(error)")
        }
    }
    
    private var accommodationFields: some View {
        Section {
            TextField("Hotel/Airbnb Name", text: $name)
                .autocorrectionDisabled()
            TextField("Full Address", text: $address, axis: .vertical)
                .lineLimit(2...3)
            DatePicker("Check-in", selection: $checkInTime)
            DatePicker("Check-out", selection: $checkOutTime)
        } header: {
            Text("Accommodation Details")
        } footer: {
            Text("Enter your hotel or rental property information")
                .font(.caption)
        }
    }
    
    private var flightFields: some View {
        Section {
            TextField("Airline (e.g., Delta, United)", text: $airline)
                .autocorrectionDisabled()
            TextField("Flight Number (e.g., DL123)", text: $flightNumber)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
            TextField("Departure Airport Code (e.g., JFK)", text: $departureAirport)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
            TextField("Arrival Airport Code (e.g., LAX)", text: $arrivalAirport)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
            DatePicker("Departure Time", selection: $departureTime)
            DatePicker("Arrival Time", selection: $arrivalTime)
        } header: {
            Text("Flight Details")
        } footer: {
            Text("Add your flight information and confirmation number for easy reference")
                .font(.caption)
        }
    }
    
    private var transportationFields: some View {
        Section {
            TextField("Name (e.g., Rental Car, Train, Bus)", text: $name)
                .autocorrectionDisabled()
            TextField("Location/Pickup Address", text: $location, axis: .vertical)
                .lineLimit(2...3)
            DatePicker("Pickup Date & Time", selection: $startDate)
            DatePicker("Return Date & Time", selection: $endDate)
        } header: {
            Text("Transportation Details")
        } footer: {
            Text("Car rentals, trains, buses, and other ground transportation")
                .font(.caption)
        }
    }
    
    private var activityFields: some View {
        Group {
            // Hero Section with Icon
            Section {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple.opacity(0.2), .blue.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .scaleEffect(animateHeader ? 1.0 : 0.5)
                            .opacity(animateHeader ? 1.0 : 0.0)
                        
                        Image(systemName: "figure.walk")
                            .font(.system(size: 35))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .rotationEffect(.degrees(animateHeader ? 0 : -180))
                            .scaleEffect(animateHeader ? 1.0 : 0.5)
                    }
                    
                    Text("Plan Your Activity")
                        .font(.title2)
                        .fontWeight(.bold)
                        .opacity(animateHeader ? 1.0 : 0.0)
                        .offset(y: animateHeader ? 0 : 20)
                    
                    Text("Add tours, shows, attractions, and experiences")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(animateHeader ? 1.0 : 0.0)
                        .offset(y: animateHeader ? 0 : 20)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        animateHeader = true
                    }
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                        animateFields = true
                    }
                }
            }
            .listRowBackground(Color.clear)
            
            // Activity Name
            Section {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.purple.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "ticket.fill")
                            .foregroundStyle(.purple)
                            .symbolEffect(.bounce, value: name)
                    }
                    
                    TextField("What are you doing?", text: $name)
                        .font(.body)
                        .autocorrectionDisabled()
                }
                .padding(.vertical, 4)
                .opacity(animateFields ? 1.0 : 0.0)
                .offset(x: animateFields ? 0 : -20)
            } header: {
                Label("Activity Name", systemImage: "star.fill")
                    .foregroundStyle(.purple)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            // Location
            Section {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.blue)
                            .symbolEffect(.pulse, value: location)
                    }
                    
                    TextField("Where is it located?", text: $location, axis: .vertical)
                        .font(.body)
                        .lineLimit(1...3)
                }
                .padding(.vertical, 4)
                .opacity(animateFields ? 1.0 : 0.0)
                .offset(x: animateFields ? 0 : -20)
            } header: {
                Label("Location/Venue", systemImage: "location.fill")
                    .foregroundStyle(.blue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            // Date & Time
            Section {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "calendar")
                                .foregroundStyle(.green)
                                .symbolEffect(.bounce, value: startDate)
                        }
                        
                        DatePicker("Date", selection: $startDate, displayedComponents: .date)
                            .font(.body)
                    }
                    
                    Divider()
                        .overlay(Color.gray.opacity(0.3))
                    
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.1))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "clock.fill")
                                .foregroundStyle(.orange)
                                .symbolEffect(.pulse, value: reservationTime)
                        }
                        
                        DatePicker("Time", selection: $reservationTime, displayedComponents: .hourAndMinute)
                            .font(.body)
                    }
                }
                .padding(.vertical, 4)
                .opacity(animateFields ? 1.0 : 0.0)
                .offset(x: animateFields ? 0 : -20)
            } header: {
                Label("When", systemImage: "calendar.badge.clock")
                    .foregroundStyle(.green)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            } footer: {
                Text("Set the date and time for your activity")
                    .font(.caption)
            }
            
            // Additional Info
            Section {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.cyan.opacity(0.1))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "link")
                                .foregroundStyle(.cyan)
                                .symbolEffect(.bounce, value: website)
                        }
                        
                        TextField("Activity website", text: $website)
                            .font(.body)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }
                .padding(.vertical, 4)
                .opacity(animateFields ? 1.0 : 0.0)
                .offset(x: animateFields ? 0 : -20)
            } header: {
                Label("Website (Optional)", systemImage: "globe")
                    .foregroundStyle(.cyan)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            } footer: {
                Text("Add a website link for quick access to activity details")
                    .font(.caption)
            }
        }
    }
    
    private var restaurantFields: some View {
        Section {
            TextField("Restaurant Name", text: $name)
                .autocorrectionDisabled()
            TextField("Address", text: $location, axis: .vertical)
                .lineLimit(2...3)
            DatePicker("Reservation Time", selection: $reservationTime)
            TextField("Phone Number (Optional)", text: $phoneNumber)
                .keyboardType(.phonePad)
            TextField("Website (Optional)", text: $website)
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        } header: {
            Text("Restaurant Details")
        } footer: {
            Text("Keep all your dining reservations organized in one place")
                .font(.caption)
        }
    }
    
    private var canSave: Bool {
        // Allow saving with just type selected - all fields are optional
        // Users can add details later through editing
        return true
    }
    
    private func addTripItem() {
        let costValue = Double(cost) ?? 0
        
        // Use default name if empty
        let itemName = name.isEmpty ? "New \(selectedType.rawValue)" : name
        
        let item: TripItem
        
        switch selectedType {
        case .accommodation:
            item = TripItem.accommodation(
                name: itemName,
                address: address,
                checkIn: checkInTime,
                checkOut: checkOutTime,
                cost: costValue,
                confirmationNumber: confirmationNumber
            )
        case .flight:
            item = TripItem.flight(
                airline: airline,
                flightNumber: flightNumber,
                departure: departureAirport,
                arrival: arrivalAirport,
                departureTime: departureTime,
                arrivalTime: arrivalTime,
                cost: costValue,
                confirmationNumber: confirmationNumber
            )
            // Use default name for flights if both airline and flight number are empty
            if item.name.isEmpty {
                item.name = itemName
            }
        case .transportation:
            item = TripItem(
                type: .transportation,
                name: itemName,
                startDate: startDate,
                endDate: endDate,
                location: location,
                cost: costValue,
                confirmationNumber: confirmationNumber
            )
        case .activity:
            item = TripItem.activity(
                name: itemName,
                location: location,
                date: startDate,
                time: reservationTime,
                cost: costValue,
                notes: notes
            )
            item.website = website
            item.confirmationNumber = confirmationNumber
        case .restaurant:
            item = TripItem.restaurant(
                name: itemName,
                location: location,
                reservationTime: reservationTime,
                phoneNumber: phoneNumber,
                cost: costValue
            )
            item.website = website
            item.confirmationNumber = confirmationNumber
        }
        
        item.notes = notes
        item.isPaid = isPaid
        item.trip = trip
        
        modelContext.insert(item)
        trip.tripItems.append(item)
        
        // Explicitly save the context
        do {
            try modelContext.save()
            
            // Check if item has a cost and ask if user wants to add to expenses
            if costValue > 0 {
                savedItem = item
                showAddToExpensesPrompt = true
            } else {
                // No cost - dismiss normally
                if selectedType == .activity {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        showSuccessAnimation = true
                    }
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    dismiss()
                }
            }
        } catch {
            print("Error saving trip item: \(error)")
        }
    }
}

#Preview {
    let userID = UserManager.shared.currentUserID
    AddTripItemView(trip: Trip(name: "Tokyo Trip", creatorID: userID))
        .modelContainer(for: [Trip.self, TripItem.self])
}
