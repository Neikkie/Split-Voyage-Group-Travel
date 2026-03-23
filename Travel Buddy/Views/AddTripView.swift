//
//  AddTripView.swift
//  Split Voyage Group Travel
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI
import SwiftData

struct AddTripView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var tripName = ""
    @State private var startDate = Date()
    @State private var endDate: Date?
    @State private var selectedCurrency: Currency = .usd
    @State private var animateHeader = false
    @State private var animateForm = false
    @State private var animateTips = false
    @State private var animateButton = false
    @State private var pulseAnimation = false
    @State private var showCurrencyPicker = false
    @State private var showSuccessOverlay = false
    @State private var particleOffset: CGFloat = 0
    
    private var backgroundGradient: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.08),
                    Color.purple.opacity(0.06),
                    Color.pink.opacity(0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating particles
            GeometryReader { geometry in
                ForEach(0..<12, id: \.self) { index in
                    FloatingParticle(
                        icon: particleIcons[index % particleIcons.count],
                        geometry: geometry,
                        index: index,
                        offset: particleOffset
                    )
                }
            }
            .opacity(0.15)
        }
    }
    
    private let particleIcons = [
        "airplane", "globe.americas.fill", "camera.fill",
        "suitcase.fill", "map.fill", "ticket.fill"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 32) {
                        HeroSection(
                            animateHeader: animateHeader,
                            pulseAnimation: pulseAnimation
                        )
                        .padding(.top, 20)
                
                        // Form Section with Enhanced Design
                        VStack(spacing: 20) {
                            // Trip Name Card
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "text.cursor")
                                        .foregroundStyle(.blue)
                                    Text("Trip Name")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                
                                TextField("e.g., Tokyo Adventure, Beach Trip 2026", text: $tripName)
                                    .font(.body)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(tripName.isEmpty ? Color.gray.opacity(0.2) : Color.blue, lineWidth: tripName.isEmpty ? 1 : 2)
                                    )
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                            )
                            .scaleEffect(animateForm ? 1.0 : 0.95)
                            .opacity(animateForm ? 1 : 0)
                            
                            // Date Card
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(.purple)
                                    Text("Trip Dates")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    if let end = endDate, end != startDate {
                                        Text("\(calculateTripDuration()) days")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [.purple, .pink],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                            )
                                    }
                                }
                                
                                VStack(spacing: 16) {
                                    // Start Date
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.purple.opacity(0.1))
                                                .frame(width: 40, height: 40)
                                            
                                            Image(systemName: "airplane.departure")
                                                .foregroundStyle(.purple)
                                                .symbolEffect(.bounce, value: startDate)
                                        }
                                        
                                        DatePicker("Start Date", selection: $startDate, in: Date()..., displayedComponents: .date)
                                            .font(.body)
                                    }
                                    
                                    Divider()
                                        .overlay(Color.purple.opacity(0.3))
                                    
                                    // End Date (Optional)
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.pink.opacity(0.1))
                                                .frame(width: 40, height: 40)
                                            
                                            Image(systemName: "airplane.arrival")
                                                .foregroundStyle(.pink)
                                                .symbolEffect(.pulse, value: endDate)
                                        }
                                        
                                        DatePicker("End Date (Optional)", selection: Binding(
                                            get: { endDate ?? startDate },
                                            set: { newValue in
                                                endDate = newValue
                                            }
                                        ), in: startDate..., displayedComponents: .date)
                                            .font(.body)
                                    }
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                            )
                            .scaleEffect(animateForm ? 1.0 : 0.95)
                            .opacity(animateForm ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateForm)
                            
                            // Currency Card
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("Currency")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                
                                Button {
                                    UISelectionFeedbackGenerator().selectionChanged()
                                    showCurrencyPicker.toggle()
                                } label: {
                                    HStack {
                                        Text(selectedCurrency.symbol)
                                            .font(.title2)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(selectedCurrency.name)
                                                .font(.body)
                                                .fontWeight(.semibold)
                                            Text(selectedCurrency.rawValue)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.down")
                                            .foregroundStyle(.secondary)
                                            .rotationEffect(.degrees(showCurrencyPicker ? 180 : 0))
                                    }
                                    .foregroundStyle(.primary)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                    )
                                }
                                
                                if showCurrencyPicker {
                                    ScrollView {
                                        VStack(spacing: 8) {
                                            ForEach(Currency.allCases, id: \.self) { currency in
                                                Button {
                                                    UISelectionFeedbackGenerator().selectionChanged()
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                        selectedCurrency = currency
                                                        showCurrencyPicker = false
                                                    }
                                                } label: {
                                                    HStack {
                                                        Text(currency.symbol)
                                                            .font(.title3)
                                                        Text(currency.name)
                                                            .font(.body)
                                                        Spacer()
                                                        if selectedCurrency == currency {
                                                            Image(systemName: "checkmark.circle.fill")
                                                                .foregroundStyle(.green)
                                                        }
                                                    }
                                                    .foregroundStyle(.primary)
                                                    .padding(12)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(selectedCurrency == currency ? Color.green.opacity(0.1) : Color.clear)
                                                    )
                                                }
                                            }
                                        }
                                    }
                                    .frame(maxHeight: 200)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                            )
                            .scaleEffect(animateForm ? 1.0 : 0.95)
                            .opacity(animateForm ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateForm)
                        }
                        .padding(.horizontal, 24)
                        
                        // Quick Tips Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(.yellow)
                                Text("What's Next")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            
                            VStack(spacing: 12) {
                                InteractiveTipCard(
                                    number: "1",
                                    icon: "person.2.fill",
                                    title: "Add Group Members",
                                    description: "Invite friends to your trip",
                                    color: .blue,
                                    isSelected: false,
                                    action: {}
                                )
                                
                                InteractiveTipCard(
                                    number: "2",
                                    icon: "camera.fill",
                                    title: "Scan Receipts",
                                    description: "Add expenses by taking photos",
                                    color: .purple,
                                    isSelected: false,
                                    action: {}
                                )
                                
                                InteractiveTipCard(
                                    number: "3",
                                    icon: "chart.bar.fill",
                                    title: "Track & Settle",
                                    description: "See who owes what in real-time",
                                    color: .green,
                                    isSelected: false,
                                    action: {}
                                )
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
                        )
                        .padding(.horizontal, 24)
                        .opacity(animateTips ? 1 : 0)
                        .offset(y: animateTips ? 0 : 30)
                        
                        // Create Button
                        Button {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            createTrip()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                Text("Create Trip")
                                    .fontWeight(.bold)
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                Group {
                                    if tripName.isEmpty {
                                        LinearGradient(
                                            colors: [.gray, .gray.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    } else {
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    }
                                }
                            )
                            .cornerRadius(20)
                            .shadow(color: tripName.isEmpty ? .clear : .blue.opacity(0.4), radius: 15, x: 0, y: 8)
                        }
                        .disabled(tripName.isEmpty)
                        .padding(.horizontal, 24)
                        .scaleEffect(animateButton ? 1 : 0.9)
                        .opacity(animateButton ? 1 : 0)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .overlay {
                if showSuccessOverlay {
                    SuccessOverlay()
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    animateHeader = true
                }
                pulseAnimation = true
                particleOffset = 500
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        animateForm = true
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        animateTips = true
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        animateButton = true
                    }
                }
            }
        }
    }
    
    private func calculateTripDuration() -> Int {
        guard let end = endDate else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: end)
        return max((components.day ?? 0) + 1, 1) // +1 to include both start and end days
    }
    
    private func createTrip() {
        let currentUserID = UserManager.shared.currentUserID
        let currentUserName = UserManager.shared.currentUserName
        
        let newTrip = Trip(
            name: tripName,
            startDate: startDate,
            endDate: endDate,
            creatorID: currentUserID,
            currency: selectedCurrency
        )
        modelContext.insert(newTrip)
        
        // Automatically add the current user as a buddy
        let currentUserBuddy = TravelBuddy(name: currentUserName, isCurrentUser: true)
        currentUserBuddy.trip = newTrip
        modelContext.insert(currentUserBuddy)
        newTrip.travelBuddies.append(currentUserBuddy)
        
        // Explicitly save the context
        do {
            try modelContext.save()
            
            // Show success animation
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showSuccessOverlay = true
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            // Dismiss after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                dismiss()
            }
        } catch {
            print("Error saving trip: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct HeroSection: View {
    let animateHeader: Bool
    let pulseAnimation: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.15), .purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120 + CGFloat(index) * 30, height: 120 + CGFloat(index) * 30)
                        .scaleEffect(pulseAnimation ? 1.1 : 0.9)
                        .animation(
                            .easeInOut(duration: 2)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: pulseAnimation
                        )
                }
                
                Image(systemName: "airplane.departure.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 20)
                    .rotationEffect(.degrees(animateHeader ? 5 : -5))
                    .animation(
                        .easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                        value: animateHeader
                    )
            }
            .scaleEffect(animateHeader ? 1.0 : 0.5)
            .opacity(animateHeader ? 1 : 0)
            
            VStack(spacing: 12) {
                Text("Create Your Trip")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Begin your adventure with friends")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(animateHeader ? 1 : 0)
            .offset(y: animateHeader ? 0 : 20)
        }
    }
}

