//
//  ExpenseDetailView.swift
//  Split Voyage Group Travel
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI
import SwiftData

struct ExpenseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var expense: Expense
    let trip: Trip
    
    @State private var showingEditSheet = false
    @State private var selectedBuddyForPayment: TravelBuddy?
    @State private var animateProgress = false
    @State private var pulseScale: CGFloat = 1.0
    
    private var isCreator: Bool {
        trip.isCreator(userID: UserManager.shared.currentUserID)
    }
    
    var participatingBuddies: [TravelBuddy] {
        trip.travelBuddies.filter { expense.participantIDs.contains($0.id) }
    }
    
    var paidByBuddy: TravelBuddy? {
        guard let paidByID = expense.paidByBuddyID else { return nil }
        return trip.travelBuddies.first { $0.id == paidByID }
    }
    
    var body: some View {
        ZStack {
            // Subtle gradient background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.03),
                    Color.purple.opacity(0.02),
                    Color(.systemGroupedBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Receipt Image with enhanced styling
                    if let imageData = expense.receiptImageData,
                       let uiImage = UIImage(data: imageData) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Receipt")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Payment Status Card
                    paymentStatusCard
                    
                    // Expense Summary Card
                    expenseSummaryCard
                    
                    // Participants Payment List (Combined)
                    participantsPaymentSection
                }
                .padding(.vertical)
            }
        }
        .navigationTitle(expense.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if isCreator {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showingEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil.circle.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditExpenseView(expense: expense, trip: trip)
        }
        .sheet(item: $selectedBuddyForPayment) { buddy in
            AddPaymentView(trip: trip, preselectedBuddy: buddy, preselectedExpense: expense, suggestedAmount: expense.remainingAmountForBuddy(buddy.id))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
        }
    }
    
    // MARK: - Payment Status Card
    private var paymentStatusCard: some View {
        VStack(spacing: 16) {
            // Status Header
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: expense.isFullyPaid 
                                    ? [Color.green.opacity(0.2), Color.green.opacity(0.1)]
                                    : [Color.orange.opacity(0.2), Color.orange.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .scaleEffect(pulseScale)
                    
                    Image(systemName: expense.isFullyPaid ? "checkmark.circle.fill" : "clock.fill")
                        .font(.title2)
                        .foregroundStyle(expense.isFullyPaid ? .green : .orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.isFullyPaid ? "Fully Paid" : "Pending Payment")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(expense.isFullyPaid ? "All settled up!" : "Awaiting payments")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Payment Progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int((expense.totalAmountPaid / expense.totalAmount) * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * (expense.totalAmountPaid / expense.totalAmount), height: 12)
                            .animation(.spring(), value: expense.totalAmountPaid)
                    }
                }
                .frame(height: 12)
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Paid")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(trip.currency.format(expense.totalAmountPaid))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Remaining")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(trip.currency.format(expense.totalAmountRemaining))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Expense Summary Card
    private var expenseSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(.blue)
                Text("Expense Details")
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            // Total Amount
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(.green)
                Text("Total Amount")
                    .font(.subheadline)
                Spacer()
                Text(trip.currency.format(expense.totalAmount))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            // Date
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.orange)
                Text("Date")
                    .font(.subheadline)
                Spacer()
                Text(expense.date, style: .date)
                    .foregroundStyle(.secondary)
            }
            
            // Who Paid Initially
            if let paidBy = paidByBuddy {
                HStack {
                    Image(systemName: "person.fill.checkmark")
                        .foregroundStyle(.purple)
                    Text("Paid By")
                        .font(.subheadline)
                    Spacer()
                    Text(paidBy.name)
                        .fontWeight(.semibold)
                        .foregroundStyle(.purple)
                }
            }
            
            // Split Method
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(.pink)
                Text("Split Method")
                    .font(.subheadline)
                Spacer()
                Text(expense.splitType.rawValue)
                    .foregroundStyle(.secondary)
            }
            
            // Number of People
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.blue)
                Text("Split Between")
                    .font(.subheadline)
                Spacer()
                Text("\(participatingBuddies.count) people")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal)
    }
    

    // MARK: - Participants Payment Section
    private var participantsPaymentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.blue)
                Text("Payment Status")
                    .font(.headline)
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(participatingBuddies) { buddy in
                    participantPaymentCard(for: buddy)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func participantPaymentCard(for buddy: TravelBuddy) -> some View {
        let owes = expense.amountForBuddy(buddy.id)
        let paid = expense.amountPaidByBuddy(buddy.id)
        let remaining = expense.remainingAmountForBuddy(buddy.id)
        let isPaidInFull = expense.isBuddyPaidInFull(buddy.id)
        
        return VStack(spacing: 12) {
            HStack {
                // Avatar
                ZStack {
                    Circle()
                        .fill(isPaidInFull ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: isPaidInFull ? "checkmark.circle.fill" : "person.fill")
                        .foregroundStyle(isPaidInFull ? .green : .blue)
                }
                
                // Name and status
                VStack(alignment: .leading, spacing: 2) {
                    Text(buddy.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(isPaidInFull ? "Paid" : trip.currency.format(remaining) + " remaining")
                        .font(.caption)
                        .foregroundStyle(isPaidInFull ? .green : .orange)
                }
                
                Spacer()
                
                // Amount owed
                Text(trip.currency.format(owes))
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isPaidInFull ? Color.green : Color.blue)
                        .frame(width: owes > 0 ? geometry.size.width * CGFloat(paid / owes) : 0, height: 6)
                        .animation(.spring(), value: paid)
                }
            }
            .frame(height: 6)
            
            // Record payment button
            if !isPaidInFull {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    selectedBuddyForPayment = buddy
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Record Payment")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
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
    
    return NavigationStack {
        ExpenseDetailView(expense: expense, trip: trip)
    }
}
