//
//  PaymentsView.swift
//  Travel Buddy
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI
import SwiftData

struct PaymentsView: View {
    @Environment(\.modelContext) private var modelContext
    var trip: Trip
    
    @State private var showingAddPayment = false
    
    var isCreator: Bool {
        trip.isCreator(userID: UserManager.shared.currentUserID)
    }
    
    var sortedPayments: [Payment] {
        trip.payments.sorted(by: { $0.date > $1.date })
    }
    
    var body: some View {
        listContent
            .sheet(isPresented: $showingAddPayment) {
                AddPaymentView(trip: trip)
            }
    }
    
    private var listContent: some View {
        ZStack {
            if sortedPayments.isEmpty {
                EmptyStateView(
                    icon: "dollarsign.circle.fill",
                    title: "No Payments Yet",
                    message: "Record payments between travel buddies to settle up expenses and keep track of who owes what.",
                    actionTitle: "Add Payment",
                    action: {
                        showingAddPayment = true
                    }
                )
            } else {
                List {
                    ForEach(sortedPayments) { payment in
                        PaymentRow(payment: payment, trip: trip)
                    }
                    .onDelete(perform: deletePaymentsIfAllowed)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showingAddPayment = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 56, height: 56)
                                .foregroundStyle(.blue)
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding()
                    }
                }
            }
        }
    }
    
    private func deletePaymentsIfAllowed(at offsets: IndexSet) {
        guard isCreator else { return }
        deletePayments(at: offsets)
    }
    
    private func deletePayments(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedPayments[index])
        }
    }
}

struct PaymentRow: View {
    let payment: Payment
    let trip: Trip
    
    var paidByBuddy: TravelBuddy? {
        trip.travelBuddies.first { $0.id == payment.fromBuddyID }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                
                if let buddy = paidByBuddy {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(buddy.name) paid")
                            .font(.headline)
                        
                        if let expense = payment.expense {
                            Text("for \(expense.name)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("Unknown")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(trip.currency.format(payment.amount))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
            }
            
            HStack {
                Text(payment.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if !payment.notes.isEmpty {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(payment.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let userID = UserManager.shared.currentUserID
    NavigationStack {
        PaymentsView(trip: Trip(name: "Test Trip", creatorID: userID))
    }
    .modelContainer(for: [Trip.self, Payment.self, TravelBuddy.self])
}
