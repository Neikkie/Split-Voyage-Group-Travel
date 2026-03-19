//
//  ExpensesListView.swift
//  Travel Buddy
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI
import SwiftData

struct ExpensesListView: View {
    @Environment(\.modelContext) private var modelContext
    var trip: Trip
    @Binding var showingAddExpense: Bool
    
    @State private var selectedSegment = 0
    @State private var showingAddBuddy = false
    @State private var editingBuddy: TravelBuddy?
    @State private var animateHeader = false
    @State private var animateCards = false
    @State private var selectedExpense: Expense?
    
    var isCreator: Bool {
        trip.isCreator(userID: UserManager.shared.currentUserID)
    }
    
    var canEdit: Bool {
        trip.canEdit(userID: UserManager.shared.currentUserID)
    }
    
    var canDelete: Bool {
        trip.canDelete(userID: UserManager.shared.currentUserID)
    }
    
    var sortedExpenses: [Expense] {
        trip.expenses.sorted(by: { $0.date > $1.date })
    }
    
    var totalSpent: Double {
        trip.expenses.reduce(0) { $0 + $1.totalAmount }
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.03),
                    Color.purple.opacity(0.02),
                    Color.pink.opacity(0.01)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Permission Banner (for non-creators)
                if !isCreator {
                    PermissionBanner(trip: trip)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                // Custom Segmented Control with animations
                CustomSegmentedControl(
                    selection: $selectedSegment,
                    segments: [
                        (title: "Expenses", icon: "receipt.fill"),
                        (title: "Buddies", icon: "person.2.fill")
                    ]
                )
                .padding(.horizontal)
                .padding(.top, isCreator ? 8 : 4)
                .padding(.bottom, 12)
                
                // Content based on selection
                TabView(selection: $selectedSegment) {
                    expensesContent
                        .tag(0)
                    
                    buddiesContent
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedSegment)
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(trip: trip)
        }
        .sheet(isPresented: $showingAddBuddy) {
            AddBuddyView(trip: trip)
        }
        .sheet(item: $editingBuddy) { buddy in
            EditBuddyView(buddy: buddy)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateHeader = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    animateCards = true
                }
            }
        }
    }
    
    // MARK: - Expenses Content
    private var expensesContent: some View {
        ZStack {
            if trip.expenses.isEmpty {
                EnhancedEmptyExpensesView(action: {
                    showingAddExpense = true
                })
                .opacity(animateCards ? 1 : 0)
                .scaleEffect(animateCards ? 1 : 0.9)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header Stats Card
                        ExpenseStatsCard(trip: trip, totalSpent: totalSpent)
                            .opacity(animateHeader ? 1 : 0)
                            .offset(y: animateHeader ? 0 : -30)
                        
                        // Expenses List
                        LazyVStack(spacing: 12) {
                            ForEach(Array(sortedExpenses.enumerated()), id: \.element.id) { index, expense in
                                NavigationLink(destination: ExpenseDetailView(expense: expense, trip: trip)) {
                                    EnhancedExpenseRow(expense: expense, trip: trip)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .opacity(animateCards ? 1 : 0)
                                .offset(x: animateCards ? 0 : -30)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.7)
                                    .delay(Double(index) * 0.05),
                                    value: animateCards
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton(
                        icon: "plus",
                        label: "Add Expense",
                        action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showingAddExpense = true
                        }
                    )
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    // MARK: - Buddies Content
    private var buddiesContent: some View {
        ZStack {
            if trip.travelBuddies.isEmpty {
                EnhancedEmptyBuddiesView(action: {
                    showingAddBuddy = true
                })
                .opacity(animateCards ? 1 : 0)
                .scaleEffect(animateCards ? 1 : 0.9)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(trip.travelBuddies.enumerated()), id: \.element.id) { index, buddy in
                            Button {
                                if canEdit {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    editingBuddy = buddy
                                }
                            } label: {
                                EnhancedBuddyCard(buddy: buddy, trip: trip, canEdit: canEdit)
                            }
                            .opacity(animateCards ? 1 : 0)
                            .offset(x: animateCards ? 0 : -30)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.7)
                                .delay(Double(index) * 0.05),
                                value: animateCards
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton(
                        icon: "plus",
                        label: "Add Buddy",
                        action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showingAddBuddy = true
                        }
                    )
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    private func deleteExpensesIfAllowed(at offsets: IndexSet) {
        guard canDelete else { return }
        deleteExpenses(at: offsets)
    }
    
    private func deleteExpenses(at offsets: IndexSet) {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        for index in offsets {
            let expense = sortedExpenses[index]
            
            // Clear the link from itinerary item if it exists
            if let sourceItem = expense.sourceItineraryItem {
                sourceItem.linkedExpense = nil
            }
            
            modelContext.delete(expense)
        }
    }
    
    private func deleteBuddiesIfAllowed(at offsets: IndexSet) {
        guard canDelete else { return }
        deleteBuddies(at: offsets)
    }
    
    private func deleteBuddies(at offsets: IndexSet) {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        for index in offsets {
            modelContext.delete(trip.travelBuddies[index])
        }
    }
}

// MARK: - Custom Segmented Control
struct CustomSegmentedControl: View {
    @Binding var selection: Int
    let segments: [(title: String, icon: String)]
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<segments.count, id: \.self) { index in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = index
                    }
                } label: {
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: segments[index].icon)
                                .font(.subheadline)
                            Text(segments[index].title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(selection == index ? .white : .secondary)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                if selection == index {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .matchedGeometryEffect(id: "segment", in: animation)
                                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Expense Stats Card
struct ExpenseStatsCard: View {
    let trip: Trip
    let totalSpent: Double
    @State private var animateStats = false
    
    var expenseCount: Int {
        trip.expenses.count
    }
    
    var avgPerExpense: Double {
        expenseCount > 0 ? totalSpent / Double(expenseCount) : 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Spent")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(trip.currency.format(totalSpent))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .scaleEffect(animateStats ? 1 : 0.8)
                .rotationEffect(.degrees(animateStats ? 0 : -10))
            }
            
            Divider()
            
            HStack(spacing: 20) {
                ExpenseStatBadge(
                    icon: "receipt",
                    value: "\(expenseCount)",
                    label: "Expenses"
                )
                
                Spacer()
                
                ExpenseStatBadge(
                    icon: "person.2",
                    value: "\(trip.travelBuddies.count)",
                    label: "Buddies"
                )
                
                Spacer()
                
                ExpenseStatBadge(
                    icon: "dollarsign.circle",
                    value: trip.currency.format(avgPerExpense),
                    label: "Average"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3)) {
                animateStats = true
            }
        }
    }
}

struct ExpenseStatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundStyle(.primary)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Enhanced Expense Row
struct EnhancedExpenseRow: View {
    let expense: Expense
    let trip: Trip
    @State private var isPressed = false
    
    var categoryIcon: String {
        expense.name.lowercased().contains("food") || expense.name.lowercased().contains("restaurant") || expense.name.lowercased().contains("dinner") ? "fork.knife" :
        expense.name.lowercased().contains("hotel") || expense.name.lowercased().contains("accommodation") ? "bed.double.fill" :
        expense.name.lowercased().contains("transport") || expense.name.lowercased().contains("uber") || expense.name.lowercased().contains("taxi") ? "car.fill" :
        expense.name.lowercased().contains("flight") || expense.name.lowercased().contains("airline") ? "airplane" :
        "receipt.fill"
    }
    
    var categoryColor: Color {
        expense.name.lowercased().contains("food") || expense.name.lowercased().contains("restaurant") ? .orange :
        expense.name.lowercased().contains("hotel") ? .purple :
        expense.name.lowercased().contains("transport") || expense.name.lowercased().contains("uber") ? .green :
        expense.name.lowercased().contains("flight") ? .blue :
        .blue
    }
    
    var participantCount: Int {
        expense.participantIDs.count
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [categoryColor.opacity(0.2), categoryColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: categoryIcon)
                    .font(.title3)
                    .foregroundStyle(categoryColor)
            }
            
            // Expense Details
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(expense.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    // Show "You added" badge if current user added this expense
                    if expense.addedByUserID == UserManager.shared.currentUserID {
                        HStack(spacing: 3) {
                            Image(systemName: "person.circle.fill")
                                .font(.caption2)
                            Text("You")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                }
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(expense.date, style: .date)
                            .font(.caption)
                    }
                    
                    if participantCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2")
                                .font(.caption2)
                            Text("\(participantCount)")
                                .font(.caption)
                        }
                    }
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text(trip.currency.format(expense.totalAmount))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("per person")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .opacity(participantCount > 1 ? 1 : 0)
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(categoryColor.opacity(0.2), lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .shadow(color: .black.opacity(isPressed ? 0.05 : 0.08), radius: isPressed ? 5 : 8, x: 0, y: isPressed ? 2 : 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Enhanced Buddy Card
struct EnhancedBuddyCard: View {
    let buddy: TravelBuddy
    let trip: Trip
    let canEdit: Bool
    @State private var isPressed = false
    
    private var balance: Double {
        trip.balanceForBuddy(buddy)
    }
    
    private var balanceColor: Color {
        if abs(balance) < 0.01 {
            return .green
        } else if balance > 0 {
            return .blue
        } else {
            return .orange
        }
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
    
    private var avatarColor: Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .red, .indigo, .teal]
        let hash = abs(buddy.name.hashValue)
        return colors[hash % colors.count]
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [avatarColor.opacity(0.3), avatarColor.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Text(buddy.name.prefix(1).uppercased())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(avatarColor)
            }
            
            // Buddy Info
            VStack(alignment: .leading, spacing: 6) {
                Text(buddy.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(balanceColor)
                        .frame(width: 6, height: 6)
                    
                    Text(balanceLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Balance Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text(trip.currency.format(abs(balance)))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(balanceColor)
                
                if !canEdit {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                            .font(.caption2)
                        Text("View Only")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            
            if canEdit {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(avatarColor.opacity(0.2), lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if canEdit { isPressed = true } }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(label)
                    .fontWeight(.bold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(30)
            .shadow(color: .blue.opacity(0.4), radius: isPressed ? 10 : 15, x: 0, y: isPressed ? 4 : 8)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Enhanced Empty States
struct EnhancedEmptyExpensesView: View {
    let action: () -> Void
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.1), .purple.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(animate ? 1.1 : 0.9)
                    .opacity(animate ? 0.5 : 1)
                
                Image(systemName: "receipt.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("No Expenses Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Track your trip spending! Add expenses to split costs with your travel buddies and keep your budget on track.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Your First Expense")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct EnhancedEmptyBuddiesView: View {
    let action: () -> Void
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange.opacity(0.1), .pink.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(animate ? 1.1 : 0.9)
                    .opacity(animate ? 0.5 : 1)
                
                Image(systemName: "person.2.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("No Travel Buddies Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Add your friends and family to split expenses and track who's joining you on this adventure!")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Your First Buddy")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.orange, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// MARK: - Permission Banner
struct PermissionBanner: View {
    let trip: Trip
    @State private var showInfo = false
    
    private var permission: TripPermission {
        trip.permissionFor(userID: UserManager.shared.currentUserID)
    }
    
    private var bannerColor: Color {
        permission == .editor ? .blue : .orange
    }
    
    private var bannerIcon: String {
        permission == .editor ? "pencil.circle.fill" : "eye.circle.fill"
    }
    
    private var bannerText: String {
        permission == .editor ? "You can add & edit expenses" : "You have view-only access"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: bannerIcon)
                .font(.title3)
                .foregroundStyle(bannerColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(bannerText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                if permission == .editor {
                    Text("Collaborate with the trip creator")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Button {
                showInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(bannerColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(bannerColor.opacity(0.3), lineWidth: 1)
                )
        )
        .alert("Trip Access", isPresented: $showInfo) {
            Button("Got it", role: .cancel) {}
        } message: {
            if permission == .editor {
                Text("You're a trip editor! You can:\n• Add new expenses\n• Add travel buddies\n• Add itinerary items\n• Record payments\n\nOnly the trip creator can delete items.")
            } else {
                Text("You have view-only access to this trip. You can see all expenses and balances but cannot make changes.\n\nAsk the trip creator to give you editor access.")
            }
        }
    }
}

#Preview {
    let userID = UserManager.shared.currentUserID
    NavigationStack {
        ExpensesListView(trip: Trip(name: "Test Trip", creatorID: userID), showingAddExpense: .constant(false))
    }
    .modelContainer(for: [Trip.self, Expense.self, TravelBuddy.self])
}
