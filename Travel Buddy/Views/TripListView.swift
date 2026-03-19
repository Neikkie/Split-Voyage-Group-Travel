//
//  TripListView.swift
//  Travel Buddy
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI
import SwiftData

struct TripListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]
    @State private var showingAddTrip = false
    @State private var showWelcome = true
    @State private var hasShownWelcome = UserDefaults.standard.bool(forKey: "hasShownWelcome")
    @State private var refreshID = UUID()
    @State private var tripToDelete: Trip?
    @State private var showDeleteConfirmation = false
    @State private var deletingTripID: UUID?
    @State private var showPastTrips = false
    @State private var cardScale: CGFloat = 0.95
    @State private var cardOpacity: Double = 0
    @State private var headerOffset: CGFloat = -50
    
    // Separate active and archived trips
    var activeTrips: [Trip] {
        trips.filter { !$0.isArchived }
    }
    
    var pastTrips: [Trip] {
        trips.filter { $0.isArchived }
    }
    
    var shouldShowEnhancedView: Bool {
        !activeTrips.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Enhanced Animated Background
                EnhancedSingleTripBackground()
                
                if shouldShowEnhancedView {
                    // Enhanced featured view for all trips
                    EnhancedTripsView(trips: activeTrips, showingAddTrip: $showingAddTrip)
                        .scaleEffect(cardScale)
                        .opacity(cardOpacity)
                        .offset(y: headerOffset)
                } else {
                    List {
                        // Active Trips Section
                        if !activeTrips.isEmpty {
                            Section {
                                ForEach(activeTrips) { trip in
                                    NavigationLink(destination: TripDetailView(trip: trip)) {
                                        TripCard(trip: trip)
                                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            deletingTripID = trip.id
                                        }
                                        
                                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            tripToDelete = trip
                                            showDeleteConfirmation = true
                                        }
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: "trash.fill")
                                                .font(.title3)
                                            Text("Delete")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .tint(.red)
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        archiveTrip(trip)
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: "archivebox.fill")
                                                .font(.title3)
                                            Text("Archive")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .tint(.orange)
                                }
                                .opacity(deletingTripID == trip.id ? 0.3 : 1.0)
                                .scaleEffect(deletingTripID == trip.id ? 0.95 : 1.0)
                            }
                        } header: {
                            Text("Active Trips")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                                .textCase(nil)
                        }
                    }
                    
                    // Past Trips Section
                    if !pastTrips.isEmpty {
                        Section {
                            ForEach(pastTrips) { trip in
                                NavigationLink(destination: TripDetailView(trip: trip)) {
                                    TripCard(trip: trip, isPastTrip: true)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            deletingTripID = trip.id
                                        }
                                        
                                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            tripToDelete = trip
                                            showDeleteConfirmation = true
                                        }
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: "trash.fill")
                                                .font(.title3)
                                            Text("Delete")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .tint(.red)
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        unarchiveTrip(trip)
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: "arrow.uturn.backward.circle.fill")
                                                .font(.title3)
                                            Text("Restore")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .tint(.green)
                                }
                                .opacity(deletingTripID == trip.id ? 0.3 : 1.0)
                                .scaleEffect(deletingTripID == trip.id ? 0.95 : 1.0)
                            }
                        } header: {
                            HStack {
                                Image(systemName: "archivebox.fill")
                                    .font(.subheadline)
                                Text("Past Trips")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
                .id(refreshID)
                
                // Floating Add Button (only show when trips exist)
                if !trips.isEmpty {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showingAddTrip = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("New Trip")
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(30)
                        .shadow(color: .blue.opacity(0.4), radius: 15, x: 0, y: 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(shouldShowEnhancedView ? "" : "Trips")
            .navigationBarTitleDisplayMode(shouldShowEnhancedView ? .inline : .large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingAddTrip) {
                AddTripView()
            }
            .onAppear {
                // Force refresh when view appears
                refreshID = UUID()
                
                // Animate enhanced view
                if shouldShowEnhancedView {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                        cardScale = 1.0
                        cardOpacity = 1.0
                        headerOffset = 0
                    }
                }
            }
            .onChange(of: shouldShowEnhancedView) { oldValue, newValue in
                if newValue {
                    // Reset animation state
                    cardScale = 0.95
                    cardOpacity = 0
                    headerOffset = -50
                    
                    // Animate in
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                        cardScale = 1.0
                        cardOpacity = 1.0
                        headerOffset = 0
                    }
                }
            }
            .alert("Delete Trip?", isPresented: $showDeleteConfirmation, presenting: tripToDelete) { trip in
                Button("Cancel", role: .cancel) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        deletingTripID = nil
                    }
                }
                Button("Delete", role: .destructive) {
                    deleteTrip(trip)
                }
            } message: { trip in
                Text("Are you sure you want to delete '\(trip.name)'? This will permanently delete all itinerary items, expenses, and payments associated with this trip.")
            }
            .overlay {
                if trips.isEmpty && hasShownWelcome {
                    EmptyTripsView(showingAddTrip: $showingAddTrip)
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { !hasShownWelcome && showWelcome },
                set: { newValue in
                    showWelcome = newValue
                    if !newValue {
                        hasShownWelcome = true
                        UserDefaults.standard.set(true, forKey: "hasShownWelcome")
                    }
                }
            )) {
                WelcomeView(showWelcome: $showWelcome) {
                    showingAddTrip = true
                }
            }
        }
    }
    
    private func archiveTrip(_ trip: Trip) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            trip.isArchived = true
            
            do {
                try modelContext.save()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                print("Error archiving trip: \(error)")
            }
        }
    }
    
    private func unarchiveTrip(_ trip: Trip) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            trip.isArchived = false
            
            do {
                try modelContext.save()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                print("Error unarchiving trip: \(error)")
            }
        }
    }
    
    private func calculateTotalSpent() -> String {
        var totalsByGroup: [String: Double] = [:]
        
        for trip in trips {
            let currencyCode = trip.currencyCode
            let total = trip.totalExpenses
            totalsByGroup[currencyCode, default: 0] += total
        }
        
        if totalsByGroup.isEmpty {
            return "$0.00"
        }
        
        // Show the primary currency total
        let sorted = totalsByGroup.sorted { $0.value > $1.value }
        if let primary = sorted.first {
            let currency = Currency(rawValue: primary.key) ?? .usd
            return currency.format(primary.value)
        }
        
        return "$0.00"
    }
    
    private func deleteTrip(_ trip: Trip) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            modelContext.delete(trip)
            
            // Explicitly save
            do {
                try modelContext.save()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                
                // Reset animation state
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    deletingTripID = nil
                }
            } catch {
                print("Error deleting trip: \(error)")
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                deletingTripID = nil
            }
        }
    }
    
    private func deleteTrips(at offsets: IndexSet) {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        let currentUserID = UserManager.shared.currentUserID
        for index in offsets {
            let trip = trips[index]
            // Only allow deletion if user is the creator
            if trip.isCreator(userID: currentUserID) {
                modelContext.delete(trip)
            }
        }
    }
}

