//
//  Travel_BuddyApp.swift
//  Travel Buddy
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI
import SwiftData
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport

@main
struct Travel_BuddyApp: App {
    init() {
        // Force light mode for the entire app
        applyLightMode()
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Trip.self,
            TravelBuddy.self,
            Expense.self,
            ExpenseSplit.self,
            Payment.self,
            User.self,
            TripItem.self,
            ManualExchangeRate.self
        ])
        
        // Enable automatic migration and delete-recreate on schema mismatch
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ ModelContainer initialized successfully")
            return container
        } catch {
            // Log the error for debugging
            print("⚠️ WARNING: ModelContainer creation failed, attempting recovery...")
            print("Error details: \(error)")
            
            // Try to delete the old store and create a fresh one
            do {
                // Get the store URL
                let storeURL = modelConfiguration.url
                print("🗑️ Deleting old database at: \(storeURL)")
                try? FileManager.default.removeItem(at: storeURL)
                
                // Try creating container again with fresh database
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("✅ ModelContainer recreated successfully with fresh database")
                return container
            } catch {
                print("❌ Recovery failed: \(error)")
            }
            
            // Last resort: use in-memory container
            print("⚠️ Using in-memory database as fallback")
            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [memoryConfig])
            } catch {
                fatalError("Could not create even in-memory ModelContainer: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                        ATTrackingManager.requestTrackingAuthorization { _ in
                            MobileAds.shared.start(completionHandler: nil)
                        }
                    } else {
                        MobileAds.shared.start(completionHandler: nil)
                    }
                }
                .preferredColorScheme(.light)
                .onAppear {
                    applyLightMode()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func applyLightMode() {
        // Force light mode across all windows and scenes
        DispatchQueue.main.async {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .forEach { window in
                    window.overrideUserInterfaceStyle = .light
                }
        }
    }
}
