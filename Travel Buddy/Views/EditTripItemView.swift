//
//  EditTripItemView.swift
//  Travel Buddy
//
//  Created by Shanique Beckford on 3/13/26.
//

import SwiftUI
import SwiftData

struct EditTripItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var item: TripItem
    let trip: Trip
    
    @State private var name: String
    @State private var notes: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var location: String
    @State private var cost: String
    @State private var isPaid: Bool
    @State private var confirmationNumber: String
    
    // Accommodation specific
    @State private var address: String
    @State private var checkInTime: Date
    @State private var checkOutTime: Date
    
    // Flight specific
    @State private var airline: String
    @State private var flightNumber: String
    @State private var departureAirport: String
    @State private var arrivalAirport: String
    @State private var departureTime: Date
    @State private var arrivalTime: Date
    
    // Activity/Restaurant specific
    @State private var reservationTime: Date
    @State private var phoneNumber: String
    @State private var website: String
    
    // Delete confirmation
    @State private var showDeleteConfirmation = false
    
    // Unsaved changes tracking
    @State private var showUnsavedChangesAlert = false
    @State private var hasUnsavedChanges = false
    
    // Add to expenses
    @State private var showAddToExpensesAlert = false
    @State private var expenseCreated = false
    
    init(item: TripItem, trip: Trip) {
        self.item = item
        self.trip = trip
        
        // Initialize state from item
        _name = State(initialValue: item.name)
        _notes = State(initialValue: item.notes)
        _startDate = State(initialValue: item.startDate)
        _endDate = State(initialValue: item.endDate ?? item.startDate)
        _location = State(initialValue: item.location)
        _cost = State(initialValue: item.cost > 0 ? String(format: "%.2f", item.cost) : "")
        _isPaid = State(initialValue: item.isPaid)
        _confirmationNumber = State(initialValue: item.confirmationNumber)
        
        // Accommodation
        _address = State(initialValue: item.address)
        _checkInTime = State(initialValue: item.checkInTime ?? Date())
        _checkOutTime = State(initialValue: item.checkOutTime ?? Date())
        
        // Flight
        _airline = State(initialValue: item.airline)
        _flightNumber = State(initialValue: item.flightNumber)
        _departureAirport = State(initialValue: item.departureAirport)
        _arrivalAirport = State(initialValue: item.arrivalAirport)
        _departureTime = State(initialValue: item.departureTime ?? Date())
        _arrivalTime = State(initialValue: item.arrivalTime ?? Date())
        
        // Activity/Restaurant
        _reservationTime = State(initialValue: item.reservationTime ?? Date())
        _phoneNumber = State(initialValue: item.phoneNumber)
        _website = State(initialValue: item.website)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Info banner
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Edit Details")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Update your itinerary item information")
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
                
                // Type indicator (non-editable)
                Section {
                    HStack {
                        Image(systemName: item.type.icon)
                            .foregroundStyle(.blue)
                        Text(item.type.rawValue)
                        Spacer()
                        Text("Type")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Item Type")
                }
                
                // Dynamic fields based on type
                switch item.type {
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
                
                // Common fields
                Section("Additional Information") {
                    TextField("Confirmation Number", text: $confirmationNumber)
                    
                    HStack {
                        Text("Cost")
                        Spacer()
                        TextField("0.00", text: $cost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Toggle("Paid", isOn: $isPaid)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                // Add to Expenses section (only if item has cost and not already an expense)
                if item.cost > 0 && !trip.travelBuddies.isEmpty {
                    Section {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showAddToExpensesAlert = true
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.green.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.green)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Add to Expenses")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    if expenseCreated {
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.caption2)
                                            Text("Already added")
                                                .font(.caption)
                                        }
                                        .foregroundStyle(.green)
                                    } else {
                                        Text("Track this as a shared expense with buddies")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                        .disabled(expenseCreated)
                    } footer: {
                        if expenseCreated {
                            Text("This item has been added to expenses")
                                .foregroundStyle(.green)
                        } else {
                            Text("Create an expense entry to split the cost of \(trip.currency.format(item.cost)) with your travel buddies")
                        }
                    }
                }
            }
            .navigationTitle("Edit \(item.type.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if checkForUnsavedChanges() {
                            showUnsavedChangesAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Button(role: .destructive) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showDeleteConfirmation = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash.fill")
                                .font(.body)
                            Text("Delete Itinerary Item")
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .alert("Delete Itinerary Item?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteItem()
                }
            } message: {
                Text("This will permanently delete \"\(item.name)\" from your itinerary. This action cannot be undone.")
            }
            .alert("Unsaved Changes", isPresented: $showUnsavedChangesAlert) {
                Button("Discard Changes", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) { }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .alert("Add to Expenses?", isPresented: $showAddToExpensesAlert) {
                Button("Add to Expenses") {
                    createExpenseFromItem()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Create an expense entry for \(item.name) (\(trip.currency.format(item.cost))) to track and split with your \(trip.travelBuddies.count) travel buddy(ies)?")
            }
            .onAppear {
                checkIfExpenseExists()
            }
        }
    }
    
    // MARK: - Field Views
    
    private var accommodationFields: some View {
        Group {
            Section("Basic Information") {
                TextField("Hotel/Property Name", text: $name)
                TextField("Address", text: $address)
                TextField("Location/City", text: $location)
            }
            
            Section("Check-in & Check-out") {
                DatePicker("Check-in", selection: $checkInTime)
                DatePicker("Check-out", selection: $checkOutTime)
            }
        }
    }
    
    private var flightFields: some View {
        Group {
            Section("Flight Information") {
                TextField("Airline", text: $airline)
                TextField("Flight Number", text: $flightNumber)
            }
            
            Section("Departure") {
                TextField("Airport Code", text: $departureAirport)
                DatePicker("Time", selection: $departureTime)
            }
            
            Section("Arrival") {
                TextField("Airport Code", text: $arrivalAirport)
                DatePicker("Time", selection: $arrivalTime)
            }
        }
    }
    
    private var transportationFields: some View {
        Group {
            Section("Transportation Details") {
                TextField("Name (e.g., Train, Car Rental)", text: $name)
                TextField("Location/Route", text: $location)
                DatePicker("Start Date", selection: $startDate)
                DatePicker("End Date", selection: $endDate)
            }
        }
    }
    
    private var activityFields: some View {
        Group {
            Section("Activity Details") {
                TextField("Activity Name", text: $name)
                TextField("Location", text: $location)
                DatePicker("Date", selection: $startDate, displayedComponents: .date)
                DatePicker("Time", selection: $reservationTime, displayedComponents: .hourAndMinute)
            }
            
            Section("Contact Information") {
                TextField("Website", text: $website)
                TextField("Phone Number", text: $phoneNumber)
            }
        }
    }
    
    private var restaurantFields: some View {
        Group {
            Section("Restaurant Details") {
                TextField("Restaurant Name", text: $name)
                TextField("Location", text: $location)
                DatePicker("Reservation Time", selection: $reservationTime)
            }
            
            Section("Contact Information") {
                TextField("Phone Number", text: $phoneNumber)
                TextField("Website", text: $website)
            }
        }
    }
    
    // MARK: - Create Expense from Item
    
    private func createExpenseFromItem() {
        // Create an expense from the trip item using current values
        let costValue = Double(cost) ?? item.cost
        
        guard costValue > 0 else { return }
        
        let expense = Expense(
            name: name,
            totalAmount: costValue,
            date: startDate,
            participantIDs: trip.travelBuddies.map { $0.id },
            splitType: .equal,
            paidByBuddyID: nil
        )
        
        expense.trip = trip
        expense.sourceItineraryItem = item // Link expense to itinerary item
        item.linkedExpense = expense // Link itinerary item to expense
        
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
            modelContext.insert(split)
        }
        
        modelContext.insert(expense)
        trip.expenses.append(expense)
        
        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            expenseCreated = true
        } catch {
            print("Error creating expense from itinerary item: \(error)")
        }
    }
    
    private func checkIfExpenseExists() {
        // Check if this item has a linked expense
        expenseCreated = item.linkedExpense != nil
    }
    
    // MARK: - Check for Unsaved Changes
    
    private func checkForUnsavedChanges() -> Bool {
        // Check common fields
        if name != item.name { return true }
        if notes != item.notes { return true }
        if location != item.location { return true }
        if confirmationNumber != item.confirmationNumber { return true }
        if isPaid != item.isPaid { return true }
        
        // Check cost
        let currentCost = Double(cost) ?? 0
        if abs(currentCost - item.cost) > 0.01 { return true }
        
        // Check dates
        if !Calendar.current.isDate(startDate, inSameDayAs: item.startDate) { return true }
        if let itemEndDate = item.endDate {
            if !Calendar.current.isDate(endDate, inSameDayAs: itemEndDate) { return true }
        }
        
        // Check type-specific fields
        switch item.type {
        case .accommodation:
            if address != item.address { return true }
            if let itemCheckIn = item.checkInTime, !Calendar.current.isDate(checkInTime, equalTo: itemCheckIn, toGranularity: .minute) { return true }
            if let itemCheckOut = item.checkOutTime, !Calendar.current.isDate(checkOutTime, equalTo: itemCheckOut, toGranularity: .minute) { return true }
            
        case .flight:
            if airline != item.airline { return true }
            if flightNumber != item.flightNumber { return true }
            if departureAirport != item.departureAirport { return true }
            if arrivalAirport != item.arrivalAirport { return true }
            if let itemDep = item.departureTime, !Calendar.current.isDate(departureTime, equalTo: itemDep, toGranularity: .minute) { return true }
            if let itemArr = item.arrivalTime, !Calendar.current.isDate(arrivalTime, equalTo: itemArr, toGranularity: .minute) { return true }
            
        case .activity, .restaurant:
            if phoneNumber != item.phoneNumber { return true }
            if website != item.website { return true }
            if let itemResTime = item.reservationTime, !Calendar.current.isDate(reservationTime, equalTo: itemResTime, toGranularity: .minute) { return true }
            
        case .transportation:
            break
        }
        
        return false
    }
    
    // MARK: - Delete Item
    
    private func deleteItem() {
        // Remove from trip
        if let index = trip.tripItems.firstIndex(where: { $0.id == item.id }) {
            trip.tripItems.remove(at: index)
        }
        
        // Delete from context
        modelContext.delete(item)
        
        // Save context
        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            print("Error deleting item: \(error)")
        }
    }
    
    // MARK: - Save Changes
    
    private func saveChanges() {
        // Update common fields
        item.name = name
        item.notes = notes
        item.startDate = startDate
        item.endDate = endDate
        item.location = location
        item.cost = Double(cost) ?? 0
        item.isPaid = isPaid
        item.confirmationNumber = confirmationNumber
        
        // Update type-specific fields
        switch item.type {
        case .accommodation:
            item.address = address
            item.checkInTime = checkInTime
            item.checkOutTime = checkOutTime
            
        case .flight:
            item.airline = airline
            item.flightNumber = flightNumber
            item.departureAirport = departureAirport
            item.arrivalAirport = arrivalAirport
            item.departureTime = departureTime
            item.arrivalTime = arrivalTime
            
        case .transportation:
            // Already handled by common fields
            break
            
        case .activity, .restaurant:
            item.reservationTime = reservationTime
            item.phoneNumber = phoneNumber
            item.website = website
        }
        
        // Save context
        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            print("Error saving changes: \(error)")
        }
    }
}
