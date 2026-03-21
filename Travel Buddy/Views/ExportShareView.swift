//
//  ExportShareView.swift
//  Travel Buddy
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI

struct ExportShareView: View {
    @Environment(\.dismiss) private var dismiss
    var trip: Trip
    
    @State private var selectedOption: ShareOption? = nil
    @State private var shareItem: ShareItem?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var animateCards = false
    @State private var showShareSuccess = false
    
    enum ShareOption: String, CaseIterable, Identifiable {
        case text = "Text Summary"
        case airdrop = "AirDrop"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .text: return "message.fill"
            case .airdrop: return "airplayaudio"
            }
        }
        
        var color: Color {
            switch self {
            case .text: return .pink
            case .airdrop: return .blue
            }
        }
        
        var gradient: [Color] {
            switch self {
            case .text: return [.pink, .orange]
            case .airdrop: return [.blue, .cyan]
            }
        }
        
        var description: String {
            switch self {
            case .text: return "Send trip summary via text or email"
            case .airdrop: return "Share directly with nearby devices"
            }
        }
    }
    
    struct ShareItem: Identifiable {
        let id = UUID()
        let url: URL
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Animated gradient background
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.05),
                        Color.purple.opacity(0.05),
                        Color.pink.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Hero Section
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .scaleEffect(animateCards ? 1.1 : 0.9)
                                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateCards)
                                
                                Image(systemName: "square.and.arrow.up.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple, .pink],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .blue.opacity(0.3), radius: 10)
                            }
                            .scaleEffect(animateCards ? 1 : 0.5)
                            .opacity(animateCards ? 1 : 0)
                            
                            VStack(spacing: 8) {
                                Text("Share Your Trip")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                Text("Let your friends join the adventure")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 20)
                        }
                        .padding(.top, 20)
                        
                        // Share Options Grid
                        VStack(spacing: 16) {
                            ForEach(Array(ShareOption.allCases.enumerated()), id: \.element) { index, option in
                                ShareOptionCard(
                                    option: option,
                                    isSelected: selectedOption == option,
                                    action: {
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            selectedOption = option
                                        }
                                    }
                                )
                                .opacity(animateCards ? 1 : 0)
                                .offset(x: animateCards ? 0 : -50)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.1),
                                    value: animateCards
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Preview Section
                        if let selected = selectedOption {
                            VStack(spacing: 20) {
                                Text("Preview")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                
                                SharePreviewCard(
                                    option: selected,
                                    trip: trip
                                )
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        
                        // Action Button
                        if selectedOption != nil {
                            Button {
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                exportData()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "paperplane.fill")
                                        .font(.title3)
                                    Text("Share Now")
                                        .fontWeight(.bold)
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        colors: selectedOption?.gradient ?? [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                                .shadow(color: (selectedOption?.color ?? .blue).opacity(0.4), radius: 15, x: 0, y: 8)
                            }
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Export & Share")
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
            .sheet(item: $shareItem) { item in
                ShareSheet(items: [item.url])
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if showShareSuccess {
                    ShareSuccessOverlay()
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animateCards = true
            }
        }
    }
    
    private func exportData() {
        do {
            guard let option = selectedOption else { return }
            
            switch option {
            case .text:
                let url = try exportTextSummary()
                shareItem = ShareItem(url: url)
                
            case .airdrop:
                let url = try exportForAirDrop()
                shareItem = ShareItem(url: url)
            }
            
            withAnimation {
                showShareSuccess = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showShareSuccess = false
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func exportForAirDrop() throws -> URL {
        // Create a rich text summary for AirDrop
        var text = "🌍 \(trip.name)\n"
        text += String(repeating: "=", count: 40) + "\n\n"
        text += "📅 Trip Dates\n"
        text += "Start: \(trip.startDate.formatted(date: .long, time: .omitted))\n"
        if let endDate = trip.endDate {
            text += "End: \(endDate.formatted(date: .long, time: .omitted))\n"
        }
        text += "\n"
        
        text += "👥 Travel Buddies (\(trip.travelBuddies.count))\n"
        text += String(repeating: "-", count: 40) + "\n"
        for buddy in trip.travelBuddies {
            let balance = trip.balanceForBuddy(buddy)
            text += "• \(buddy.name): \(trip.currency.format(balance))\n"
        }
        text += "\n"
        
        text += "💰 Expenses Summary\n"
        text += String(repeating: "-", count: 40) + "\n"
        text += "Total Expenses: \(trip.currency.format(trip.totalExpenses))\n"
        text += "Number of Expenses: \(trip.expenses.count)\n"
        if !trip.travelBuddies.isEmpty {
            let perPerson = trip.totalExpenses / Double(trip.travelBuddies.count)
            text += "Average Per Person: \(trip.currency.format(perPerson))\n"
        }
        text += "\n"
        
        if !trip.expenses.isEmpty {
            text += "📝 Expense Details\n"
            text += String(repeating: "-", count: 40) + "\n"
            for expense in trip.expenses.sorted(by: { $0.date > $1.date }) {
                text += "\n\(expense.name)\n"
                text += "  Date: \(expense.date.formatted(date: .abbreviated, time: .omitted))\n"
                text += "  Total: \(trip.currency.format(expense.totalAmount))\n"
                text += "  Per Person: \(trip.currency.format(expense.amountPerPerson()))\n"
                
                let participants = trip.travelBuddies.filter { expense.participantIDs.contains($0.id) }
                if !participants.isEmpty {
                    text += "  Split Between: \(participants.map { $0.name }.joined(separator: ", "))\n"
                }
            }
        }
        
        text += "\n\n" + String(repeating: "=", count: 40)
        text += "\n✨ Shared via Split Voyage App\n"
        
        let fileName = "\(trip.name.replacingOccurrences(of: " ", with: "_"))_TravelBuddy.txt"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try text.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    
    private func exportTextSummary() throws -> URL {
        var text = "🌍 \(trip.name)\n"
        text += "📅 Start Date: \(trip.startDate.formatted(date: .long, time: .omitted))\n\n"
        
        text += "👥 Travel Buddies (\(trip.travelBuddies.count)):\n"
        for buddy in trip.travelBuddies {
            text += "   • \(buddy.name)\n"
        }
        
        text += "\n💰 Expenses (\(trip.expenses.count)):\n"
        text += "Total: \(trip.currency.format(trip.totalExpenses))\n\n"
        
        for expense in trip.expenses.sorted(by: { $0.date > $1.date }) {
            text += "📝 \(expense.name)\n"
            text += "   Amount: \(trip.currency.format(expense.totalAmount))\n"
            text += "   Date: \(expense.date.formatted(date: .abbreviated, time: .omitted))\n"
            text += "   Split: \(trip.currency.format(expense.amountPerPerson())) per person\n\n"
        }
        
        text += "\n💵 Balances:\n"
        for buddy in trip.travelBuddies {
            let balance = trip.balanceForBuddy(buddy)
            text += "   \(buddy.name): \(trip.currency.format(balance))\n"
        }
        
        text += "\n\n✨ Shared via Split Voyage App"
        
        let fileName = "\(trip.name.replacingOccurrences(of: " ", with: "_"))_summary.txt"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try text.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}

// MARK: - Supporting Views

struct ShareOptionCard: View {
    let option: ExportShareView.ShareOption
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var iconRotation: Double = 0
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: option.gradient.map { $0.opacity(0.2) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: option.icon)
                        .font(.system(size: 32))
                        .foregroundStyle(
                            LinearGradient(
                                colors: option.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(iconRotation))
                        .scaleEffect(isPressed ? 1.2 : 1.0)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(option.rawValue)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text(option.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(option.color)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: isSelected ? option.color.opacity(0.3) : .black.opacity(0.1), radius: isSelected ? 15 : 8, x: 0, y: isSelected ? 8 : 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? LinearGradient(
                            colors: option.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom),
                        lineWidth: 2
                    )
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
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                iconRotation = 5
            }
        }
    }
}

struct SharePreviewCard: View {
    let option: ExportShareView.ShareOption
    let trip: Trip
    
    @State private var animatePreview = false
    
    var body: some View {
        VStack(spacing: 20) {
            switch option {
            case .text:
                TextPreview(trip: trip)
            case .airdrop:
                AirDropPreview(trip: trip)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: option.color.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal)
        .scaleEffect(animatePreview ? 1 : 0.9)
        .opacity(animatePreview ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animatePreview = true
            }
        }
    }
}

struct AirDropPreview: View {
    let trip: Trip
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.2), .cyan.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .scaleEffect(pulseAnimation ? 1.1 : 0.9)
                    
                    Image(systemName: "airplayaudio")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Text("AirDrop Share")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(.blue)
                    Text("Rich Text Summary")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("📅")
                        Text("Trip dates and details")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("👥")
                        Text("\(trip.travelBuddies.count) buddies with balances")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("💰")
                        Text("\(trip.expenses.count) expenses breakdown")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.05))
                )
            }
            
            HStack(spacing: 16) {
                ForEach(["iphone", "ipad", "applewatch", "macbook"], id: \.self) { device in
                    Image(systemName: device)
                        .font(.title3)
                        .foregroundStyle(.blue.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            
            Text("Share with nearby Apple devices")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
}

struct TextPreview: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "message.fill")
                    .foregroundStyle(.pink)
                Text("Text Summary")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("🌍")
                    Text(trip.name)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("👥")
                    Text("\(trip.travelBuddies.count) buddies")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("💰")
                    Text("\(trip.expenses.count) expenses")
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                HStack {
                    Text("Total:")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(trip.currency.format(trip.totalExpenses))
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.pink.opacity(0.05))
            )
            
            Text("Formatted summary for messaging")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct PreviewRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}

struct ShareSuccessOverlay: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Text("Ready to Share!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

// UIKit ShareSheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let userID = UserManager.shared.currentUserID
    let trip = Trip(name: "Tokyo Adventure", creatorID: userID)
    let buddy1 = TravelBuddy(name: "Alice")
    let buddy2 = TravelBuddy(name: "Bob")
    trip.travelBuddies = [buddy1, buddy2]
    
    let expense = Expense(name: "Dinner", totalAmount: 120.50, participantIDs: [buddy1.id, buddy2.id])
    trip.expenses = [expense]
    
    return ExportShareView(trip: trip)
}
