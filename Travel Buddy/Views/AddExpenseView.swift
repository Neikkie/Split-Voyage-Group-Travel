//
//  AddExpenseView.swift
//  Split Voyage Group Travel
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var trip: Trip
    
    @State private var expenseName = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var scannedImage: UIImage?
    @State private var extractedAmount: Double?
    @State private var showingScanner = false
    @State private var selectedBuddyIDs: Set<UUID> = []
    @State private var splitType: SplitType = .equal
    @State private var customAmounts: [UUID: String] = [:]
    @State private var customPercentages: [UUID: String] = [:]
    @State private var customShares: [UUID: String] = [:]
    @State private var paidByBuddyID: UUID?
    @State private var showSplitAnimation = false
    
    var body: some View {
        NavigationStack {
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
                
                Form {
                    // Info Banner
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.title3)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Smart Expense Splitting")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("Track expenses and split costs fairly with your group members")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    
                    // Expense Details
                    Section("Expense Details") {
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundStyle(.blue)
                            TextField("Name (e.g., Dinner, Taxi)", text: $expenseName)
                        }
                        
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundStyle(.green)
                            Text(trip.currency.symbol)
                            TextField("Amount", text: $amount)
                                .keyboardType(.decimalPad)
                        }
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(.orange)
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                        }
                    }
                    
                    // Receipt Section
                    receiptSection
                    
                    // Who Paid Section
                    whoPaidSection
                    
                    // Split Type Selection
                    splitTypeSection
                    
                    // Participants Selection
                    participantsSection
                    
                    // Split Details based on type
                    if !selectedBuddyIDs.isEmpty && Double(amount) != nil {
                        splitDetailsSection
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        addExpense()
                    }
                    .disabled(!canAddExpense)
                }
            }
            .sheet(isPresented: $showingScanner) {
                NavigationStack {
                    ReceiptScannerView(scannedImage: $scannedImage, extractedAmount: $extractedAmount)
                }
            }
            .onAppear {
                // Auto-select all buddies by default
                selectedBuddyIDs = Set(trip.travelBuddies.map { $0.id })
            }
        }
    }
    
    // MARK: - Receipt Section
    private var receiptSection: some View {
        Section {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showingScanner = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "camera.fill")
                            .foregroundStyle(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scan Receipt")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Auto-detect amount from image")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let image = scannedImage {
                VStack(spacing: 12) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .transition(.scale.combined(with: .opacity))
                    
                    if let extractedAmount = extractedAmount {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Detected Amount")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(trip.currency.format(extractedAmount))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.green)
                            }
                            
                            Spacer()
                            
                            Button("Use Amount") {
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                withAnimation(.spring()) {
                                    amount = String(format: "%.2f", extractedAmount)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                        )
                    }
                }
            }
        } header: {
            Label("Receipt", systemImage: "doc.text.fill")
        }
    }
    
    // MARK: - Who Paid Section
    private var whoPaidSection: some View {
        Section {
            if trip.travelBuddies.isEmpty {
                Text("Add group members first")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(trip.travelBuddies) { buddy in
                    Button {
                        UISelectionFeedbackGenerator().selectionChanged()
                        withAnimation(.spring()) {
                            paidByBuddyID = buddy.id
                        }
                    } label: {
                        HStack {
                            Image(systemName: paidByBuddyID == buddy.id ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(paidByBuddyID == buddy.id ? .green : .gray)
                                .symbolEffect(.bounce, value: paidByBuddyID == buddy.id)
                            
                            Text(buddy.name)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                        }
                    }
                }
            }
        } header: {
            Label("Who Paid This Expense?", systemImage: "person.fill.checkmark")
        } footer: {
            Text("Select who initially paid for this expense")
        }
    }
    
    // MARK: - Split Type Section
    private var splitTypeSection: some View {
        Section {
            ForEach([SplitType.equal, .custom, .percentage, .shares], id: \.self) { type in
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    withAnimation(.spring()) {
                        splitType = type
                        showSplitAnimation.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: iconForSplitType(type))
                            .foregroundStyle(splitType == type ? .blue : .gray)
                            .symbolEffect(.bounce, value: splitType == type)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.rawValue)
                                .foregroundStyle(.primary)
                                .fontWeight(splitType == type ? .semibold : .regular)
                            Text(descriptionForSplitType(type))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if splitType == type {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        } header: {
            Label("Split Method", systemImage: "chart.pie.fill")
        }
    }
    
    // MARK: - Participants Section
    private var participantsSection: some View {
        Section {
            if trip.travelBuddies.isEmpty {
                Text("Add group members first")
                    .foregroundStyle(.secondary)
            } else {
                Button(selectedBuddyIDs.count == trip.travelBuddies.count ? "Deselect All" : "Select All") {
                    UISelectionFeedbackGenerator().selectionChanged()
                    withAnimation(.spring()) {
                        if selectedBuddyIDs.count == trip.travelBuddies.count {
                            selectedBuddyIDs.removeAll()
                        } else {
                            selectedBuddyIDs = Set(trip.travelBuddies.map { $0.id })
                        }
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.blue)
                
                ForEach(trip.travelBuddies) { buddy in
                    Toggle(isOn: Binding(
                        get: { selectedBuddyIDs.contains(buddy.id) },
                        set: { isSelected in
                            // Prevent deselecting the current user
                            if buddy.isCurrentUser && !isSelected {
                                return
                            }
                            UISelectionFeedbackGenerator().selectionChanged()
                            withAnimation(.spring()) {
                                if isSelected {
                                    selectedBuddyIDs.insert(buddy.id)
                                } else {
                                    selectedBuddyIDs.remove(buddy.id)
                                }
                            }
                        }
                    )) {
                        HStack {
                            Image(systemName: buddy.isCurrentUser ? "person.fill.checkmark" : "person.fill")
                                .foregroundStyle(buddy.isCurrentUser ? .green : .blue)
                            Text(buddy.name)
                            if buddy.isCurrentUser {
                                Text("(You)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .tint(.blue)
                    .disabled(buddy.isCurrentUser)
                }
            }
        } header: {
            Label("Who Should Pay?", systemImage: "person.2.fill")
        } footer: {
            Text("Select who should split this expense")
        }
    }
    
    // MARK: - Split Details Section
    private var splitDetailsSection: some View {
        Section {
            let amountValue = Double(amount) ?? 0
            let selectedBuddies = trip.travelBuddies.filter { selectedBuddyIDs.contains($0.id) }
            
            switch splitType {
            case .equal:
                equalSplitView(amountValue: amountValue, buddies: selectedBuddies)
            case .custom:
                customSplitView(buddies: selectedBuddies)
            case .percentage:
                percentageSplitView(amountValue: amountValue, buddies: selectedBuddies)
            case .shares:
                sharesSplitView(amountValue: amountValue, buddies: selectedBuddies)
            }
        } header: {
            Label("Split Breakdown", systemImage: "chart.bar.fill")
        }
    }
    
    // MARK: - Split Views
    private func equalSplitView(amountValue: Double, buddies: [TravelBuddy]) -> some View {
        let perPerson = amountValue / Double(buddies.count)
        
        return Group {
            ForEach(buddies) { buddy in
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(.blue)
                    Text(buddy.name)
                    Spacer()
                    Text(trip.currency.format(perPerson))
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .padding(.vertical, 4)
            }
            
            Divider()
            
            HStack {
                Image(systemName: "equal.circle.fill")
                    .foregroundStyle(.green)
                Text("Per Person")
                    .fontWeight(.semibold)
                Spacer()
                Text(trip.currency.format(perPerson))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
            }
            .padding(.vertical, 8)
        }
    }
    
    private func customSplitView(buddies: [TravelBuddy]) -> some View {
        let totalCustom = buddies.reduce(0.0) { sum, buddy in
            sum + (Double(customAmounts[buddy.id] ?? "") ?? 0)
        }
        let amountValue = Double(amount) ?? 0
        let remaining = amountValue - totalCustom
        
        return Group {
            ForEach(buddies) { buddy in
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(.blue)
                        Text(buddy.name)
                        Spacer()
                    }
                    
                    HStack {
                        Text(trip.currency.symbol)
                        TextField("Amount", text: Binding(
                            get: { customAmounts[buddy.id] ?? "" },
                            set: { customAmounts[buddy.id] = $0 }
                        ))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Divider()
            
            HStack {
                Image(systemName: remaining < 0.01 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(remaining < 0.01 ? .green : .orange)
                Text("Remaining")
                    .fontWeight(.semibold)
                Spacer()
                Text(trip.currency.format(remaining))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(remaining < 0.01 ? .green : .orange)
            }
            .padding(.vertical, 8)
        }
    }
    
    private func percentageSplitView(amountValue: Double, buddies: [TravelBuddy]) -> some View {
        let totalPercentage = buddies.reduce(0.0) { sum, buddy in
            sum + (Double(customPercentages[buddy.id] ?? "") ?? 0)
        }
        let remaining = 100 - totalPercentage
        
        return Group {
            ForEach(buddies) { buddy in
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(.blue)
                        Text(buddy.name)
                        Spacer()
                        let percentage = Double(customPercentages[buddy.id] ?? "") ?? 0
                        Text(trip.currency.format(amountValue * percentage / 100))
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        TextField("Percentage", text: Binding(
                            get: { customPercentages[buddy.id] ?? "" },
                            set: { customPercentages[buddy.id] = $0 }
                        ))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        Text("%")
                    }
                }
                .padding(.vertical, 4)
            }
            
            Divider()
            
            HStack {
                Image(systemName: abs(remaining) < 0.01 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(abs(remaining) < 0.01 ? .green : .orange)
                Text("Remaining")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(String(format: "%.1f", remaining))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(abs(remaining) < 0.01 ? .green : .orange)
            }
            .padding(.vertical, 8)
        }
    }
    
    private func sharesSplitView(amountValue: Double, buddies: [TravelBuddy]) -> some View {
        let totalShares = buddies.reduce(0.0) { sum, buddy in
            sum + (Double(customShares[buddy.id] ?? "") ?? 0)
        }
        let perShare = totalShares > 0 ? amountValue / totalShares : 0
        
        return Group {
            ForEach(buddies) { buddy in
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(.blue)
                        Text(buddy.name)
                        Spacer()
                        let shares = Double(customShares[buddy.id] ?? "") ?? 0
                        Text(trip.currency.format(shares * perShare))
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        TextField("Shares", text: Binding(
                            get: { customShares[buddy.id] ?? "" },
                            set: { customShares[buddy.id] = $0 }
                        ))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        Text("shares")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            
            if totalShares > 0 {
                Divider()
                
                HStack {
                    Image(systemName: "equal.circle.fill")
                        .foregroundStyle(.green)
                    Text("Per Share")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(trip.currency.format(perShare))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func iconForSplitType(_ type: SplitType) -> String {
        switch type {
        case .equal: return "equal.circle.fill"
        case .custom: return "pencil.circle.fill"
        case .percentage: return "percent"
        case .shares: return "chart.bar.fill"
        }
    }
    
    private func descriptionForSplitType(_ type: SplitType) -> String {
        switch type {
        case .equal: return "Split evenly between everyone"
        case .custom: return "Specify exact amounts for each person"
        case .percentage: return "Split by percentage"
        case .shares: return "Divide into proportional shares"
        }
    }
    
    private var canAddExpense: Bool {
        guard !expenseName.isEmpty,
              let amountValue = Double(amount),
              amountValue > 0,
              !selectedBuddyIDs.isEmpty else {
            return false
        }
        
        // Additional validation based on split type
        switch splitType {
        case .equal:
            return true
        case .custom:
            let total = selectedBuddyIDs.reduce(0.0) { sum, id in
                sum + (Double(customAmounts[id] ?? "") ?? 0)
            }
            return abs(total - amountValue) < 0.01
        case .percentage:
            let total = selectedBuddyIDs.reduce(0.0) { sum, id in
                sum + (Double(customPercentages[id] ?? "") ?? 0)
            }
            return abs(total - 100) < 0.01
        case .shares:
            let total = selectedBuddyIDs.reduce(0.0) { sum, id in
                sum + (Double(customShares[id] ?? "") ?? 0)
            }
            return total > 0
        }
    }
    
    private func addExpense() {
        guard let amountValue = Double(amount) else { return }
        
        let imageData = scannedImage?.jpegData(compressionQuality: 0.7)
        
        let newExpense = Expense(
            name: expenseName,
            totalAmount: amountValue,
            date: date,
            receiptImageData: imageData,
            participantIDs: Array(selectedBuddyIDs),
            splitType: splitType,
            paidByBuddyID: paidByBuddyID,
            addedByUserID: UserManager.shared.currentUserID
        )
        
        // Create splits based on type
        for buddyID in selectedBuddyIDs {
            let splitAmount: Double
            
            switch splitType {
            case .equal:
                splitAmount = amountValue / Double(selectedBuddyIDs.count)
            case .custom:
                splitAmount = Double(customAmounts[buddyID] ?? "") ?? 0
            case .percentage:
                let percentage = Double(customPercentages[buddyID] ?? "") ?? 0
                splitAmount = amountValue * percentage / 100
            case .shares:
                let shares = Double(customShares[buddyID] ?? "") ?? 0
                let totalShares = selectedBuddyIDs.reduce(0.0) { sum, id in
                    sum + (Double(customShares[id] ?? "") ?? 0)
                }
                splitAmount = totalShares > 0 ? (amountValue * shares / totalShares) : 0
            }
            
            let split = ExpenseSplit(buddyID: buddyID, amount: splitAmount)
            split.expense = newExpense
            newExpense.splits.append(split)
            modelContext.insert(split)
        }
        
        newExpense.trip = trip
        modelContext.insert(newExpense)
        trip.expenses.append(newExpense)
        
        dismiss()
    }
}

#Preview {
    let userID = UserManager.shared.currentUserID
    let trip = Trip(name: "Test Trip", creatorID: userID)
    trip.travelBuddies = [
        TravelBuddy(name: "Alice"),
        TravelBuddy(name: "Bob"),
        TravelBuddy(name: "Charlie")
    ]
    
    return AddExpenseView(trip: trip)
        .modelContainer(for: [Trip.self, TravelBuddy.self, Expense.self])
}
