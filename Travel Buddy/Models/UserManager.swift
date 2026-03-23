//
//  UserManager.swift
//  Split Voyage Group Travel
//
//  Created by Shanique Beckford on 3/12/26.
//

import Foundation
import SwiftData

@Observable
class UserManager {
    static let shared = UserManager()
    
    private let userIDKey = "currentUserID"
    private let userNameKey = "currentUserName"
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    
    var currentUserID: UUID {
        if let savedID = UserDefaults.standard.string(forKey: userIDKey),
           let uuid = UUID(uuidString: savedID) {
            return uuid
        } else {
            // First time - create new user ID
            let newID = UUID()
            UserDefaults.standard.set(newID.uuidString, forKey: userIDKey)
            return newID
        }
    }
    
    var currentUserName: String {
        get {
            UserDefaults.standard.string(forKey: userNameKey) ?? "Me"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userNameKey)
        }
    }
    
    var hasCompletedOnboarding: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasCompletedOnboardingKey)
        }
    }
    
    func completeOnboarding(withName name: String) {
        currentUserName = name
        hasCompletedOnboarding = true
    }
    
    private init() {}
}