struct TripSuggestion: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let bgIcon: String
    let emoji: String
    let color: Color
    let gradient: [Color]
}

struct EmptyTripsView: View {
    @Binding var showingAddTrip: Bool
    @State private var animateHeader = false
    @State private var animateCards = false
    @State private var pulseAnimation = false
    
    let tripSuggestions: [TripSuggestion] = [
        TripSuggestion(name: "Beach Getaway", icon: "sun.max.fill", bgIcon: "water.waves", emoji: "🏖️", color: .orange, gradient: [.orange, .yellow]),
        TripSuggestion(name: "Mountain Adventure", icon: "mountain.2.fill", bgIcon: "figure.hiking", emoji: "⛰️", color: .green, gradient: [.green, .teal]),
        TripSuggestion(name: "City Tour", icon: "building.2.fill", bgIcon: "camera.fill", emoji: "🌃", color: .purple, gradient: [.purple, .pink]),
        TripSuggestion(name: "Road Trip", icon: "car.fill", bgIcon: "map.fill", emoji: "🚗", color: .blue, gradient: [.blue, .cyan]),
        TripSuggestion(name: "Island Paradise", icon: "leaf.fill", bgIcon: "figure.pool.swim", emoji: "🏝️", color: .green, gradient: [.mint, .green]),
        TripSuggestion(name: "Ski Resort", icon: "snowflake", bgIcon: "figure.skiing.downhill", emoji: "⛷️", color: .cyan, gradient: [.cyan, .blue])
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Hero Section with Animation
                VStack(spacing: 20) {
                    ZStack {
                        // Animated background circles
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.1), .purple.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 150 + CGFloat(index) * 40, height: 150 + CGFloat(index) * 40)
                                .scaleEffect(pulseAnimation ? 1.1 : 0.9)
                                .animation(
                                    .easeInOut(duration: 2)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.3),
                                    value: pulseAnimation
                                )
                        }
                        
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 80))
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
                    .scaleEffect(animateHeader ? 1.0 : 0.8)
                    .opacity(animateHeader ? 1 : 0)
                    
                    VStack(spacing: 12) {
                        Text("Ready for Adventure?")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)
                        
                        Text("Choose your next destination and start splitting expenses with friends")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .opacity(animateHeader ? 1 : 0)
                    .offset(y: animateHeader ? 0 : 20)
                }
                .padding(.top, 20)
                
                // Interactive Trip Suggestion Cards
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.yellow)
                        Text("Popular Trip Ideas")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .opacity(animateCards ? 1 : 0)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(Array(tripSuggestions.enumerated()), id: \.element.id) { index, suggestion in
                            TripIdeaCard(
                                name: suggestion.name,
                                icon: suggestion.icon,
                                bgIcon: suggestion.bgIcon,
                                emoji: suggestion.emoji,
                                color: suggestion.color,
                                gradient: suggestion.gradient
                            )
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 30)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8)
                                .delay(Double(index) * 0.1),
                                value: animateCards
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // CTA Section
                VStack(spacing: 20) {
                    Button {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        showingAddTrip = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Create Your Trip")
                                .fontWeight(.bold)
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: .blue.opacity(0.4), radius: 15, x: 0, y: 8)
                    }
                    .scaleEffect(animateCards ? 1 : 0.9)
                    .padding(.horizontal, 32)
                    
                    HStack(spacing: 16) {
                        FeatureBadge(icon: "receipt.fill", text: "Track")
                        FeatureBadge(icon: "divide.circle.fill", text: "Split")
                        FeatureBadge(icon: "checkmark.circle.fill", text: "Settle")
                    }
                    .opacity(animateCards ? 1 : 0)
                }
            }
            .padding(.bottom, 32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animateHeader = true
            }
            pulseAnimation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    animateCards = true
                }
            }
        }
    }
}

