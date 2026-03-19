//
//  SummaryView.swift
//  Travel Buddy
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI
import Charts

struct Settlement: Identifiable {
    let id = UUID()
    let from: TravelBuddy
    let to: TravelBuddy
    let amount: Double
}

struct SummaryView: View {
    var trip: Trip
    @State private var animateCards = false
    @State private var animateChart = false
    @State private var pulseScale: CGFloat = 1.0
    
    var settlements: [Settlement] {
        calculateSettlements()
    }
    
    var totalUnsettled: Double {
        // Calculate total amount that needs to be settled
        // This is the sum of all negative balances (people who owe)
        trip.travelBuddies.reduce(0.0) { total, buddy in
            let balance = trip.balanceForBuddy(buddy)
            // Only sum negative balances (people who owe)
            return total + (balance < 0 ? abs(balance) : 0)
        }
    }
    
    var isActuallySettled: Bool {
        // Only show as settled if there are no expenses OR
        // if all users have a zero balance (within rounding tolerance)
        guard !trip.expenses.isEmpty else { return true }
        
        // Check if all buddies have a balance of zero (or very close to zero)
        let allBalancesZero = trip.travelBuddies.allSatisfy { buddy in
            let balance = trip.balanceForBuddy(buddy)
            return abs(balance) < 0.01 // Within 1 cent tolerance for rounding
        }
        
        return allBalancesZero
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Total Expenses Card - Simplified
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Expenses")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(trip.currency.format(trip.totalExpenses))
                                .font(.system(size: 36, weight: .bold))
                        }
                        Spacer()
                    }
                    
                    if !isActuallySettled {
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total to Settle")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(trip.currency.format(totalUnsettled))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.blue)
                            }
                            Spacer()
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                .scaleEffect(animateCards ? 1.0 : 0.95)
                .opacity(animateCards ? 1.0 : 0)
                
                // Settlement Suggestions
                if !settlements.isEmpty {
                    settlementSuggestionsSection
                }
                
                // Individual Balances
                VStack(alignment: .leading, spacing: 16) {
                    Text("Individual Balances")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if trip.travelBuddies.isEmpty {
                        HStack {
                            Image(systemName: "person.2.slash")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("No travel buddies added yet")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                    } else {
                        ForEach(Array(trip.travelBuddies.sorted(by: { trip.balanceForBuddy($0) > trip.balanceForBuddy($1) }).enumerated()), id: \.element.id) { index, buddy in
                            BuddyBalanceCard(
                                buddy: buddy,
                                trip: trip,
                                expenseCount: expenseCountForBuddy(buddy),
                                index: index
                            )
                            .offset(x: animateCards ? 0 : -30)
                            .opacity(animateCards ? 1.0 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: animateCards)
                        }
                    }
                }
                
                // Expense Breakdown Chart with Enhanced Design
                if !trip.expenses.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Expense Breakdown")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Image(systemName: "chart.bar.doc.horizontal")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        
                        Chart {
                            ForEach(trip.expenses.sorted(by: { $0.totalAmount > $1.totalAmount }).prefix(5)) { expense in
                                BarMark(
                                    x: .value("Amount", expense.totalAmount),
                                    y: .value("Expense", expense.name)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple, .pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(6)
                                .annotation(position: .trailing) {
                                    Text(trip.currency.symbol + String(format: "%.0f", expense.totalAmount))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                        .frame(height: 220)
                        .chartXAxis {
                            AxisMarks(position: .bottom) { _ in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                                    .foregroundStyle(.secondary.opacity(0.3))
                                AxisValueLabel()
                                    .font(.caption2)
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                                    .font(.caption)
                            }
                        }
                        .opacity(animateChart ? 1.0 : 0)
                        .scaleEffect(animateChart ? 1.0 : 0.8, anchor: .leading)
                        
                        if trip.expenses.count > 5 {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .font(.caption)
                                Text("Showing top 5 expenses")
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.blue.opacity(0.2), lineWidth: 1)
                    )
                }
                
                // Recent Expenses with Enhanced Design
                if !trip.expenses.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Recent Expenses")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Image(systemName: "clock.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        
                        ForEach(Array(trip.expenses.sorted(by: { $0.date > $1.date }).prefix(3).enumerated()), id: \.element.id) { index, expense in
                            HStack(spacing: 16) {
                                // Receipt Icon with Gradient Background
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue.opacity(0.15), .purple.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 50, height: 50)
                                    Image(systemName: "receipt.fill")
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(expense.name)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "calendar")
                                            .font(.caption2)
                                        Text(expense.date, style: .date)
                                            .font(.caption)
                                    }
                                    .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text(trip.currency.format(expense.totalAmount))
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "person.2.fill")
                                            .font(.caption2)
                                        Text("\(trip.currency.format(expense.amountPerPerson())) each")
                                            .font(.caption)
                                    }
                                    .foregroundStyle(.secondary)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            )
                            .offset(y: animateCards ? 0 : 20)
                            .opacity(animateCards ? 1.0 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.15 + 0.5), value: animateCards)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Summary")
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateCards = true
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                animateChart = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
        }
    }
    
    private func expenseCountForBuddy(_ buddy: TravelBuddy) -> Int {
        trip.expenses.filter { $0.participantIDs.contains(buddy.id) }.count
    }
    
    // MARK: - Settlement Status Card
    private var settlementStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isActuallySettled 
                                    ? [Color.green.opacity(0.2), Color.green.opacity(0.1)]
                                    : [Color.blue.opacity(0.2), Color.blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .scaleEffect(pulseScale)
                    
                    Image(systemName: isActuallySettled ? "checkmark.circle.fill" : "arrow.left.arrow.right.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(isActuallySettled ? .green : .blue)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(isActuallySettled ? "All Settled!" : "Pending Settlements")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(isActuallySettled ? "Everyone is squared up" : "\(settlements.count) payment\(settlements.count == 1 ? "" : "s") needed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            if !isActuallySettled {
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total to Settle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(trip.currency.format(totalUnsettled))
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
                        
                        Spacer()
                    }
                    
                    // Show outstanding payments breakdown
                    if !settlements.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Outstanding Payments:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            ForEach(settlements.prefix(3)) { settlement in
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                    
                                    Text("\(settlement.from.name) → \(settlement.to.name)")
                                        .font(.caption)
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                    
                                    Text(trip.currency.format(settlement.amount))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.blue)
                                }
                            }
                            
                            if settlements.count > 3 {
                                Text("+ \(settlements.count - 3) more payment\(settlements.count - 3 == 1 ? "" : "s")")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.05))
                        )
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
        .scaleEffect(animateCards ? 1.0 : 0.95)
        .opacity(animateCards ? 1.0 : 0)
    }
    
    // MARK: - Settlement Suggestions Section
    private var settlementSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Settlement Suggestions")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text("Simplify payments with these suggested transactions")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                ForEach(Array(settlements.enumerated()), id: \.element.id) { index, settlement in
                    settlementCard(settlement: settlement, index: index)
                }
            }
        }
    }
    
    private func settlementCard(settlement: Settlement, index: Int) -> some View {
        HStack(spacing: 16) {
            // From buddy
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.2), Color.orange.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Text(settlement.from.name.prefix(1).uppercased())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                }
                
                Text(settlement.from.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
            
            // Arrow and amount
            VStack(spacing: 4) {
                Image(systemName: "arrow.right")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text(trip.currency.format(settlement.amount))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            // To buddy
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Text(settlement.to.name.prefix(1).uppercased())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
                
                Text(settlement.to.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
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
        .offset(y: animateCards ? 0 : 20)
        .opacity(animateCards ? 1.0 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.15), value: animateCards)
    }
    
    // MARK: - Helper Functions
    private func calculateSettlements() -> [Settlement] {
        var balances: [UUID: Double] = [:]
        
        // Calculate balance for each buddy
        // Positive balance = person is OWED money (creditor)
        // Negative balance = person OWES money (debtor)
        for buddy in trip.travelBuddies {
            balances[buddy.id] = trip.balanceForBuddy(buddy)
        }
        
        var settlements: [Settlement] = []
        var creditors = balances.filter { $0.value > 0.01 }.sorted { $0.value > $1.value }
        var debtors = balances.filter { $0.value < -0.01 }.sorted { $0.value < $1.value }
        
        while !creditors.isEmpty && !debtors.isEmpty {
            let creditor = creditors.removeFirst()
            let debtor = debtors.removeFirst()
            
            guard let creditorBuddy = trip.travelBuddies.first(where: { $0.id == creditor.key }),
                  let debtorBuddy = trip.travelBuddies.first(where: { $0.id == debtor.key }) else {
                continue
            }
            
            let amount = min(creditor.value, abs(debtor.value))
            
            settlements.append(Settlement(from: debtorBuddy, to: creditorBuddy, amount: amount))
            
            let remainingCredit = creditor.value - amount
            let remainingDebt = debtor.value + amount
            
            if remainingCredit > 0.01 {
                creditors.insert((key: creditor.key, value: remainingCredit), at: 0)
            }
            
            if remainingDebt < -0.01 {
                debtors.insert((key: debtor.key, value: remainingDebt), at: 0)
            }
        }
        
        return settlements
    }
    
    private func netBalanceForBuddy(_ buddy: TravelBuddy) -> Double {
        let amountOwed = amountOwedToBuddy(buddy)
        let amountOwes = amountBuddyOwes(buddy)
        return amountOwed - amountOwes
    }
    
    private func amountOwedToBuddy(_ buddy: TravelBuddy) -> Double {
        var total = 0.0
        
        for expense in trip.expenses {
            if let paidByID = expense.paidByBuddyID, paidByID == buddy.id {
                for participantID in expense.participantIDs where participantID != buddy.id {
                    let amountOwed = expense.amountForBuddy(participantID)
                    let amountPaid = expense.amountPaidByBuddy(participantID)
                    total += (amountOwed - amountPaid)
                }
            } else if expense.paidByBuddyID == nil && expense.participantIDs.contains(buddy.id) {
                let buddyShare = expense.amountForBuddy(buddy.id)
                let buddyPaid = expense.amountPaidByBuddy(buddy.id)
                
                if buddyPaid > buddyShare {
                    total += (buddyPaid - buddyShare)
                }
            }
        }
        
        return total
    }
    
    private func amountBuddyOwes(_ buddy: TravelBuddy) -> Double {
        var total = 0.0
        
        for expense in trip.expenses where expense.participantIDs.contains(buddy.id) {
            if let paidByID = expense.paidByBuddyID, paidByID != buddy.id {
                let amountOwed = expense.amountForBuddy(buddy.id)
                let amountPaid = expense.amountPaidByBuddy(buddy.id)
                total += (amountOwed - amountPaid)
            } else if expense.paidByBuddyID == nil {
                let amountOwed = expense.amountForBuddy(buddy.id)
                let amountPaid = expense.amountPaidByBuddy(buddy.id)
                
                if amountPaid < amountOwed {
                    total += (amountOwed - amountPaid)
                }
            }
        }
        
        return total
    }
}

