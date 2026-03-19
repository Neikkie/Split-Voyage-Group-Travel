//
//  TravelBuddy.swift
//  Travel Buddy
//
//  Created by Shanique Beckford on 3/12/26.
//

import Foundation
import SwiftData

@Model
final class TravelBuddy {
    var id: UUID
    var name: String
    var trip: Trip?
    var isCurrentUser: Bool
    
    init(name: String, isCurrentUser: Bool = false) {
        self.id = UUID()
        self.name = name
        self.isCurrentUser = isCurrentUser
    }
}
