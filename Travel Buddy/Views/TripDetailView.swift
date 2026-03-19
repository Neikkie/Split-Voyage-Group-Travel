//
//  TripDetailView.swift
//  Travel Buddy
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI
import SwiftData

struct TripDetailView: View {
    @Environment(\.modelContext) private var modelContext
    var trip: Trip
    
    @State private var showingAddExpense = false
    @State private var showingExportShare = false
    @State private var showingEditTrip = false
    
    var body: some View {
        ZStack {
            // Animated background
            TripDetailBackground()
            
            TabView {
                // Itinerary Tab
                ItineraryView(trip: trip)
                    .tabItem {
                        Label("Itinerary", systemImage: "calendar")
                    }
                
                // Expenses & Buddies Tab
                ExpensesListView(trip: trip, showingAddExpense: $showingAddExpense)
                    .tabItem {
                        Label("Expenses", systemImage: "receipt.fill")
                    }
                
                // Summary & Settlements Tab
                SummaryView(trip: trip)
                    .tabItem {
                        Label("Summary", systemImage: "chart.bar.fill")
                    }
            }
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    // Sync indicator for shared trips
                    if trip.isSharedTrip {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            showingExportShare = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.caption)
                                Text("Sync")
                                    .font(.caption)
                            }
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                    }
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showingEditTrip = true
                    } label: {
                        Label("Edit", systemImage: "pencil.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.blue)
                    }
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showingExportShare = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if trip.isSharedTrip {
                SyncStatusBanner(trip: trip, showingExportShare: $showingExportShare)
            }
        }
        .sheet(isPresented: $showingExportShare) {
            ExportShareView(trip: trip)
        }
        .sheet(isPresented: $showingEditTrip) {
            EditTripView(trip: trip)
        }
    }
}

// Buddies List View
struct BuddiesListView: View {
    @Environment(\.modelContext) private var modelContext
    var trip: Trip
    @Binding var showingAddBuddy: Bool
    @State private var editingBuddy: TravelBuddy?
    
    var isCreator: Bool {
        trip.isCreator(userID: UserManager.shared.currentUserID)
    }
    
    var body: some View {
        ZStack {
            if trip.travelBuddies.isEmpty {
                EmptyStateView(
                    icon: "person.2.fill",
                    title: "No Travel Buddies Yet",
                    message: "Add your friends and family to split expenses and track who's joining you on this adventure!",
                    actionTitle: "Add Travel Buddy",
                    action: {
                        showingAddBuddy = true
                    }
                )
            } else {
                List {
                    ForEach(trip.travelBuddies) { buddy in
                        Button {
                            if isCreator {
                                editingBuddy = buddy
                            }
                        } label: {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue.opacity(0.2), .purple.opacity(0.15)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(.blue)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(buddy.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    
                                    Text(trip.currency.format(trip.balanceForBuddy(buddy)))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if !isCreator {
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteBuddiesIfAllowed)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showingAddBuddy = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 56, height: 56)
                                .foregroundStyle(.blue)
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddBuddy) {
            AddBuddyView(trip: trip)
        }
        .sheet(item: $editingBuddy) { buddy in
            EditBuddyView(buddy: buddy)
        }
    }
    
    private func deleteBuddiesIfAllowed(at offsets: IndexSet) {
        guard isCreator else { return }
        deleteBuddies(at: offsets)
    }
    
    private func deleteBuddies(at offsets: IndexSet) {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        for index in offsets {
            modelContext.delete(trip.travelBuddies[index])
        }
    }
}

// MARK: - Sync Status Banner
struct SyncStatusBanner: View {
    let trip: Trip
    @Binding var showingExportShare: Bool
    
    private var lastSyncText: String {
        if let lastSynced = trip.lastSyncedAt {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Last synced \(formatter.localizedString(for: lastSynced, relativeTo: Date()))"
        } else {
            return "Never synced"
        }
    }
    
    private var hasUnsyncedChanges: Bool {
        guard let lastSynced = trip.lastSyncedAt else { return true }
        return trip.lastModifiedAt > lastSynced
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Sync icon with indicator
            ZStack(alignment: .topTrailing) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.title3)
                    .foregroundStyle(.blue)
                
                if hasUnsyncedChanges {
                    Circle()
                        .fill(.orange)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: -2)
                }
            }
            .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Shared Trip")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 6) {
                    Text(lastSyncText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if hasUnsyncedChanges {
                        HStack(spacing: 2) {
                            Circle()
                                .fill(.orange)
                                .frame(width: 4, height: 4)
                            Text("Unsynced changes")
                        }
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    }
                }
            }
            
            Spacer()
            
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showingExportShare = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "qrcode")
                        .font(.caption)
                    Text("Generate QR")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -2)
        )
    }
}

