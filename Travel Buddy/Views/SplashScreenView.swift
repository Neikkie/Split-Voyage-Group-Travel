//
//  SplashScreenView.swift
//  Travel Buddy
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var showPlane = false
    @State private var planeOffset: CGFloat = -200
    @State private var showClouds = false
    @State private var showTitle = false
    @State private var showTagline = false
    @State private var rotationAngle: Double = 0
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.6),
                    Color.purple.opacity(0.5),
                    Color.pink.opacity(0.4),
                    Color.orange.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .hueRotation(.degrees(isAnimating ? 30 : 0))
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: isAnimating)
            
            // Animated clouds in background
            if showClouds {
                ForEach(0..<5, id: \.self) { index in
                    CloudView(index: index)
                }
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                // Main logo area
                ZStack {
                    // Pulsing circle background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .opacity(opacity)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                    
                    // Rotating ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .blue.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(rotationAngle))
                        .opacity(opacity)
                    
                    // Airplane icon with flight path animation
                    if showPlane {
                        ZStack {
                            // Trail effect
                            ForEach(0..<3, id: \.self) { index in
                                Image(systemName: "airplane")
                                    .font(.system(size: 70))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.white, .blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .opacity(0.3 - Double(index) * 0.1)
                                    .offset(x: CGFloat(index) * -10, y: CGFloat(index) * -10)
                            }
                            
                            // Main airplane
                            Image(systemName: "airplane")
                                .font(.system(size: 70))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .blue.opacity(0.5), radius: 20)
                                .rotationEffect(.degrees(-45))
                        }
                        .offset(x: planeOffset, y: planeOffset)
                        .scaleEffect(scale)
                    }
                }
                
                // App title with character animation
                if showTitle {
                    HStack(spacing: 8) {
                        ForEach(Array("Travel Buddy".enumerated()), id: \.offset) { index, character in
                            Text(String(character))
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: .black.opacity(0.3), radius: 10)
                                .offset(y: isAnimating ? -5 : 5)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.1),
                                    value: isAnimating
                                )
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Tagline
                if showTagline {
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            TagIcon(icon: "airplane.departure", color: .white)
                            TagIcon(icon: "person.2.fill", color: .white)
                            TagIcon(icon: "dollarsign.circle.fill", color: .white)
                        }
                        
                        Text("Split expenses, share memories")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
                
                // Loading indicator
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(.white)
                            .frame(width: 12, height: 12)
                            .scaleEffect(isAnimating ? 1.0 : 0.5)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
                .opacity(opacity)
                .padding(.bottom, 60)
            }
            
            // Sparkle effects
            if isAnimating {
                ForEach(0..<8, id: \.self) { index in
                    SparkleView(index: index)
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Start background animation immediately
        isAnimating = true
        opacity = 1.0
        
        // Show clouds
        withAnimation(.easeIn(duration: 0.5)) {
            showClouds = true
        }
        
        // Animate plane flying in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showPlane = true
            withAnimation(.spring(response: 1.2, dampingFraction: 0.7)) {
                planeOffset = 0
                scale = 1.0
            }
        }
        
        // Start rotating ring
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        // Show title
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                showTitle = true
            }
        }
        
        // Show tagline
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                showTagline = true
            }
        }
        
        // Haptic feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        
        // Complete animation and transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onComplete()
            }
        }
    }
}

// MARK: - Supporting Views

struct CloudView: View {
    let index: Int
    @State private var offset: CGFloat = 0
    
    var body: some View {
        Image(systemName: "cloud.fill")
            .font(.system(size: CGFloat(30 + index * 10)))
            .foregroundColor(.white.opacity(0.3))
            .offset(x: offset, y: CGFloat(index * 80 - 200))
            .onAppear {
                let duration = Double(5 + index * 2)
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    offset = 500 // Screen width + padding
                }
            }
    }
}

struct TagIcon: View {
    let icon: String
    let color: Color
    @State private var isAnimating = false
    
    var body: some View {
        Image(systemName: icon)
            .font(.title3)
            .foregroundColor(color)
            .padding(12)
            .background(
                Circle()
                    .fill(.white.opacity(0.2))
            )
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

struct SparkleView: View {
    let index: Int
    @State private var isAnimating = false
    @State private var opacity: Double = 0
    
    private var position: CGPoint {
        let angle = Double(index) * 45
        let radius: CGFloat = 150
        let x = cos(angle * .pi / 180) * radius
        let y = sin(angle * .pi / 180) * radius
        return CGPoint(x: x, y: y)
    }
    
    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 20))
            .foregroundColor(.white)
            .opacity(opacity)
            .scaleEffect(isAnimating ? 1.5 : 0.5)
            .offset(x: position.x, y: position.y)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.2)
                ) {
                    isAnimating = true
                    opacity = 0.8
                }
            }
    }
}

#Preview {
    SplashScreenView {
        print("Splash completed")
    }
}