struct TripIdeaCard: View {
    let name: String
    let icon: String
    let bgIcon: String
    let emoji: String
    let color: Color
    let gradient: [Color]
    
    @State private var animateIcon = false
    @State private var particleOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Animated gradient background
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: gradient.map { $0.opacity(0.15) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Large background icon with animation
                Image(systemName: bgIcon)
                    .font(.system(size: 80))
                    .foregroundStyle(color.opacity(0.1))
                    .rotationEffect(.degrees(animateIcon ? 10 : -10))
                    .offset(x: 20, y: -10)
                    .animation(
                        .easeInOut(duration: 3)
                        .repeatForever(autoreverses: true),
                        value: animateIcon
                    )
                
                // Floating particles
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .offset(
                            x: CGFloat(index * 30 - 30),
                            y: particleOffset + CGFloat(index * 15)
                        )
                        .animation(
                            .easeInOut(duration: 2)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.3),
                            value: particleOffset
                        )
                }
                
                VStack(spacing: 12) {
                    // Emoji
                    Text(emoji)
                        .font(.system(size: 44))
                    
                    // Icon with gradient
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: color.opacity(0.3), radius: 8)
                    
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(.vertical, 20)
        }
        .frame(height: 160)
        .shadow(color: color.opacity(0.2), radius: 10, x: 0, y: 5)
        .onAppear {
            animateIcon = true
            particleOffset = -20
        }
    }
}