struct InteractiveTipCard: View {
    let number: String
    let icon: String
    let title: String
    let description: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Number badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Text(number)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
}

// MARK: - Floating Particle
struct FloatingParticle: View {
    let icon: String
    let geometry: GeometryProxy
    let index: Int
    let offset: CGFloat
    
    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: CGFloat.random(in: 20...40)))
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue, .purple, .pink].shuffled(),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .offset(
                x: geometry.size.width * CGFloat.random(in: 0.1...0.9) + xOffset,
                y: yOffset
            )
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                let randomDelay = Double.random(in: 0...2)
                let duration = Double.random(in: 15...25)
                
                withAnimation(.linear(duration: duration).delay(randomDelay).repeatForever(autoreverses: false)) {
                    yOffset = -geometry.size.height - 100
                }
                
                withAnimation(.easeInOut(duration: 3).delay(randomDelay).repeatForever(autoreverses: true)) {
                    xOffset = CGFloat.random(in: -30...30)
                }
                
                withAnimation(.linear(duration: duration).delay(randomDelay).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                
                withAnimation(.easeIn(duration: 1).delay(randomDelay)) {
                    opacity = Double.random(in: 0.3...0.7)
                }
                
                yOffset = geometry.size.height + 100
            }
    }
}

// MARK: - Success Overlay
struct SuccessOverlay: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var checkmarkScale: CGFloat = 0
    @State private var particlesExpanded = false
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .opacity(opacity)
            
            VStack(spacing: 24) {
                // Success icon with particles
                ZStack {
                    // Expanding circles
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 100, height: 100)
                            .scaleEffect(particlesExpanded ? 2.5 : 1)
                            .opacity(particlesExpanded ? 0 : 1)
                            .animation(
                                .easeOut(duration: 1.2).delay(Double(index) * 0.1),
                                value: particlesExpanded
                            )
                    }
                    
                    // Success circle background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: .green.opacity(0.5), radius: 20)
                    
                    // Checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(checkmarkScale)
                }
                .scaleEffect(scale)
                
                // Success text
                VStack(spacing: 8) {
                    Text("Trip Created!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("Get ready for your adventure")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                checkmarkScale = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.1).delay(0.3)) {
                particlesExpanded = true
            }
        }
    }
}

#Preview {
    AddTripView()
        .modelContainer(for: [Trip.self])
}