// MARK: - Supporting Views

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
            }
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
    }
}

struct BuddyBalanceCard: View {
    let buddy: TravelBuddy
    let trip: Trip
    let expenseCount: Int
    let index: Int
    
    private var balance: Double {
        trip.balanceForBuddy(buddy)
    }
    
    private var balanceLabel: String {
        if abs(balance) < 0.01 {
            return "Settled"
        } else if balance > 0 {
            return "is owed"
        } else {
            return "owes"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar Circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [avatarColor.opacity(0.3), avatarColor.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                Text(buddy.name.prefix(1).uppercased())
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(avatarColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(buddy.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(balanceLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(trip.currency.format(abs(balance)))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(abs(balance) < 0.01 ? .green : .primary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var avatarColor: Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .teal]
        return colors[index % colors.count]
    }
}

#Preview {
    let userID = UserManager.shared.currentUserID
    let trip = Trip(name: "Tokyo Adventure", creatorID: userID)
    let buddy1 = TravelBuddy(name: "Alice")
    let buddy2 = TravelBuddy(name: "Bob")
    let buddy3 = TravelBuddy(name: "Charlie")
    trip.travelBuddies = [buddy1, buddy2, buddy3]
    
    let expense1 = Expense(name: "Dinner at Sushi Restaurant", totalAmount: 120.50, participantIDs: [buddy1.id, buddy2.id, buddy3.id])
    let expense2 = Expense(name: "Hotel Tokyo Stay", totalAmount: 450.00, participantIDs: [buddy1.id, buddy2.id, buddy3.id])
    let expense3 = Expense(name: "Train Tickets", totalAmount: 85.00, participantIDs: [buddy1.id, buddy2.id])
    let expense4 = Expense(name: "Museum Entry", totalAmount: 30.00, participantIDs: [buddy1.id, buddy3.id])
    let expense5 = Expense(name: "Coffee & Snacks", totalAmount: 25.00, participantIDs: [buddy1.id, buddy2.id, buddy3.id])
    trip.expenses = [expense1, expense2, expense3, expense4, expense5]
    
    return NavigationStack {
        SummaryView(trip: trip)
    }
}
