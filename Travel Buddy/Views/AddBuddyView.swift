//
//  AddBuddyView.swift
//  Split Voyage Group Travel
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI
import SwiftData

struct AddBuddyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var trip: Trip
    @State private var buddyName = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Member Details") {
                    TextField("Name", text: $buddyName)
                }
            }
            .navigationTitle("Add Group Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addBuddy()
                    }
                    .disabled(buddyName.isEmpty)
                }
            }
        }
    }
    
    private func addBuddy() {
        let newBuddy = TravelBuddy(name: buddyName)
        newBuddy.trip = trip
        modelContext.insert(newBuddy)
        trip.travelBuddies.append(newBuddy)
        dismiss()
    }
}

#Preview {
    let userID = UserManager.shared.currentUserID
    AddBuddyView(trip: Trip(name: "Test Trip", creatorID: userID))
        .modelContainer(for: [Trip.self, TravelBuddy.self])
}