struct FeatureBadge: View {
    let icon: String
    let text: String
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(isAnimating ? 1.1 : 1.0)
            
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

struct TripCard: View {
    let trip: Trip
    var isPastTrip: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon and title
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isPastTrip ? 
                                    [.gray.opacity(0.3), .gray.opacity(0.2)] :
                                    [.blue.opacity(0.3), .purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: isPastTrip ? "checkmark.circle.fill" : "airplane")
                        .font(.title3)
                        .foregroundStyle(isPastTrip ? .gray : .blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(trip.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(isPastTrip ? .secondary : .primary)
                        
                        if isPastTrip {
                            Text("COMPLETED")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(.gray)
                                )
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        if let endDate = trip.endDate {
                            Text(formatDateRange(start: trip.startDate, end: endDate))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            // Duration badge with better formatting
                            let duration = calculateDuration(from: trip.startDate, to: endDate)
                            Text(duration == 1 ? "1 day" : "\(duration) days")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
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
                        } else {
                            Text(formatSingleDate(trip.startDate))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Stats
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text("\(trip.travelBuddies.count)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    Text("Buddies")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "receipt.fill")
                            .font(.caption)
                            .foregroundStyle(.purple)
                        Text("\(trip.expenses.count)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    Text("Expenses")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(trip.currency.format(trip.totalExpenses))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("Total")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(isPastTrip ? 0.04 : 0.08), radius: 15, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: isPastTrip ?
                            [.gray.opacity(0.2), .gray.opacity(0.1)] :
                            [.blue.opacity(0.3), .purple.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .opacity(isPastTrip ? 0.85 : 1.0)
    }
    
    private func calculateDuration(from start: Date, to end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: start, to: end)
        return max((components.day ?? 0) + 1, 1)
    }
    
    private func formatDateRange(start: Date, end: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        // Check if both dates are in the same month and year
        let startComponents = calendar.dateComponents([.year, .month, .day], from: start)
        let endComponents = calendar.dateComponents([.year, .month, .day], from: end)
        
        if startComponents.year == endComponents.year && startComponents.month == endComponents.month {
            // Same month: "Mar 12-14, 2026"
            formatter.dateFormat = "MMM d"
            let startDay = formatter.string(from: start)
            let endDay = String(endComponents.day ?? 0)
            
            formatter.dateFormat = "yyyy"
            let year = formatter.string(from: start)
            
            return "\(startDay)-\(endDay), \(year)"
        } else if startComponents.year == endComponents.year {
            // Same year, different months: "Mar 12 - Apr 5, 2026"
            formatter.dateFormat = "MMM d"
            let startStr = formatter.string(from: start)
            let endStr = formatter.string(from: end)
            
            formatter.dateFormat = "yyyy"
            let year = formatter.string(from: start)
            
            return "\(startStr) - \(endStr), \(year)"
        } else {
            // Different years: "Dec 30, 2025 - Jan 5, 2026"
            formatter.dateFormat = "MMM d, yyyy"
            let startStr = formatter.string(from: start)
            let endStr = formatter.string(from: end)
            
            return "\(startStr) - \(endStr)"
        }
    }
    
    private func formatSingleDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Animated Travel Background
struct AnimatedTravelBackground: View {
    @State private var animateGradient = false
    @State private var animateIcons = false
    
    var body: some View {
        ZStack {
            // Base gradient background
            LinearGradient(
                colors: [
                    animateGradient ? Color.blue.opacity(0.15) : Color.purple.opacity(0.15),
                    animateGradient ? Color.purple.opacity(0.1) : Color.pink.opacity(0.1),
                    Color(.systemGroupedBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animateGradient)
            
            // Floating travel icons
            GeometryReader { geometry in
                ForEach(0..<8, id: \.self) { index in
                    FloatingTravelIcon(
                        icon: travelIcons[index % travelIcons.count],
                        geometry: geometry,
                        index: index
                    )
                }
            }
            .opacity(0.08)
        }
        .onAppear {
            animateGradient = true
            animateIcons = true
        }
    }
    
    private let travelIcons = [
        "airplane",
        "suitcase.fill",
        "map.fill",
        "camera.fill",
        "car.fill",
        "ferry.fill",
        "figure.walk",
        "globe.americas.fill"
    ]
}

struct FloatingTravelIcon: View {
    let icon: String
    let geometry: GeometryProxy
    let index: Int
    
    @State private var offsetY: CGFloat = 0
    @State private var offsetX: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 40 + CGFloat(index * 10)))
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue, .purple, .pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .offset(
                x: initialX + offsetX,
                y: initialY + offsetY
            )
            .onAppear {
                startAnimation()
            }
    }
    
    private var initialX: CGFloat {
        let spacing = geometry.size.width / 4
        return CGFloat(index % 4) * spacing + spacing / 2
    }
    
    private var initialY: CGFloat {
        let spacing = geometry.size.height / 3
        return CGFloat(index / 4) * spacing + spacing / 2
    }
    
    private func startAnimation() {
        let duration = Double.random(in: 15...25)
        let delay = Double(index) * 0.5
        
        withAnimation(
            .easeInOut(duration: duration)
            .repeatForever(autoreverses: true)
            .delay(delay)
        ) {
            offsetY = CGFloat.random(in: -100...100)
            offsetX = CGFloat.random(in: -50...50)
            rotation = Double.random(in: -15...15)
            scale = CGFloat.random(in: 0.8...1.2)
        }
    }
}

// MARK: - Enhanced Single Trip Background
struct EnhancedSingleTripBackground: View {
    @State private var animateGradient = false
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Dynamic gradient background
            LinearGradient(
                colors: [
                    animateGradient ? Color.blue.opacity(0.25) : Color.purple.opacity(0.25),
                    animateGradient ? Color.purple.opacity(0.18) : Color.pink.opacity(0.18),
                    animateGradient ? Color.pink.opacity(0.12) : Color.blue.opacity(0.12),
                    Color(.systemGroupedBackground)
                ],
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 12).repeatForever(autoreverses: true), value: animateGradient)
            
            // Animated orbs
            GeometryReader { geometry in
                // Large primary orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(0.3),
                                Color.blue.opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 250
                        )
                    )
                    .frame(width: 500, height: 500)
                    .blur(radius: 60)
                    .offset(x: geometry.size.width * 0.5, y: -150)
                    .rotationEffect(.degrees(rotationAngle))
                    .scaleEffect(pulseScale)
                
                // Secondary orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.purple.opacity(0.25),
                                Color.purple.opacity(0.12),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .blur(radius: 50)
                    .offset(x: -100, y: geometry.size.height * 0.6)
                    .rotationEffect(.degrees(-rotationAngle * 0.6))
                
                // Accent orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.pink.opacity(0.2),
                                Color.pink.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 40)
                    .offset(x: geometry.size.width * 0.7, y: geometry.size.height * 0.7)
                    .rotationEffect(.degrees(rotationAngle * 0.4))
            }
        }
        .onAppear {
            animateGradient = true
            
            withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                pulseScale = 1.2
            }
        }
    }
}