// MARK: - Trip Detail Background
struct TripDetailBackground: View {
    @State private var animateGradient = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // Base gradient that shifts colors
            LinearGradient(
                colors: [
                    animateGradient ? Color.blue.opacity(0.12) : Color.purple.opacity(0.12),
                    animateGradient ? Color.purple.opacity(0.08) : Color.blue.opacity(0.08),
                    Color(.systemGroupedBackground)
                ],
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: animateGradient)
            
            // Animated geometric shapes
            GeometryReader { geometry in
                // Large rotating circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.06), .purple.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 40)
                    .offset(x: geometry.size.width * 0.7, y: geometry.size.height * 0.1)
                    .rotationEffect(.degrees(rotationAngle))
                
                // Medium circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pink.opacity(0.05), .orange.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                    .offset(x: geometry.size.width * 0.1, y: geometry.size.height * 0.6)
                    .rotationEffect(.degrees(-rotationAngle * 0.7))
                
                // Small accent circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan.opacity(0.07), .blue.opacity(0.04)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 150, height: 150)
                    .blur(radius: 25)
                    .offset(x: geometry.size.width * 0.5, y: geometry.size.height * 0.7)
                    .rotationEffect(.degrees(rotationAngle * 0.5))
            }
            .allowsHitTesting(false)
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            animateGradient = true
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void
    
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Animated icon
            ZStack {
                // Pulsing circles
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
                        .frame(width: 100 + CGFloat(index * 20), height: 100 + CGFloat(index * 20))
                        .scaleEffect(pulseScale)
                        .opacity(1.0 - Double(index) * 0.2)
                }
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.2), .purple.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                    pulseScale = 1.1
                }
            }
            
            // Title and message
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Action button
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                action()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text(actionTitle)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
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
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    let userID = UserManager.shared.currentUserID
    let trip = Trip(name: "Tokyo Adventure", creatorID: userID)
    
    // Add sample itinerary items
    let flight = TripItem.flight(
        airline: "Japan Airlines",
        flightNumber: "JL005",
        departure: "JFK",
        arrival: "NRT",
        departureTime: Date(),
        arrivalTime: Date().addingTimeInterval(14 * 3600),
        cost: 850.00,
        confirmationNumber: "ABC123"
    )
    
    let hotel = TripItem.accommodation(
        name: "Park Hyatt Tokyo",
        address: "3-7-1-2 Nishi Shinjuku",
        checkIn: Date().addingTimeInterval(24 * 3600),
        checkOut: Date().addingTimeInterval(5 * 24 * 3600),
        cost: 450.00,
        confirmationNumber: "HTL456"
    )
    
    let activity = TripItem.activity(
        name: "TeamLab Borderless",
        location: "Odaiba",
        date: Date().addingTimeInterval(2 * 24 * 3600),
        time: Date().addingTimeInterval(2 * 24 * 3600 + 14 * 3600),
        cost: 35.00,
        notes: "Digital art museum"
    )
    
    trip.tripItems = [flight, hotel, activity]
    
    return NavigationStack {
        TripDetailView(trip: trip)
    }
    .modelContainer(for: [Trip.self, TravelBuddy.self, Expense.self, TripItem.self])
}
