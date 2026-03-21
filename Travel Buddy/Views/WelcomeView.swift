//
//  WelcomeView.swift
//  Travel Buddy
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI

struct WelcomeView: View {
    @Binding var showWelcome: Bool
    var onCreateTrip: () -> Void
    
    @State private var animateIcon = false
    @State private var animateFeatures = false
    @State private var animateButtons = false
    @State private var selectedFeature: Int = 0
    @State private var particleAnimation = false
    @State private var backgroundOffset: CGFloat = 0
    
    private let features = [
        (icon: "person.2.fill", title: "Add Travel Buddies", description: "Invite your friends and split expenses fairly", emoji: "👥", bgIcon: "person.3.fill", color: Color.blue),
        (icon: "camera.fill", title: "Scan Receipts", description: "Snap a photo and auto-detect amounts instantly", emoji: "📸", bgIcon: "doc.text.magnifyingglass", color: Color.purple),
        (icon: "chart.bar.fill", title: "Track & Settle", description: "Real-time balance updates for everyone", emoji: "💰", bgIcon: "chart.line.uptrend.xyaxis", color: Color.green),
        (icon: "airplane.departure.fill", title: "Plan Trips", description: "Organize flights, hotels, and activities", emoji: "✈️", bgIcon: "map.fill", color: Color.orange),
        (icon: "lock.shield.fill", title: "100% Private", description: "All your data stays secure on your device", emoji: "🔒", bgIcon: "shield.lefthalf.filled", color: Color.red)
    ]
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.15),
                    Color.purple.opacity(0.1),
                    Color.pink.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 40) {
                    Spacer().frame(height: 40)
                    
                    // App Icon/Logo with animation
                    Image(systemName: "airplane.circle.fill")
                        .font(.system(size: 120))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.4), radius: 20, x: 0, y: 10)
                        .scaleEffect(animateIcon ? 1.0 : 0.5)
                        .opacity(animateIcon ? 1 : 0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateIcon)
                    
                    VStack(spacing: 12) {
                        Text("Welcome to")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .opacity(animateIcon ? 1 : 0)
                        
                        Text("Split Voyage")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .opacity(animateIcon ? 1 : 0)
                        
                        Text("Split expenses easily on group trips")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .opacity(animateIcon ? 1 : 0)
                            .padding(.horizontal)
                    }
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateIcon)
                    
                    // Features with enhanced design
                    VStack(spacing: 20) {
                        ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                            EnhancedFeatureRow(
                                icon: feature.icon,
                                title: feature.title,
                                description: feature.description,
                                color: feature.color
                            )
                            .offset(x: animateFeatures ? 0 : -50)
                            .opacity(animateFeatures ? 1 : 0)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.7)
                                    .delay(Double(index) * 0.15),
                                value: animateFeatures
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // CTA Buttons
                    VStack(spacing: 16) {
                        Button {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            onCreateTrip()
                            showWelcome = false
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                Text("Create Your First Trip")
                                    .fontWeight(.bold)
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                            .shadow(color: .blue.opacity(0.5), radius: 20, x: 0, y: 10)
                        }
                        .scaleEffect(animateButtons ? 1 : 0.9)
                        .opacity(animateButtons ? 1 : 0)
                        
                        Button {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            showWelcome = false
                        } label: {
                            Text("Skip for Now")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 12)
                        }
                        .opacity(animateButtons ? 0.8 : 0)
                    }
                    .padding(.horizontal, 24)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: animateButtons)
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .onAppear {
            withAnimation {
                animateIcon = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                animateFeatures = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                animateButtons = true
            }
        }
    }
}

struct EnhancedFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: color.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    WelcomeView(showWelcome: .constant(true), onCreateTrip: {})
}