// MARK: - Enhanced Trips View
struct EnhancedTripsView: View {
    let trips: [Trip]
    @Binding var showingAddTrip: Bool
    @State private var glowIntensity: Double = 0.3
    @State private var currentIndex: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<trips.count, id: \.self) { index in
                    Circle()
                        .fill(currentIndex == index ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(currentIndex == index ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: currentIndex)
                }
            }
            .padding(.top, 60)
            .padding(.bottom, 12)
            
            // Horizontal swipeable trips
            TabView(selection: $currentIndex) {
                ForEach(Array(trips.enumerated()), id: \.element.id) { index, trip in
                    TripCardPage(
                        trip: trip,
                        glowIntensity: glowIntensity,
                        showingAddTrip: $showingAddTrip,
                        currentIndex: index,
                        totalTrips: trips.count
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    glowIntensity = 0.6
                }
            }
        }
    }
}

// MARK: - Trip Card Page
struct TripCardPage: View {
    @Environment(\.modelContext) private var modelContext
    let trip: Trip
    let glowIntensity: Double
    @Binding var showingAddTrip: Bool
    let currentIndex: Int
    let totalTrips: Int
    @State private var showDeleteConfirm = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Trip Hero Card
                    TripHeroCard(trip: trip, glowIntensity: glowIntensity)
                        .padding(.top, 20)
                    
