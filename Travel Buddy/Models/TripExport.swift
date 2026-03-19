//
//  TripExport.swift
//  Travel Buddy
//
//  Created by Shanique Beckford on 3/12/26.
//

import Foundation

// Codable versions of models for export/import
struct TripExport: Codable {
    let id: String
    let name: String
    let startDate: Date
    let endDate: Date?
    let creatorID: String
    let currencyCode: String
    let travelBuddies: [TravelBuddyExport]
    let expenses: [ExpenseExport]
    let payments: [PaymentExport]
    let tripItems: [TripItemExport]
    let exportDate: Date
    
    // Sync metadata
    let version: Int
    let lastModifiedDate: Date
    let exportedByUserID: String
    
    static func from(trip: Trip, exportedByUserID: UUID) -> TripExport {
        TripExport(
            id: trip.id.uuidString,
            name: trip.name,
            startDate: trip.startDate,
            endDate: trip.endDate,
            creatorID: trip.creatorID.uuidString,
            currencyCode: trip.currencyCode,
            travelBuddies: trip.travelBuddies.map { TravelBuddyExport.from(buddy: $0) },
            expenses: trip.expenses.map { ExpenseExport.from(expense: $0) },
            payments: trip.payments.map { PaymentExport.from(payment: $0) },
            tripItems: trip.tripItems.map { TripItemExport.from(item: $0) },
            exportDate: Date(),
            version: trip.syncVersion,
            lastModifiedDate: trip.lastModifiedAt,
            exportedByUserID: exportedByUserID.uuidString
        )
    }
    
    // Legacy support for old QR codes without sync metadata
    static func from(trip: Trip) -> TripExport {
        from(trip: trip, exportedByUserID: UserManager.shared.currentUserID)
    }
}

struct TravelBuddyExport: Codable {
    let id: String
    let name: String
    
    static func from(buddy: TravelBuddy) -> TravelBuddyExport {
        TravelBuddyExport(id: buddy.id.uuidString, name: buddy.name)
    }
}

struct ExpenseExport: Codable {
    let id: String
    let name: String
    let totalAmount: Double
    let date: Date
    let participantIDs: [String]
    let hasReceipt: Bool
    let splitType: String
    let paidByBuddyID: String?
    let addedByUserID: String?
    let createdAt: Date
    let lastModifiedAt: Date
    
    static func from(expense: Expense) -> ExpenseExport {
        ExpenseExport(
            id: expense.id.uuidString,
            name: expense.name,
            totalAmount: expense.totalAmount,
            date: expense.date,
            participantIDs: expense.participantIDs.map { $0.uuidString },
            hasReceipt: expense.receiptImageData != nil,
            splitType: expense.splitType.rawValue,
            paidByBuddyID: expense.paidByBuddyID?.uuidString,
            addedByUserID: expense.addedByUserID?.uuidString,
            createdAt: expense.createdAt,
            lastModifiedAt: expense.lastModifiedAt
        )
    }
}

struct PaymentExport: Codable {
    let id: String
    let amount: Double
    let date: Date
    let fromBuddyID: String
    let toBuddyID: String
    let notes: String
    
    static func from(payment: Payment) -> PaymentExport {
        PaymentExport(
            id: payment.id.uuidString,
            amount: payment.amount,
            date: payment.date,
            fromBuddyID: payment.fromBuddyID.uuidString,
            toBuddyID: payment.toBuddyID.uuidString,
            notes: payment.notes
        )
    }
}

struct TripItemExport: Codable {
    let id: String
    let name: String
    let type: String
    let startDate: Date
    let cost: Double
    let notes: String
    
    static func from(item: TripItem) -> TripItemExport {
        TripItemExport(
            id: item.id.uuidString,
            name: item.name,
            type: item.type.rawValue,
            startDate: item.startDate,
            cost: item.cost,
            notes: item.notes
        )
    }
}
