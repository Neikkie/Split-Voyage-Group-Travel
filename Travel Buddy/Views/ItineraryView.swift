//
//  ItineraryView.swift
//  Split Voyage Group Travel
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI
import SwiftData

struct ItineraryView: View {
    @Environment(\.modelContext) private var modelContext
    var trip: Trip
    
    @State private var showingAddItem = false
    @State private var selectedFilter: TripItemType? = nil
    @State private var editingItem: TripItem? = nil
    
    private var isCreator: Bool {
        trip.isCreator(userID: UserManager.shared.currentUserID)
    }
    
    private var canEdit: Bool {
        trip.canEdit(userID: UserManager.shared.currentUserID)
    }
    
    private var filteredItems: [TripItem] {
        let items = trip.tripItems.sorted { $0.startDate < $1.startDate }
        if let filter = selectedFilter {
            return items.filter { $0.type == filter }
        }
        return items
    }
    
    var body: some View {
        ZStack {
            // Subtle gradient background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.03),
                    Color.purple.opacity(0.02),
                    Color.pink.opacity(0.01),
                    Color(.systemGroupedBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            List {
                // Filter section
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(title: "All", isSelected: selectedFilter == nil) {
                                selectedFilter = nil
                            }
                            
                            ForEach(TripItemType.allCases, id: \.self) { type in
                                FilterChip(
                                    title: type.rawValue,
                                    icon: type.icon,
                                    isSelected: selectedFilter == type
                                ) {
                                    selectedFilter = type
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .listRowInsets(EdgeInsets())
                }
                .listRowBackground(Color.clear)
                
                // Trip items grouped by date
                ForEach(groupedByDate(), id: \.key) { dateGroup in
                    Section {
                        ForEach(dateGroup.value) { item in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                editingItem = item
                            } label: {
                                TripItemRow(item: item, trip: trip)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                if canEdit {
                                    Button {
                                        editingItem = item
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                }
                                
                                if trip.canDelete(userID: UserManager.shared.currentUserID) {
                                    Button(role: .destructive) {
                                        if let index = dateGroup.value.firstIndex(where: { $0.id == item.id }) {
                                            deleteItems(at: IndexSet(integer: index), from: dateGroup.value)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete { offsets in
                            deleteItems(at: offsets, from: dateGroup.value)
                        }
                    } header: {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                            Text(dateGroup.key, style: .date)
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    }
                }
            }
            .overlay {
                if trip.tripItems.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.plus",
                        title: "No Itinerary Yet",
                        message: "Start planning your adventure! Add activities, accommodations, and transportation to create your perfect trip.",
                        actionTitle: "Add Itinerary Item",
                        action: {
                            showingAddItem = true
                        }
                    )
                }
            }
            
            // Floating Add Button (when items exist)
            if canEdit && !trip.tripItems.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showingAddItem = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Text("Add Item")
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
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .navigationTitle("Itinerary")
        .toolbar {
            if canEdit {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showingAddItem = true
                    } label: {
                        Label("Add Item", systemImage: "plus.circle.fill")
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            BannerViewContainer(bannerAdType: .itienaryViewAd)
                .frame(height: 60)
                .background(Color(.systemBackground))
        }
        .sheet(isPresented: $showingAddItem) {
            AddTripItemView(trip: trip)
        }
        .sheet(item: $editingItem) { item in
            EditTripItemView(item: item, trip: trip)
        }
    }
    
    private func groupedByDate() -> [(key: Date, value: [TripItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredItems) { item in
            calendar.startOfDay(for: item.startDate)
        }
        return grouped.sorted { $0.key < $1.key }
    }
    
    private func deleteItems(at offsets: IndexSet, from items: [TripItem]) {
        guard trip.canDelete(userID: UserManager.shared.currentUserID) else { return }
        
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        
        for index in offsets {
            if let tripIndex = trip.tripItems.firstIndex(where: { $0.id == items[index].id }) {
                let item = trip.tripItems[tripIndex]
                
                // Delete linked expense and all its splits
                // First check if there's a direct link
                if let linkedExpense = item.linkedExpense {
                    // Delete all expense splits first
                    for split in linkedExpense.splits {
                        modelContext.delete(split)
                    }
                    
                    // Remove from trip's expenses array
                    if let expenseIndex = trip.expenses.firstIndex(where: { $0.id == linkedExpense.id }) {
                        trip.expenses.remove(at: expenseIndex)
                    }
                    
                    // Delete the expense
                    modelContext.delete(linkedExpense)
                } else if item.cost > 0 {
                    // Fallback: Find expense that links back to this item OR matches by name/cost
                    if let matchingExpense = trip.expenses.first(where: { expense in
                        // Check if expense links back to this item
                        (expense.sourceItineraryItem?.id == item.id) ||
                        // Or match by name and cost (for old expenses without proper linking)
                        (expense.name == item.name && abs(expense.totalAmount - item.cost) < 0.01)
                    }) {
                        // Delete all expense splits first
                        for split in matchingExpense.splits {
                            modelContext.delete(split)
                        }
                        
                        // Remove from trip's expenses array
                        if let expenseIndex = trip.expenses.firstIndex(where: { $0.id == matchingExpense.id }) {
                            trip.expenses.remove(at: expenseIndex)
                        }
                        
                        // Delete the expense
                        modelContext.delete(matchingExpense)
                    }
                }
                
                // Remove itinerary item from trip's array
                trip.tripItems.remove(at: tripIndex)
                
                // Delete the itinerary item
                modelContext.delete(item)
            }
        }
        
        // Save the context to persist all changes
        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            print("Error deleting itinerary item: \(error)")
        }
    }
}

struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                        .symbolEffect(.bounce, value: isSelected)
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        LinearGradient(
                            colors: [Color(.systemGray5), Color(.systemGray5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .cornerRadius(20)
            .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.3)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3)) {
                        isPressed = false
                    }
                }
        )
    }
}

struct TripItemRow: View {
    let item: TripItem
    let trip: Trip
    
    @State private var isPressed = false
    @State private var iconScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 16) {
            // Animated Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [iconColor.opacity(0.2), iconColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .scaleEffect(iconScale)
                
                Image(systemName: item.type.icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                    .scaleEffect(iconScale)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    iconScale = 1.05
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 6) {
                    if !timeString.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text(timeString)
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                    
                    if !item.location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption2)
                            Text(item.location)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                
                if item.cost > 0 {
                    HStack(spacing: 6) {
                        Text(trip.currency.format(item.cost))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        if item.isPaid {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                Text("Paid")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.green.opacity(0.1))
                            )
                        }
                    }
                }
            }
            