                    // Quick Actions
                    VStack(spacing: 12) {
                        NavigationLink(destination: TripDetailView(trip: trip)) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title3)
                                Text("View Trip Details")
                                    .fontWeight(.bold)
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
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        
                        // Delete Trip Button
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showDeleteConfirm = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "trash.fill")
                                    .font(.title3)
                                Text("Delete Trip")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.red.opacity(0.5), lineWidth: 2)
                            )
                        }
                        
                        // Plan Another Trip Button
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showingAddTrip = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                Text("Plan Another Trip")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Trip counter at bottom
                    Text("Trip \(currentIndex + 1) of \(totalTrips)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 20)
                }
            }
        }
        .alert("Delete Trip", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTrip()
            }
        } message: {
            Text("Are you sure you want to delete '\(trip.name)'? This action cannot be undone.")
        }
    }
    
    private func deleteTrip() {
        withAnimation(.easeOut(duration: 0.3)) {
            modelContext.delete(trip)
        }
    }
}

// MARK: - Trip Hero Card
struct TripHeroCard: View {
    let trip: Trip
    let glowIntensity: Double
    
    var body: some View {
        VStack(spacing: 24) {
            // Hero Section
            VStack(spacing: 20) {
                // Animated icon
                ZStack {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 90 + CGFloat(index * 15), height: 90 + CGFloat(index * 15))
                            .scaleEffect(glowIntensity > 0.4 ? 1.05 : 1.0)
                    }
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.25)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)
                    
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .blue.opacity(glowIntensity), radius: 15)
                }
                .padding(.top, 30)
                
                // Trip name
                Text(trip.name)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 20)
                    .lineLimit(2)
                
                // Date badge
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    
                    if let endDate = trip.endDate {
                        Text(formatDateRange(start: trip.startDate, end: endDate))
                    } else {
                        Text(formatSingleDate(trip.startDate))
                    }
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 8)
                )
            }
            
            // Compact Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                CompactStatCard(
                    icon: "person.2.fill",
                    value: "\(trip.travelBuddies.count)",
                    label: "Buddies",
                    color: .blue
                )
                
                CompactStatCard(
                    icon: "receipt.fill",
                    value: "\(trip.expenses.count)",
                    label: "Expenses",
                    color: .purple
                )
                
                CompactStatCard(
                    icon: "dollarsign.circle.fill",
                    value: trip.currency.format(trip.totalExpenses),
                    label: "Total",
                    color: .green
                )
                
                CompactStatCard(
                    icon: "calendar.badge.clock",
                    value: trip.endDate != nil ? "\(calculateDuration(from: trip.startDate, to: trip.endDate!))d" : "∞",
                    label: "Days",
                    color: .orange
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 20)
    }
    
    private func formatDateRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startStr = formatter.string(from: start)
        let endStr = formatter.string(from: end)
        formatter.dateFormat = "yyyy"
        let year = formatter.string(from: start)
        return "\(startStr) - \(endStr), \(year)"
    }
    
    private func formatSingleDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func calculateDuration(from start: Date, to end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: start, to: end)
        return max((components.day ?? 0) + 1, 1)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
            }
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(Double.random(in: 0...0.5))) {
                isAnimating = true
            }
        }
    }
    
    private func formatDateRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startStr = formatter.string(from: start)
        formatter.dateFormat = "d"
        let endDay = formatter.string(from: end)
        return "\(startStr)-\(endDay)"
    }
    
    private func formatSingleDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func calculateDuration(from start: Date, to end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: start, to: end)
        return max((components.day ?? 0) + 1, 1)
    }
}

// MARK: - Compact Stat Card
struct CompactStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Multi Trip Header View
struct MultiTripHeaderView: View {
    let activeCount: Int
    let archivedCount: Int
    let totalSpent: String
    
