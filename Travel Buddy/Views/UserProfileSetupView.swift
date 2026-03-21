//
//  UserProfileSetupView.swift
//  Travel Buddy
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI
import SwiftData

struct UserProfileSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var userName = ""
    @State private var showingError = false
    
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.6),
                    Color.purple.opacity(0.5),
                    Color.pink.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 10)
                    
                    Text("Welcome to Split Voyage Group Travel!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Let's get started by setting up your profile")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 60)
                
                // Input card
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Name")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        TextField("Enter your name", text: $userName)
                            .textFieldStyle(.plain)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                            .font(.title3)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Text("You'll be automatically included in all trip expenses, and other travelers can make payments to you.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 4)
                    }
                    
                    Button {
                        saveProfile()
                    } label: {
                        HStack {
                            Text("Continue")
                                .font(.headline)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThickMaterial)
                        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, 24)
                
                Spacer()
                Spacer()
            }
        }
        .interactiveDismissDisabled()
        .alert("Name Required", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please enter your name to continue")
        }
    }
    
    private func saveProfile() {
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            showingError = true
            return
        }
        
        // Create User object in SwiftData as the device owner
        let deviceOwner = User(name: trimmedName, isDeviceOwner: true)
        modelContext.insert(deviceOwner)
        
        // Save to SwiftData
        do {
            try modelContext.save()
        } catch {
            print("Error saving device owner user: \(error)")
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UserManager.shared.completeOnboarding(withName: trimmedName)
        onComplete()
    }
}

#Preview {
    UserProfileSetupView(onComplete: {})
}
