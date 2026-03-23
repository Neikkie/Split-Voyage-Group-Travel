//
//  Trip.swift
//  Split Voyage Group Travel
//
//  Created by Shanique Beckford on 3/12/26.
//

import Foundation
import SwiftData

enum TripPermission: String, Codable {
    case creator = "Creator"
    case editor = "Editor"
    case viewer = "Viewer"
}

@Model
final class Trip {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date?
    var creatorID: UUID
    var currencyCode: String = "USD" // Store as string for SwiftData compatibility
    var isArchived: Bool = false
    
    // Permission management - stored as JSON string for SwiftData compatibility
    @Attribute(.externalStorage) var permissionsData: Data?
    
    // Sync tracking for local collaboration
    var syncVersion: Int = 1
    var lastModifiedAt: Date = Date()
    var lastSyncedAt: Date?
    var isSharedTrip: Bool = false // True if imported from another device
    
    @Relationship(deleteRule: .cascade, inverse: \TravelBuddy.trip)
    var travelBuddies: [TravelBuddy]
    
    @Relationship(deleteRule: .cascade, inverse: \Expense.trip)
    var expenses: [Expense]
    
    @Relationship(deleteRule: .cascade, inverse: \Payment.trip)
    var payments: [Payment]
    
    @Relationship(deleteRule: .cascade, inverse: \TripItem.trip)
    var tripItems: [TripItem]
    
    init(name: String, startDate: Date = Date(), endDate: Date? = nil, creatorID: UUID, currency: Currency = .usd) {
        self.id = UUID()
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.creatorID = creatorID
        self.currencyCode = currency.rawValue
        self.travelBuddies = []
        self.expenses = []
        self.payments = []
        self.tripItems = []
    }
    
    // Computed property to get Currency enum from stored string
    var currency: Currency {
        get {
            Currency(rawValue: currencyCode) ?? .usd
        }
        set {
            currencyCode = newValue.rawValue
        }
    }
    
