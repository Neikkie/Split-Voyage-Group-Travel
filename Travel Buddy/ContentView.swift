//
//  ContentView.swift
//  Split Voyage Group Travel
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showSplash = true
    @State private var showOnboarding = !UserManager.shared.hasCompletedOnboarding
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
            } else if showOnboarding {
                UserProfileSetupView {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showOnboarding = false
                    }
                }
                .transition(.opacity)
            } else {
                TripListView()
                    .transition(.opacity)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Trip.self, TravelBuddy.self, Expense.self])
}
