//
//  TripItem.swift
//  Travel Buddy
//
//  Created by Shanique Beckford on 3/12/26.
//

import Foundation
import SwiftData

enum TripItemType: String, Codable, CaseIterable {
    case accommodation = "Accommodation"
    case transportation = "Transportation"
    case flight = "Flight"
    case activity = "Activity"
    case restaurant = "Restaurant"
    
    var icon: String {
        switch self {
        case .accommodation: return "bed.double.fill"
        case .transportation: return "car.fill"
        case .flight: return "airplane"
        case .activity: return "figure.walk"
        case .restaurant: return "fork.knife"
        }
    }
    
    var color: String {
        switch self {
        case .accommodation: return "blue"
        case .transportation: return "green"
        case .flight: return "purple"
        case .activity: return "orange"
        case .restaurant: return "red"
        }
    }
}

@Model
final class TripItem {
    var id: UUID
    var typeRaw: String
    var name: String
    var notes: String
    var startDate: Date
    var endDate: Date?
    var location: String
    var cost: Double
    var isPaid: Bool
    var confirmationNumber: String
    
    // Accommodation specific
    var checkInTime: Date?
    var checkOutTime: Date?
    var address: String
    
    // Flight specific
    var flightNumber: String
    var airline: String
    var departureAirport: String
    var arrivalAirport: String
    var departureTime: Date?
    var arrivalTime: Date?
    
    // Activity/Restaurant specific
    var reservationTime: Date?
    var phoneNumber: String
    var website: String
    
    var trip: Trip?
    var linkedExpense: Expense? // Link to expense if this item was added as an expense
    
    var type: TripItemType {
        get {
            TripItemType(rawValue: typeRaw) ?? .activity
        }
        set {
            typeRaw = newValue.rawValue
        }
    }
    
    init(
        type: TripItemType,
        name: String,
        notes: String = "",
        startDate: Date = Date(),
        endDate: Date? = nil,
        location: String = "",
        cost: Double = 0,
        isPaid: Bool = false,
        confirmationNumber: String = ""
    ) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.name = name
        self.notes = notes
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.cost = cost
        self.isPaid = isPaid
        self.confirmationNumber = confirmationNumber
        
        // Initialize optional fields
        self.address = ""
        self.flightNumber = ""
        self.airline = ""
        self.departureAirport = ""
        self.arrivalAirport = ""
        self.phoneNumber = ""
        self.website = ""
    }
    
    // Convenience initializer for accommodations
    static func accommodation(
        name: String,
        address: String,
        checkIn: Date,
        checkOut: Date,
        cost: Double = 0,
        confirmationNumber: String = ""
    ) -> TripItem {
        let item = TripItem(
            type: .accommodation,
            name: name,
            startDate: checkIn,
            endDate: checkOut,
            location: address,
            cost: cost,
            confirmationNumber: confirmationNumber
        )
        item.address = address
        item.checkInTime = checkIn
        item.checkOutTime = checkOut
        return item
    }
    
    // Convenience initializer for flights
    static func flight(
        airline: String,
        flightNumber: String,
        departure: String,
        arrival: String,
        departureTime: Date,
        arrivalTime: Date,
        cost: Double = 0,
        confirmationNumber: String = ""
    ) -> TripItem {
        let item = TripItem(
            type: .flight,
            name: "\(airline) \(flightNumber)",
            startDate: departureTime,
            endDate: arrivalTime,
            location: "\(departure) → \(arrival)",
            cost: cost,
            confirmationNumber: confirmationNumber
        )
        item.airline = airline
        item.flightNumber = flightNumber
        item.departureAirport = departure
        item.arrivalAirport = arrival
        item.departureTime = departureTime
        item.arrivalTime = arrivalTime
        return item
    }
    
    // Convenience initializer for activities
    static func activity(
        name: String,
        location: String,
        date: Date,
        time: Date? = nil,
        cost: Double = 0,
        notes: String = ""
    ) -> TripItem {
        let item = TripItem(
            type: .activity,
            name: name,
            notes: notes,
            startDate: date,
            location: location,
            cost: cost
        )
        item.reservationTime = time
        return item
    }
    
    // Convenience initializer for restaurants
    static func restaurant(
        name: String,
        location: String,
        reservationTime: Date,
        phoneNumber: String = "",
        cost: Double = 0
    ) -> TripItem {
        let item = TripItem(
            type: .restaurant,
            name: name,
            startDate: reservationTime,
            location: location,
            cost: cost
        )
        item.phoneNumber = phoneNumber
        item.reservationTime = reservationTime
        return item
    }
}
