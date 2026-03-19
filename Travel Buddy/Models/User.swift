//
//  User.swift
//  Travel Buddy
//
//  Created by Shanique Beckford on 3/12/26.
//

import Foundation
import SwiftData

@Model
final class User {
    var id: UUID
    var name: String
    var isDeviceOwner: Bool
    
    init(name: String, isDeviceOwner: Bool = true) {
        self.id = UUID()
        self.name = name
        self.isDeviceOwner = isDeviceOwner
    }
}
