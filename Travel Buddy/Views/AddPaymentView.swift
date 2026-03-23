//
//  AddPaymentView.swift
//  Split Voyage Group Travel
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI
import SwiftData

struct AddPaymentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var trip: Trip
    var preselectedBuddy: TravelBuddy? = nil
    var preselectedExpense: Expense? = nil
    var suggestedAmount: Double? = nil
    
    @State private var amount = ""
    @State private var fromBuddyID: UUID?
    @State private var notes = ""
    @State private var date = Date()
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var selectedExpenseID: UUID?
    @State private var linkToExpense = true
    @State private var showingOverpaymentWarning = false
    @State private var overpaymentAmount: Double = 0
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Payment Details") {
                    HStack {
                        Text(trip.currency.symbol)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Who Paid") {
                    if trip.travelBuddies.isEmpty {
                        Text("Add group members first")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Person", selection: $fromBuddyID) {
                            Text("Select person").tag(nil as UUID?)
                            ForEach(trip.travelBuddies) { buddy in
                                Text(buddy.name).tag(buddy.id as UUID?)
                            }
                        }
                    }
                }
                
                Section {
                    if trip.expenses.isEmpty {
                        Text("No expenses available. Please create an expense first.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Expense", selection: $selectedExpenseID) {
                            Text("Select expense").tag(nil as UUID?)
                            ForEach(trip.expenses.filter { expense in
                                // Only show expenses where fromBuddy is a participant
                                guard let from = fromBuddyID else { return true }
                                return expense.participantIDs.contains(from)
                            }) { expense in
                                HStack {
                                    Text(expense.name)
                                    Spacer()
                                    Text(trip.currency.format(expense.totalAmount))
                                        .foregroundStyle(.secondary)
                                }
                                .tag(expense.id as UUID?)
                            }
                        }
                        
                        if let expenseID = selectedExpenseID,
                           let expense = trip.expenses.first(where: { $0.id == expenseID }),
                           let from = fromBuddyID {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Expense Details")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                HStack {
                                    Text("Amount Owed:")
                                    Spacer()
                                    Text(trip.currency.format(expense.amountForBuddy(from)))
                                        .fontWeight(.semibold)
                                }
                                .font(.subheadline)
                                
                                HStack {
                                    Text("Already Paid:")
                                    Spacer()
                                    Text(trip.currency.format(expense.amountPaidByBuddy(from)))
                                        .foregroundStyle(.green)
                                }
                                .font(.subheadline)
                                
                                HStack {
                                    Text("Remaining:")
                                    Spacer()
                                    Text(trip.currency.format(expense.remainingAmountForBuddy(from)))
                                        .foregroundStyle(.orange)
                                        .fontWeight(.bold)
                                }
                                .font(.subheadline)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Select Expense")
                } footer: {
                    Text("This payment will reduce the outstanding balance for the selected expense")
                }
                
                Section("Notes (Optional)") {
                    TextField("e.g., Dinner settlement", text: $notes)
                }
                
                if let from = fromBuddyID,
                   let fromBuddy = trip.travelBuddies.first(where: { $0.id == from }),
                   let amountValue = Double(amount) {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Summary")
                                .font(.headline)
                            if let expenseID = selectedExpenseID,
                               let expense = trip.expenses.first(where: { $0.id == expenseID }) {
                                Text("\(fromBuddy.name) pays \(trip.currency.format(amountValue)) for \(expense.name)")
                                    .foregroundStyle(.secondary)
                                
                                // Check for overpayment
                                let remaining = expense.remainingAmountForBuddy(from)
                                if amountValue > remaining {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.orange)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Overpayment Warning")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.orange)
                                            Text("This exceeds the remaining balance of \(trip.currency.format(remaining)) by \(trip.currency.format(amountValue - remaining))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.orange.opacity(0.1))
                                    )
                                }
                            } else {
                                Text("\(fromBuddy.name) pays \(trip.currency.format(amountValue))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Record Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addPayment()
                    }
                    .disabled(!canSave)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Overpayment Detected", isPresented: $showingOverpaymentWarning) {
                Button("Cancel", role: .cancel) {}
                Button("Continue Anyway") {
                    guard let amountValue = Double(amount),
                          let from = fromBuddyID,
                          let expenseID = selectedExpenseID,
                          let expense = trip.expenses.first(where: { $0.id == expenseID }) else {
                        return
                    }
                    savePayment(amountValue: amountValue, from: from, expense: expense)
                }
            } message: {
                if let from = fromBuddyID,
                   let fromBuddy = trip.travelBuddies.first(where: { $0.id == from }),
                   let expenseID = selectedExpenseID,
                   let expense = trip.expenses.first(where: { $0.id == expenseID }) {
                    Text("\(fromBuddy.name) only owes \(trip.currency.format(expense.remainingAmountForBuddy(from))) for this expense. You're recording \(trip.currency.format(overpaymentAmount)) more than required. Do you want to continue?")
                }
            }
            .onAppear {
                // Always link to expense in this simplified payment flow
                linkToExpense = true
                
                // Set preselected values if provided
                if let buddy = preselectedBuddy {
                    fromBuddyID = buddy.id
                }
                if let expense = preselectedExpense {
                    selectedExpenseID = expense.id
                }
                if let suggested = suggestedAmount, suggested > 0 {
                    amount = String(format: "%.2f", suggested)
                }
            }
        }
    }
    
    private var canSave: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        guard fromBuddyID != nil else { return false }
        // Must link to an expense when using this simplified payment flow
        return linkToExpense && selectedExpenseID != nil
    }
    
    private func addPayment() {
        guard let amountValue = Double(amount),
              let from = fromBuddyID else {
            errorMessage = "Please fill in all required fields"
            showingError = true
            return
        }
        
        guard linkToExpense, let expenseID = selectedExpenseID,
              let expense = trip.expenses.first(where: { $0.id == expenseID }) else {
            errorMessage = "Please select an expense to record this payment against"
            showingError = true
            return
        }
        
        // Check for overpayment and show confirmation
        let remaining = expense.remainingAmountForBuddy(from)
        if amountValue > remaining {
            overpaymentAmount = amountValue - remaining
            showingOverpaymentWarning = true
            return
        }
        
        // Proceed with saving the payment
        savePayment(amountValue: amountValue, from: from, expense: expense)
    }
    
    private func savePayment(amountValue: Double, from: UUID, expense: Expense) {
        // Create payment record - using fromBuddyID for both from and to since it's just tracking who paid
        let newPayment = Payment(
            amount: amountValue,
            fromBuddyID: from,
            toBuddyID: from, // Same as from since we're just tracking who paid, not who they paid to
            notes: notes.isEmpty ? "Payment for \(expense.name)" : notes,
            date: date
        )
        
        newPayment.trip = trip
        newPayment.expense = expense
        modelContext.insert(newPayment)
        trip.payments.append(newPayment)
        
        // Update the expense split for this buddy
        if let split = expense.splits.first(where: { $0.buddyID == from }) {
            // Add the payment amount to the amount paid
            split.amountPaid += amountValue
            
            // Check if now paid in full
            if split.amountPaid >= split.amount {
                split.isPaidInFull = true
            }
        } else {
            // Create a new split if one doesn't exist
            let buddyAmount = expense.amountForBuddy(from)
            let split = ExpenseSplit(
                buddyID: from,
                amount: buddyAmount,
                amountPaid: min(amountValue, buddyAmount),
                isPaidInFull: amountValue >= buddyAmount
            )
            split.expense = expense
            expense.splits.append(split)
        }
        
        // Save context to ensure changes are persisted
        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            print("Error saving payment: \(error)")
        }
        
        dismiss()
    }
}

#Preview {
    let userID = UserManager.shared.currentUserID
    let trip = Trip(name: "Test Trip", creatorID: userID)
    trip.travelBuddies = [
        TravelBuddy(name: "Alice"),
        TravelBuddy(name: "Bob")
    ]
    
    return AddPaymentView(trip: trip)
        .modelContainer(for: [Trip.self, TravelBuddy.self, Payment.self])
}