    @State private var animateHeader = false
    @State private var pulseIcons = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Hero Icon
            ZStack {
                ForEach(0..<2, id: \.self) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.15), .purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90 + CGFloat(index * 20), height: 90 + CGFloat(index * 20))
                        .scaleEffect(pulseIcons ? 1.1 : 1.0)
                }
                
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 45))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(animateHeader ? 5 : -5))
            }
            .padding(.top, 20)
            
            // Title & Subtitle
            VStack(spacing: 8) {
                Text("Your Adventures")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("\(activeCount) active \(activeCount == 1 ? "trip" : "trips")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Quick Stats
            HStack(spacing: 16) {
                QuickStatBadge(
                    icon: "airplane.departure",
                    value: "\(activeCount)",
                    label: "Active",
                    color: .blue
                )
                
                QuickStatBadge(
                    icon: "archivebox.fill",
                    value: "\(archivedCount)",
                    label: "Archived",
                    color: .orange
                )
                
                QuickStatBadge(
                    icon: "dollarsign.circle.fill",
                    value: totalSpent,
                    label: "Total",
                    color: .green
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateHeader = true
                pulseIcons = true
            }
        }
    }
}

// MARK: - Quick Stat Badge
struct QuickStatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    @State private var bounceAnimation = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .scaleEffect(bounceAnimation ? 1.1 : 1.0)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5).repeatForever(autoreverses: true).delay(Double.random(in: 0...0.3))) {
                bounceAnimation = true
            }
        }
    }
}

// MARK: - Compact Trip Card
struct CompactTripCard: View {
    let trip: Trip
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.2), .purple.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: "airplane")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            
            // Trip Info
            VStack(alignment: .leading, spacing: 6) {
                Text(trip.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    // Date
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        if let endDate = trip.endDate {
                            Text(formatCompactDateRange(start: trip.startDate, end: endDate))
                        } else {
                            Text(formatCompactDate(trip.startDate))
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    // Duration badge
                    if let endDate = trip.endDate {
                        Text("\(calculateCompactDuration(from: trip.startDate, to: endDate))d")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
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
                
                // Quick stats
                HStack(spacing: 12) {
                    Label("\(trip.travelBuddies.count)", systemImage: "person.2.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    
                    Label("\(trip.expenses.count)", systemImage: "receipt.fill")
                        .font(.caption2)
                        .foregroundStyle(.purple)
                    
                    Text(trip.currency.format(trip.totalExpenses))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.blue.opacity(0.2), .purple.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    private func formatCompactDateRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startStr = formatter.string(from: start)
        formatter.dateFormat = "d"
        let endDay = formatter.string(from: end)
        return "\(startStr)-\(endDay)"
    }
    
    private func formatCompactDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func calculateCompactDuration(from start: Date, to end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: start, to: end)
        return max((components.day ?? 0) + 1, 1)
    }
}

// MARK: - Swipeable Trip Card
struct SwipeableTripCard: View {
    @Environment(\.modelContext) private var modelContext
    let trip: Trip
    let glowIntensity: Double
    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    @State private var showDeleteConfirm = false
    
    private let deleteThreshold: CGFloat = -100
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete background
            HStack {
                Spacer()
                
                VStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                    
                    Text("Delete")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                .padding(.trailing, 30)
                .frame(height: 200)
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [.red, .red.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .opacity(offset < -20 ? 1 : 0)
            
            // Trip card (same as TripHeroCard)
            NavigationLink(destination: TripDetailView(trip: trip)) {
                TripHeroCard(trip: trip, glowIntensity: glowIntensity)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                    )
            }
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        isDragging = true
                        // Only allow left swipe
                        if gesture.translation.width < 0 {
                            offset = gesture.translation.width
                        }
                    }
                    .onEnded { gesture in
                        isDragging = false
                        
                        if offset < deleteThreshold {
                            // Show delete confirmation
                            showDeleteConfirm = true
                            withAnimation(.spring(response: 0.3)) {
                                offset = 0
                            }
                        } else {
                            // Snap back
                            withAnimation(.spring(response: 0.3)) {
                                offset = 0
                            }
                        }
                    }
            )
        }
        .alert("Delete Trip", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTrip()
            }
        } message: {
            Text("Are you sure you want to delete '\(trip.name)'? This action cannot be undone.")
        }
    }
    
    private func deleteTrip() {
        withAnimation(.easeOut(duration: 0.3)) {
            modelContext.delete(trip)
        }
    }
}
#Preview {
    TripListView()
        .modelContainer(for: [Trip.self, TravelBuddy.self, Expense.self])
}

