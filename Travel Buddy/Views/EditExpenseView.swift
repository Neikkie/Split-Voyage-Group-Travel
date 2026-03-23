//
//  EditExpenseView.swift
//  Split Voyage Group Travel
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI
import SwiftData

struct EditExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    
    var expense: Expense
    var trip: Trip
    
    @State private var expenseName: String
    @State private var amount: String
    @State private var date: Date
    @State private var selectedBuddyIDs: Set<UUID>
    @State private var showingDeleteAlert = false
    
    init(expense: Expense, trip: Trip) {
        self.expense = expense
        self.trip = trip
        _expenseName = State(initialValue: expense.name)
        _amount = State(initialValue: String(format: "%.2f", expense.totalAmount))
        _date = State(initialValue: expense.date)
        _selectedBuddyIDs = State(initialValue: Set(expense.participantIDs))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Expense Details") {
                    TextField("Name", text: $expenseName)
                    
                    HStack {
                        Text("$")
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                if let imageData = expense.receiptImageData,
                   let uiImage = UIImage(data: imageData) {
                    Section("Receipt") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 150)
                            .cornerRadius(8)
                    }
                }
                
                Section {
                    Button(selectedBuddyIDs.isEmpty ? "Select All" : "Deselect All") {
                        if selectedBuddyIDs.isEmpty {
                            selectedBuddyIDs = Set(trip.travelBuddies.map { $0.id })
                        } else {
                            // Keep current user selected when deselecting all
                            let currentUserIDs = trip.travelBuddies.filter { $0.isCurrentUser }.map { $0.id }
                            selectedBuddyIDs = Set(currentUserIDs)
                        }
                    }
                    
                    ForEach(trip.travelBuddies) { buddy in
                        Toggle(isOn: Binding(
                            get: { selectedBuddyIDs.contains(buddy.id) },
                            set: { isSelected in
                                // Prevent deselecting the current user
                                if buddy.isCurrentUser && !isSelected {
                                    return
                                }
                                if isSelected {
                                    selectedBuddyIDs.insert(buddy.id)
                                } else {
                                    selectedBuddyIDs.remove(buddy.id)
                                }
                            }
                        )) {
                            HStack {
                                Text(buddy.name)
                                if buddy.isCurrentUser {
                                    Text("(You)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .disabled(buddy.isCurrentUser)
                    }
                    
                    if !selectedBuddyIDs.isEmpty, let amountValue = Double(amount) {
                        HStack {
                            Text("Amount per person:")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("$\(amountValue / Double(selectedBuddyIDs.count), specifier: "%.2f")")
                                .foregroundStyle(.blue)
                                .font(.headline)
                        }
                    }
                } header: {
                    Text("Split Between")
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private var canSave: Bool {
        !expenseName.isEmpty && Double(amount) != nil && Double(amount)! > 0 && !selectedBuddyIDs.isEmpty
    }
    
    private func saveChanges() {
        guard let amountValue = Double(amount) else { return }
        
        expense.name = expenseName
        expense.totalAmount = amountValue
        expense.date = date
        expense.participantIDs = Array(selectedBuddyIDs)
        
        dismiss()
    }
}

#Preview {
    let userID = UserManager.shared.currentUserID
    let trip = Trip(name: "Test Trip", creatorID: userID)
    let buddy1 = TravelBuddy(name: "Alice")
    let buddy2 = TravelBuddy(name: "Bob")
    trip.travelBuddies = [buddy1, buddy2]
    
    let expense = Expense(
        name: "Dinner",
        totalAmount: 120.50,
        participantIDs: [buddy1.id, buddy2.id]
    )
    
    return EditExpenseView(expense: expense, trip: trip)
        .modelContainer(for: [Trip.self, TravelBuddy.self, Expense.self])
}