    // Permission helpers
    private var permissionsDict: [String: String] {
        get {
            guard let data = permissionsData,
                  let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
                return [:]
            }
            return dict
        }
        set {
            permissionsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // Check if current device owner is the creator
    func isCreator(userID: UUID) -> Bool {
        return creatorID == userID
    }
    
    // Get permission for a user
    func permissionFor(userID: UUID) -> TripPermission {
        if isCreator(userID: userID) {
            return .creator
        }
        
        if let permString = permissionsDict[userID.uuidString],
           let permission = TripPermission(rawValue: permString) {
            return permission
        }
        
        // Default: editors can add/edit, viewers can only view
        // If user is in travelBuddies, they're an editor by default
        return .editor
    }
    
    // Set permission for a user
    func setPermission(_ permission: TripPermission, for userID: UUID) {
        var dict = permissionsDict
        dict[userID.uuidString] = permission.rawValue
        permissionsDict = dict
    }
    
    // Check if user can edit (creator or editor)
    func canEdit(userID: UUID) -> Bool {
        let permission = permissionFor(userID: userID)
        return permission == .creator || permission == .editor
    }
    
    // Check if user can delete (creator only)
    func canDelete(userID: UUID) -> Bool {
        return isCreator(userID: userID)
    }
    
    // Check if trip is completed (end date has passed)
    var isCompleted: Bool {
        guard let endDate = endDate else {
            // If no end date, consider completed if start date was more than 7 days ago
            return startDate < Date().addingTimeInterval(-7 * 24 * 3600)
        }
        return endDate < Date()
    }
    
    // Archive/Unarchive trip
    func toggleArchive() {
        isArchived.toggle()
    }
    
    // Calculate total expenses
    var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.totalAmount }
    }
    
    // Calculate balance for each buddy
    // Returns negative if they owe money, positive if they are owed money
    func balanceForBuddy(_ buddy: TravelBuddy) -> Double {
        var balance = 0.0
        
        for expense in expenses {
            // If this buddy paid for the expense initially, they are owed the full amount
            if expense.paidByBuddyID == buddy.id {
                balance += expense.totalAmount
            }
            
            // Subtract their share of the expense (what they owe)
            if expense.participantIDs.contains(buddy.id) {
                let amountOwed = expense.amountForBuddy(buddy.id)
                let amountPaid = expense.amountPaidByBuddy(buddy.id)
                balance -= (amountOwed - amountPaid)
            }
        }
        
        return balance
    }
    
    // Calculate net balance (simplified view of who owes whom)
    func netBalanceForBuddy(_ buddy: TravelBuddy) -> Double {
        var total = 0.0
        
        // Add expenses this buddy participated in
        for expense in expenses {
            if expense.participantIDs.contains(buddy.id) {
                total += expense.amountPerPerson()
            }
        }
        
        // Subtract payments made
        for payment in payments where payment.fromBuddyID == buddy.id {
            total -= payment.amount
        }
        
        return total
    }
    
    // MARK: - Sync & Merge Logic
    
    // Update sync version when trip is modified
    func markAsModified() {
        syncVersion += 1
        lastModifiedAt = Date()
    }
    
    // Merge incoming trip data from another device
    func merge(with incomingExport: TripExport, context: Any) {
        guard let modelContext = context as? ModelContext else { return }
        
        // Track what was merged for user feedback
        var mergedExpenses = 0
        var mergedBuddies = 0
        var mergedPayments = 0
        var mergedItems = 0
        
        // Merge travel buddies (by ID, avoid duplicates)
        for buddyExport in incomingExport.travelBuddies {
            guard let buddyUUID = UUID(uuidString: buddyExport.id) else { continue }
            
            if !travelBuddies.contains(where: { $0.id == buddyUUID }) {
                let newBuddy = TravelBuddy(name: buddyExport.name)
                newBuddy.id = buddyUUID
                newBuddy.trip = self
                travelBuddies.append(newBuddy)
                modelContext.insert(newBuddy)
                mergedBuddies += 1
            }
        }
        
        // Merge expenses (by ID, keep newest if duplicate)
        for expenseExport in incomingExport.expenses {
            guard let expenseUUID = UUID(uuidString: expenseExport.id) else { continue }
            
            if let existingExpense = expenses.first(where: { $0.id == expenseUUID }) {
                // Expense exists - check if incoming is newer
                if expenseExport.lastModifiedAt > existingExpense.lastModifiedAt {
                    existingExpense.name = expenseExport.name
                    existingExpense.totalAmount = expenseExport.totalAmount
                    existingExpense.date = expenseExport.date
                    existingExpense.lastModifiedAt = expenseExport.lastModifiedAt
                }
            } else {
                // New expense - add it
                let newExpense = Expense(
                    name: expenseExport.name,
                    totalAmount: expenseExport.totalAmount,
                    date: expenseExport.date,
                    participantIDs: expenseExport.participantIDs.compactMap { UUID(uuidString: $0) },
                    splitType: SplitType(rawValue: expenseExport.splitType) ?? .equal,
                    paidByBuddyID: expenseExport.paidByBuddyID.flatMap { UUID(uuidString: $0) },
                    addedByUserID: expenseExport.addedByUserID.flatMap { UUID(uuidString: $0) }
                )
                newExpense.id = expenseUUID
                newExpense.createdAt = expenseExport.createdAt
                newExpense.lastModifiedAt = expenseExport.lastModifiedAt
                newExpense.trip = self
                
                // Create splits for each participant
                for participantID in newExpense.participantIDs {
                    let split = ExpenseSplit(
                        buddyID: participantID,
                        amount: newExpense.amountPerPerson(),
                        amountPaid: 0,
                        isPaidInFull: false
                    )
                    split.expense = newExpense
                    newExpense.splits.append(split)
                    modelContext.insert(split)
                }
                
                expenses.append(newExpense)
                modelContext.insert(newExpense)
                mergedExpenses += 1
            }
        }
        
        // Merge payments (by ID, avoid duplicates)
        for paymentExport in incomingExport.payments {
            guard let paymentUUID = UUID(uuidString: paymentExport.id) else { continue }
            
            if !payments.contains(where: { $0.id == paymentUUID }) {
                let newPayment = Payment(
                    amount: paymentExport.amount,
                    fromBuddyID: UUID(uuidString: paymentExport.fromBuddyID) ?? UUID(),
                    toBuddyID: UUID(uuidString: paymentExport.toBuddyID) ?? UUID(),
                    notes: paymentExport.notes,
                    date: paymentExport.date
                )
                newPayment.id = paymentUUID
                newPayment.trip = self
                payments.append(newPayment)
                modelContext.insert(newPayment)
                mergedPayments += 1
            }
        }
        
        // Merge trip items (by ID, avoid duplicates)
        for itemExport in incomingExport.tripItems {
            guard let itemUUID = UUID(uuidString: itemExport.id) else { continue }
            
            if !tripItems.contains(where: { $0.id == itemUUID }) {
                let newItem = TripItem(
                    type: TripItemType(rawValue: itemExport.type) ?? .activity,
                    name: itemExport.name,
                    notes: itemExport.notes,
                    startDate: itemExport.startDate,
                    cost: itemExport.cost
                )
                newItem.id = itemUUID
                newItem.trip = self
                tripItems.append(newItem)
                modelContext.insert(newItem)
                mergedItems += 1
            }
        }
        
        // Update sync metadata
        lastSyncedAt = Date()
        if incomingExport.version > syncVersion {
            syncVersion = incomingExport.version
        }
        
        print("✅ Merge complete: \(mergedExpenses) expenses, \(mergedBuddies) buddies, \(mergedPayments) payments, \(mergedItems) items")
    }
}