            Spacer()
            
            if !item.confirmationNumber.isEmpty {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            }
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
                        colors: [iconColor.opacity(0.3), iconColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
    }
    
    private var iconColor: Color {
        switch item.type {
        case .accommodation: return .blue
        case .transportation: return .green
        case .flight: return .purple
        case .activity: return .orange
        case .restaurant: return .red
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        switch item.type {
        case .flight:
            if let dep = item.departureTime, let arr = item.arrivalTime {
                return "\(formatter.string(from: dep)) - \(formatter.string(from: arr))"
            }
        case .accommodation:
            if let checkIn = item.checkInTime {
                return formatter.string(from: checkIn)
            }
        case .restaurant, .activity:
            if let resTime = item.reservationTime {
                return formatter.string(from: resTime)
            }
        default:
            break
        }
        
        return formatter.string(from: item.startDate)
    }
}

struct TripItemDetailView: View {
    let item: TripItem
    let trip: Trip
    @State private var showingEditItem = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Image(systemName: item.type.icon)
                        .font(.system(size: 50))
                        .foregroundStyle(iconColor.gradient)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.type.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(item.name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                .padding()
                
                // Details based on type
                VStack(alignment: .leading, spacing: 16) {
                    switch item.type {
                    case .flight:
                        flightDetails
                    case .accommodation:
                        accommodationDetails
                    case .transportation:
                        transportationDetails
                    case .activity:
                        activityDetails
                    case .restaurant:
                        restaurantDetails
                    }
                    
                    if item.cost > 0 {
                        DetailRow(label: "Cost", value: trip.currency.format(item.cost))
                        DetailRow(label: "Payment Status", value: item.isPaid ? "Paid ✓" : "Pending")
                    }
                    
                    if !item.confirmationNumber.isEmpty {
                        DetailRow(label: "Confirmation #", value: item.confirmationNumber)
                    }
                    
                    if !item.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            Text(item.notes)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showingEditItem = true
                } label: {
                    Label("Edit", systemImage: "pencil.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.blue)
                }
            }
        }
        .sheet(isPresented: $showingEditItem) {
            EditTripItemView(item: item, trip: trip)
        }
    }
    
    private var iconColor: Color {
        switch item.type {
        case .accommodation: return .blue
        case .transportation: return .green
        case .flight: return .purple
        case .activity: return .orange
        case .restaurant: return .red
        }
    }
    
    private var flightDetails: some View {
        Group {
            DetailRow(label: "Airline", value: item.airline)
            DetailRow(label: "Flight Number", value: item.flightNumber)
            DetailRow(label: "From", value: item.departureAirport)
            DetailRow(label: "To", value: item.arrivalAirport)
            if let dep = item.departureTime {
                DetailRow(label: "Departure", value: dep, style: .dateTime)
            }
            if let arr = item.arrivalTime {
                DetailRow(label: "Arrival", value: arr, style: .dateTime)
            }
        }
    }
    
