//
//  EditBuddyView.swift
//  Split Voyage Group Travel
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI
import SwiftData

struct EditBuddyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var buddy: TravelBuddy
    
    @State private var buddyName: String
    
    init(buddy: TravelBuddy) {
        self.buddy = buddy
        _buddyName = State(initialValue: buddy.name)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Buddy Details") {
                    TextField("Name", text: $buddyName)
                }
            }
            .navigationTitle("Edit Group Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(buddyName.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        buddy.name = buddyName
        dismiss()
    }
}

#Preview {
    EditBuddyView(buddy: TravelBuddy(name: "Alice"))
        .modelContainer(for: [TravelBuddy.self])
}
