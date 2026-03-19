//
//  DataStorageView.swift
//  Travel Buddy
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI
import SwiftData

struct DataStorageView: View {
    @Query private var trips: [Trip]
    @Query private var expenses: [Expense]
    @Query private var buddies: [TravelBuddy]
    @Query private var payments: [Payment]
    @Query private var tripItems: [TripItem]
    
    @State private var animateCards = false
    @State private var selectedStorage: StorageType? = nil
    @State private var showDetails = false
    
    enum StorageType: String, CaseIterable, Identifiable {
        case local = "Local Storage"
        case swiftData = "SwiftData"
        case device = "On Device"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .local: return "internaldrive.fill"
            case .swiftData: return "cylinder.fill"
            case .device: return "iphone"
            }
        }
        
        var color: Color {
            switch self {
            case .local: return .blue
            case .swiftData: return .purple
            case .device: return .green
            }
        }
        
        var gradient: [Color] {
            switch self {
            case .local: return [.blue, .cyan]
            case .swiftData: return [.purple, .pink]
            case .device: return [.green, .mint]
            }
        }
        
        var description: String {
            switch self {
            case .local: return "All data stored locally on your device"
            case .swiftData: return "Apple's modern data persistence framework"
            case .device: return "Never leaves your device - 100% private"
            }
        }
    }
    
    var totalDataSize: String {
        let tripCount = trips.count
        let expenseCount = expenses.count
        let buddyCount = buddies.count
        let estimatedKB = (tripCount * 2) + (expenseCount * 5) + (buddyCount * 1)
        
        if estimatedKB < 1024 {
            return "\(estimatedKB) KB"
        } else {
            let mb = Double(estimatedKB) / 1024.0
            return String(format: "%.2f MB", mb)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.05),
                        Color.purple.opacity(0.05),
                        Color.green.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Hero Section
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .scaleEffect(animateCards ? 1.1 : 0.9)
                                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateCards)
                                
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple, .green],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .blue.opacity(0.3), radius: 15)
                            }
                            .scaleEffect(animateCards ? 1 : 0.5)
                            .opacity(animateCards ? 1 : 0)
                            
                            VStack(spacing: 8) {
                                Text("Your Data is Safe")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                Text("100% stored locally on your device")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 20)
                        }
                        .padding(.top, 20)
                        
                        // Storage Stats Card
                        VStack(spacing: 20) {
                            HStack {
                                Image(systemName: "chart.pie.fill")
                                    .foregroundStyle(.blue)
                                Text("Storage Overview")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 16) {
                                StorageStatRow(
                                    icon: "airplane",
                                    label: "Trips",
                                    count: trips.count,
                                    color: .blue
                                )
                                
                                StorageStatRow(
                                    icon: "receipt.fill",
                                    label: "Expenses",
                                    count: expenses.count,
                                    color: .purple
                                )
                                
                                StorageStatRow(
                                    icon: "person.2.fill",
                                    label: "Travel Buddies",
                                    count: buddies.count,
                                    color: .green
                                )
                                
                                StorageStatRow(
                                    icon: "dollarsign.circle.fill",
                                    label: "Payments",
                                    count: payments.count,
                                    color: .orange
                                )
                                
                                StorageStatRow(
                                    icon: "calendar",
                                    label: "Trip Items",
                                    count: tripItems.count,
                                    color: .pink
                                )
                                
                                Divider()
                                
                                HStack {
                                    Text("Total Storage Used")
                                        .font(.headline)
                                    Spacer()
                                    Text(totalDataSize)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                }
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
                        )
                        .padding(.horizontal)
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 30)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateCards)
                        
                        // Storage Technology Cards
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Storage Technology")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(Array(StorageType.allCases.enumerated()), id: \.element) { index, type in
                                    StorageTechCard(
                                        type: type,
                                        isSelected: selectedStorage == type,
                                        action: {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                selectedStorage = selectedStorage == type ? nil : type
                                            }
                                        }
                                    )
                                    .opacity(animateCards ? 1 : 0)
                                    .offset(x: animateCards ? 0 : -30)
                                    .animation(
                                        .spring(response: 0.6, dampingFraction: 0.8)
                                        .delay(0.3 + Double(index) * 0.1),
                                        value: animateCards
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Security Features
                        VStack(spacing: 20) {
                            HStack {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundStyle(.green)
                                Text("Security Features")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 12) {
                                SecurityFeatureRow(
                                    icon: "lock.fill",
                                    title: "Encrypted Storage",
                                    description: "Protected by iOS encryption"
                                )
                                
                                SecurityFeatureRow(
                                    icon: "eye.slash.fill",
                                    title: "No Tracking",
                                    description: "Zero analytics or data collection"
                                )
                                
                                SecurityFeatureRow(
                                    icon: "icloud.slash.fill",
                                    title: "No Cloud Sync",
                                    description: "Data stays on your device only"
                                )
                                
                                SecurityFeatureRow(
                                    icon: "network.slash",
                                    title: "Offline First",
                                    description: "Works without internet"
                                )
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
                        )
                        .padding(.horizontal)
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 30)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: animateCards)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Data Storage")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animateCards = true
            }
        }
    }
}

// MARK: - Supporting Views

struct StorageStatRow: View {
    let icon: String
    let label: String
    let count: Int
    let color: Color
    
    @State private var animateCount = false
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundStyle(color)
            }
            
            Text(label)
                .font(.body)
            
            Spacer()
            
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .scaleEffect(animateCount ? 1.1 : 1.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.5)) {
                animateCount = true
            }
        }
    }
}

struct StorageTechCard: View {
    let type: DataStorageView.StorageType
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: type.gradient.map { $0.opacity(0.2) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: type.icon)
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: type.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(type.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(type.color)
                        .font(.title3)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: isSelected ? type.color.opacity(0.2) : .black.opacity(0.05), radius: isSelected ? 12 : 6, x: 0, y: isSelected ? 6 : 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? type.color.opacity(0.4) : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
    }
}

struct SecurityFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.05))
        )
    }
}

#Preview {
    DataStorageView()
        .modelContainer(for: [Trip.self, Expense.self, TravelBuddy.self, Payment.self, TripItem.self])
}
