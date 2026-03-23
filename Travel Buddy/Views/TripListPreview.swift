//
//  TripListPreview.swift
//  Split Voyage Group Travel
//
//  Created by Shanique Beckford on 3/13/26.
//

import SwiftUI
import SwiftData

struct TripListPreview: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isSetup = false
    
    var body: some View {
        TripListView()
            .onAppear {
                if !isSetup {
                    setupSampleData()
                    isSetup = true
                }
            }
    }
    
    private func setupSampleData() {
        let creatorID = UUID()
        
        // Create sample trips
        let trip1 = Trip(
            name: "South America Expedition",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
            creatorID: creatorID,
            currency: .usd
        )
        
        let trip2 = Trip(
            name: "European Adventure",
            startDate: Calendar.current.date(byAdding: .month, value: 2, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: 75, to: Calendar.current.date(byAdding: .month, value: 2, to: Date())!)!,
            creatorID: creatorID,
            currency: .eur
        )
        
        // Add buddies to trip1
        let sarah = TravelBuddy(name: "Sarah")
        let mike = TravelBuddy(name: "Mike")
        trip1.travelBuddies.append(sarah)
        trip1.travelBuddies.append(mike)
        
        // Add buddies and expenses to trip2
        let emma = TravelBuddy(name: "Emma")
        trip2.travelBuddies.append(emma)
        
        let flight = Expense(name: "Flight", totalAmount: 450.00, date: Date())
        let hotel = Expense(name: "Hotel", totalAmount: 120.00, date: Date())
        flight.trip = trip2
        hotel.trip = trip2
        trip2.expenses.append(flight)
        trip2.expenses.append(hotel)
        
        // Insert into context
        modelContext.insert(trip1)
        modelContext.insert(trip2)
        
        try? modelContext.save()
    }
}

#Preview {
    TripListPreview()
        .modelContainer(for: [Trip.self, TravelBuddy.self, Expense.self])
}
