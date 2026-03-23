//
//  Expense.swift
//  Split Voyage Group Travel
//
//  Created by Shanique Beckford on 3/12/26.
//

import Foundation
import SwiftData
import SwiftUI

enum SplitType: String, Codable {
    case equal = "Equal Split"
    case custom = "Custom Amounts"
    case percentage = "Percentage"
    case shares = "By Shares"
}

@Model
final class ExpenseSplit {
    var id: UUID
    var buddyID: UUID
    var amount: Double
    var amountPaid: Double
    var isPaidInFull: Bool
    var expense: Expense?
    
    init(buddyID: UUID, amount: Double, amountPaid: Double = 0, isPaidInFull: Bool = false) {
        self.id = UUID()
        self.buddyID = buddyID
        self.amount = amount
        self.amountPaid = amountPaid
        self.isPaidInFull = isPaidInFull
    }
    
    var remainingAmount: Double {
        return max(0, amount - amountPaid)
    }
}

@Model
final class Expense {
    var id: UUID
    var name: String
    var totalAmount: Double
    var date: Date
    @Attribute(.externalStorage) var receiptImageData: Data?
    var trip: Trip?
    var sourceItineraryItem: TripItem? // Link back to itinerary item if created from one
    
    // Stores the IDs of participants who should pay for this expense
    var participantIDs: [UUID]
    
    // Split configuration
    var splitType: SplitType
    
    @Relationship(deleteRule: .cascade, inverse: \ExpenseSplit.expense)
    var splits: [ExpenseSplit]
    
    // Who paid the expense initially (if someone paid for everyone)
    var paidByBuddyID: UUID?
    
    // Track who added this expense (for collaborative editing)
    var addedByUserID: UUID?
    var addedByBuddyID: UUID?
    var createdAt: Date
    var lastModifiedAt: Date
    var lastModifiedByUserID: UUID?
    
    init(name: String, totalAmount: Double, date: Date = Date(), receiptImageData: Data? = nil, participantIDs: [UUID] = [], splitType: SplitType = .equal, paidByBuddyID: UUID? = nil, addedByUserID: UUID? = nil, addedByBuddyID: UUID? = nil) {
        self.id = UUID()
        self.name = name
        self.totalAmount = totalAmount
        self.date = date
        self.receiptImageData = receiptImageData
        self.participantIDs = participantIDs
        self.splitType = splitType
        self.splits = []
        self.paidByBuddyID = paidByBuddyID
        self.addedByUserID = addedByUserID
        self.addedByBuddyID = addedByBuddyID
        self.createdAt = Date()
        self.lastModifiedAt = Date()
        self.lastModifiedByUserID = addedByUserID
    }
    
    // Calculate amount per person based on selected participants (for equal split)
    func amountPerPerson() -> Double {
        guard participantIDs.count > 0 else { return 0 }
        return totalAmount / Double(participantIDs.count)
    }
    
    // Get split amount for a specific buddy
    func amountForBuddy(_ buddyID: UUID) -> Double {
        if let split = splits.first(where: { $0.buddyID == buddyID }) {
            return split.amount
        }
        // Fallback to equal split
        return amountPerPerson()
    }
    
    // Get amount paid by a specific buddy
    func amountPaidByBuddy(_ buddyID: UUID) -> Double {
        if let split = splits.first(where: { $0.buddyID == buddyID }) {
            return split.amountPaid
        }
        return 0
    }
    
    // Get remaining amount for a specific buddy
    func remainingAmountForBuddy(_ buddyID: UUID) -> Double {
        if let split = splits.first(where: { $0.buddyID == buddyID }) {
            return split.remainingAmount
        }
        return amountForBuddy(buddyID)
    }
    
    // Check if a buddy has paid their share in full
    func isBuddyPaidInFull(_ buddyID: UUID) -> Bool {
        if let split = splits.first(where: { $0.buddyID == buddyID }) {
            return split.isPaidInFull
        }
        return false
    }
    
    // Total amount paid so far
    var totalAmountPaid: Double {
        splits.reduce(0) { $0 + $1.amountPaid }
    }
    
    // Total amount remaining
    var totalAmountRemaining: Double {
        max(0, totalAmount - totalAmountPaid)
    }
    
    // Check if expense is fully paid
    var isFullyPaid: Bool {
        totalAmountRemaining <= 0.01 // Allow for rounding errors
    }
}