    private var accommodationDetails: some View {
        Group {
            DetailRow(label: "Address", value: item.address)
            if let checkIn = item.checkInTime {
                DetailRow(label: "Check-in", value: checkIn, style: .dateTime)
            }
            if let checkOut = item.checkOutTime {
                DetailRow(label: "Check-out", value: checkOut, style: .dateTime)
            }
        }
    }
    
    private var transportationDetails: some View {
        Group {
            DetailRow(label: "Location", value: item.location)
            DetailRow(label: "Pickup", value: item.startDate, style: .dateTime)
            if let endDate = item.endDate {
                DetailRow(label: "Return", value: endDate, style: .dateTime)
            }
        }
    }
    
    private var activityDetails: some View {
        Group {
            DetailRow(label: "Location", value: item.location)
            DetailRow(label: "Date", value: item.startDate, style: .date)
            if let time = item.reservationTime {
                DetailRow(label: "Time", value: time, style: .time)
            }
            if !item.website.isEmpty {
                DetailRow(label: "Website", value: item.website)
            }
        }
    }
    
    private var restaurantDetails: some View {
        Group {
            DetailRow(label: "Address", value: item.location)
            if let resTime = item.reservationTime {
                DetailRow(label: "Reservation", value: resTime, style: .dateTime)
            }
            if !item.phoneNumber.isEmpty {
                DetailRow(label: "Phone", value: item.phoneNumber)
            }
            if !item.website.isEmpty {
                DetailRow(label: "Website", value: item.website)
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    init(label: String, value: String) {
        self.label = label
        self.value = value
    }
    
    init(label: String, value: Date, style: DateFormatter.Style) {
        self.label = label
        let formatter = DateFormatter()
        
        switch style {
        case .date:
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
        case .time:
            formatter.dateStyle = .none
            formatter.timeStyle = .short
        case .dateTime:
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
        default:
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
        }
        
        self.value = formatter.string(from: value)
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

extension DateFormatter.Style {
    static let dateTime: DateFormatter.Style = .medium
    static let date: DateFormatter.Style = .medium
    static let time: DateFormatter.Style = .short
}

#Preview {
    let userID = UserManager.shared.currentUserID
    let trip = Trip(name: "Tokyo Adventure", creatorID: userID)
    
    // Create sample itinerary items
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
        address: "3-7-1-2 Nishi Shinjuku, Shinjuku-ku",
        checkIn: Date().addingTimeInterval(24 * 3600),
        checkOut: Date().addingTimeInterval(5 * 24 * 3600),
        cost: 450.00,
        confirmationNumber: "HTL456"
    )
    
    let activity1 = TripItem.activity(
        name: "Senso-ji Temple Visit",
        location: "Asakusa",
        date: Date().addingTimeInterval(2 * 24 * 3600),
        time: Date().addingTimeInterval(2 * 24 * 3600 + 10 * 3600),
        cost: 0,
        notes: "Traditional Buddhist temple"
    )
    
    let activity2 = TripItem.activity(
        name: "TeamLab Borderless",
        location: "Odaiba",
        date: Date().addingTimeInterval(3 * 24 * 3600),
        time: Date().addingTimeInterval(3 * 24 * 3600 + 14 * 3600),
        cost: 35.00,
        notes: "Digital art museum"
    )
    activity2.website = "borderless.teamlab.art"
    
    let restaurant = TripItem.restaurant(
        name: "Sukiyabashi Jiro",
        location: "Ginza",
        reservationTime: Date().addingTimeInterval(3 * 24 * 3600 + 19 * 3600),
        phoneNumber: "+81-3-3535-3600",
        cost: 300.00
    )
    restaurant.confirmationNumber = "SUSHI789"
    
    let transportation = TripItem(
        type: .transportation,
        name: "JR Pass (7-Day)",
        startDate: Date().addingTimeInterval(24 * 3600),
        endDate: Date().addingTimeInterval(7 * 24 * 3600),
        location: "All JR Lines",
        cost: 280.00,
        confirmationNumber: "JRPASS001"
    )
    
    // Quick save item (minimal info)
    let quickSave = TripItem.activity(
        name: "New Activity",
        location: "",
        date: Date().addingTimeInterval(4 * 24 * 3600),
        time: Date(),
        cost: 0,
        notes: ""
    )
    
    trip.tripItems = [flight, hotel, activity1, activity2, restaurant, transportation, quickSave]
    
    return NavigationStack {
        ItineraryView(trip: trip)
    }
    .modelContainer(for: [Trip.self, TripItem.self])
}
