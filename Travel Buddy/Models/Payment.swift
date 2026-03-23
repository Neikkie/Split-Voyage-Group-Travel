//
//  Payment.swift
//  Split Voyage Group Travel
//
//  Created by Shanique Beckford on 3/12/26.
//

import Foundation
import SwiftData

@Model
final class Payment {
    var id: UUID
    var amount: Double
    var date: Date
    var fromBuddyID: UUID
    var toBuddyID: UUID
    var notes: String
    var trip: Trip?
    var expense: Expense?
    
    init(amount: Double, fromBuddyID: UUID, toBuddyID: UUID, notes: String = "", date: Date = Date()) {
        self.id = UUID()
        self.amount = amount
        self.fromBuddyID = fromBuddyID
        self.toBuddyID = toBuddyID
        self.notes = notes
        self.date = date
    }
}
