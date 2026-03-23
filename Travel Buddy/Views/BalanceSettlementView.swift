//
//  BalanceSettlementView.swift
//  Split Voyage Group Travel
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI
import SwiftData

struct BalanceSettlementView: View {
    @Environment(\.modelContext) private var modelContext
    let trip: Trip
    
    @State private var animateCards = false
    @State private var pulseScale: CGFloat = 1.0
    
    var settlements: [Settlement] {
        calculateSettlements()
    }
    
    var totalUnsettled: Double {
        settlements.reduce(0) { $0 + $1.amount }
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
                    // Summary Card
                    summaryCard
                    
                    // Balance Overview
                    balanceOverviewSection
                    
                    // Settlement Suggestions
                    if !settlements.isEmpty {
                        settlementSuggestionsSection
                    } else {
                        allSettledCard
                    }
                    
                    // Individual Balances
                    individualBalancesSection
                }
                .padding()
            }
        }
        .navigationTitle("Balances & Settlements")
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateCards = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
        }
    }
    
    // MARK: - Summary Card
    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: settlements.isEmpty 
                                    ? [Color.green.opacity(0.2), Color.green.opacity(0.1)]
                                    : [Color.blue.opacity(0.2), Color.blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .scaleEffect(pulseScale)
                    
                    Image(systemName: settlements.isEmpty ? "checkmark.circle.fill" : "arrow.left.arrow.right.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(settlements.isEmpty ? .green : .blue)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(settlements.isEmpty ? "All Settled!" : "Pending Settlements")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(settlements.isEmpty ? "Everyone is squared up" : "\(settlements.count) payment\(settlements.count == 1 ? "" : "s") needed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            if !settlements.isEmpty {
                Divider()
                
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
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Total Expenses")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(trip.currency.format(trip.totalExpenses))
                            .font(.title3)
                            .fontWeight(.semibold)
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
    
    // MARK: - Balance Overview Section
    private var balanceOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.blue)
                Text("Balance Overview")
                    .font(.headline)
            }
            
            VStack(spacing: 12) {
                ForEach(trip.travelBuddies.sorted(by: { netBalanceForBuddy($0) > netBalanceForBuddy($1) })) { buddy in
                    balanceOverviewRow(for: buddy)
                }
            }
        }
    }
    
    private func balanceOverviewRow(for buddy: TravelBuddy) -> some View {
        let netBalance = netBalanceForBuddy(buddy)
        let owes = amountBuddyOwes(buddy)
        let owed = amountOwedToBuddy(buddy)
        
        return VStack(spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [buddyColor(buddy).opacity(0.2), buddyColor(buddy).opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Text(buddy.name.prefix(1).uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(buddyColor(buddy))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(buddy.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if abs(netBalance) < 0.01 {
                        Text("Settled up")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else if netBalance > 0 {
                        Text("Should receive \(trip.currency.format(netBalance))")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text("Owes \(trip.currency.format(abs(netBalance)))")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(trip.currency.format(abs(netBalance)))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            abs(netBalance) < 0.01 ? 
                                LinearGradient(colors: [.green, .green], startPoint: .leading, endPoint: .trailing) :
                            netBalance > 0 ? 
                                LinearGradient(colors: [.green, .green], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                        )
                    
                    if abs(netBalance) > 0.01 {
                        Image(systemName: netBalance > 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .font(.caption)
                            .foregroundStyle(netBalance > 0 ? .green : .orange)
                    }
                }
            }
            
            // Progress bars
            if owes > 0.01 || owed > 0.01 {
                HStack(spacing: 12) {
                    if owes > 0.01 {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Owes")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [.orange, .red],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * min(1.0, owes / max(owes, owed)), height: 6)
                                }
                            }
                            .frame(height: 6)
                            
                            Text(trip.currency.format(owes))
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                    
                    if owed > 0.01 {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Is Owed")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [.green, .green],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * min(1.0, owed / max(owes, owed)), height: 6)
                                }
                            }
                            .frame(height: 6)
                            
                            Text(trip.currency.format(owed))
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Settlement Suggestions Section
    private var settlementSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Settlement Suggestions")
                    .font(.headline)
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
    
    // MARK: - All Settled Card
    private var allSettledCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulseScale)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.green)
            }
            
            Text("All Settled Up!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Everyone has paid their share. Great job keeping track of expenses!")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
        )
    }
    
    // MARK: - Individual Balances Section
    private var individualBalancesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.blue)
                Text("Individual Balances")
                    .font(.headline)
            }
            
            VStack(spacing: 12) {
                ForEach(trip.travelBuddies.sorted(by: { $0.name < $1.name })) { buddy in
                    individualBalanceCard(for: buddy)
                }
            }
        }
    }
    
    private func individualBalanceCard(for buddy: TravelBuddy) -> some View {
        let totalOwed = amountBuddyOwes(buddy)
        let totalPaid = amountPaidByBuddy(buddy)
        let totalExpenses = trip.expenses.filter { $0.participantIDs.contains(buddy.id) }.reduce(0.0) { $0 + $1.amountForBuddy(buddy.id) }
        
        return VStack(spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [buddyColor(buddy).opacity(0.2), buddyColor(buddy).opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Text(buddy.name.prefix(1).uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(buddyColor(buddy))
                }
                
                Text(buddy.name)
                    .font(.headline)
                
                Spacer()
            }
            
            Divider()
            
            VStack(spacing: 8) {
                HStack {
                    Text("Total Expenses")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(trip.currency.format(totalExpenses))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Paid So Far")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(trip.currency.format(totalPaid))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
                
                HStack {
                    Text("Still Owes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(trip.currency.format(totalOwed))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(totalOwed > 0.01 ? .orange : .green)
                }
            }
            
            // Progress bar
            if totalExpenses > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: totalOwed < 0.01 ? [.green, .green] : [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(totalPaid / totalExpenses), height: 8)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("\(Int((totalPaid / totalExpenses) * 100))% paid")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Helper Functions
    private func calculateSettlements() -> [Settlement] {
        var balances: [UUID: Double] = [:]
        
        // Calculate net balance for each buddy
        for buddy in trip.travelBuddies {
            balances[buddy.id] = netBalanceForBuddy(buddy)
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
        // Amount that should be paid to this buddy by others
        var total = 0.0
        
        for expense in trip.expenses {
            if let paidByID = expense.paidByBuddyID, paidByID == buddy.id {
                // This buddy paid for the expense, calculate what others owe
                for participantID in expense.participantIDs where participantID != buddy.id {
                    let amountOwed = expense.amountForBuddy(participantID)
                    let amountPaid = expense.amountPaidByBuddy(participantID)
                    total += (amountOwed - amountPaid)
                }
            } else if expense.paidByBuddyID == nil && expense.participantIDs.contains(buddy.id) {
                // No one marked as payer yet - treat as if everyone should contribute equally
                // This buddy is owed their share from others who haven't paid
                let buddyShare = expense.amountForBuddy(buddy.id)
                let buddyPaid = expense.amountPaidByBuddy(buddy.id)
                
                // If this buddy has paid more than their share, they're owed the difference
                if buddyPaid > buddyShare {
                    total += (buddyPaid - buddyShare)
                }
            }
        }
        
        return total
    }
    
    private func amountBuddyOwes(_ buddy: TravelBuddy) -> Double {
        // Amount this buddy still owes for their share
        var total = 0.0
        
        for expense in trip.expenses where expense.participantIDs.contains(buddy.id) {
            if let paidByID = expense.paidByBuddyID, paidByID != buddy.id {
                // Someone else paid, calculate what this buddy owes
                let amountOwed = expense.amountForBuddy(buddy.id)
                let amountPaid = expense.amountPaidByBuddy(buddy.id)
                total += (amountOwed - amountPaid)
            } else if expense.paidByBuddyID == nil {
                // No one marked as payer - everyone owes their unpaid share
                let amountOwed = expense.amountForBuddy(buddy.id)
                let amountPaid = expense.amountPaidByBuddy(buddy.id)
                
                // This buddy owes whatever they haven't paid yet
                if amountPaid < amountOwed {
                    total += (amountOwed - amountPaid)
                }
            }
        }
        
        return total
    }
    
    private func amountPaidByBuddy(_ buddy: TravelBuddy) -> Double {
        trip.expenses
            .filter { $0.participantIDs.contains(buddy.id) }
            .reduce(0.0) { $0 + $1.amountPaidByBuddy(buddy.id) }
    }
    
    private func buddyColor(_ buddy: TravelBuddy) -> Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .teal, .indigo]
        let index = trip.travelBuddies.firstIndex(where: { $0.id == buddy.id }) ?? 0
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
    
    // Scenario: Expenses added but no payments recorded yet
    // Alice paid for dinner, Bob and Charlie haven't paid their shares
    let expense1 = Expense(name: "Dinner at Sushi Restaurant", totalAmount: 120.0, participantIDs: [buddy1.id, buddy2.id, buddy3.id], paidByBuddyID: buddy1.id)
    
    // Bob paid for hotel, Alice and Charlie haven't paid their shares
    let expense2 = Expense(name: "Hotel Tokyo Bay", totalAmount: 300.0, participantIDs: [buddy1.id, buddy2.id, buddy3.id], paidByBuddyID: buddy2.id)
    
    // Taxi - no payer marked yet, everyone owes their share
    let expense3 = Expense(name: "Taxi to Airport", totalAmount: 60.0, participantIDs: [buddy1.id, buddy2.id, buddy3.id])
    
    trip.expenses = [expense1, expense2, expense3]
    
    // Create splits for expenses with no payments recorded
    for expense in trip.expenses {
        for buddyID in expense.participantIDs {
            let split = ExpenseSplit(buddyID: buddyID, amount: expense.amountPerPerson(), amountPaid: 0, isPaidInFull: false)
            split.expense = expense
            expense.splits.append(split)
        }
    }
    
    return NavigationStack {
        BalanceSettlementView(trip: trip)
    }
    .modelContainer(for: [Trip.self, TravelBuddy.self, Expense.self, ExpenseSplit.self])
}
