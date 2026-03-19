//
//  LanguageSelectionView.swift
//  Travel Buddy
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI

struct LanguageSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var localization = LocalizationManager.shared
    @State private var selectedLanguage: AppLanguage
    @State private var animateSelection = false
    
    init() {
        _selectedLanguage = State(initialValue: LocalizationManager.shared.currentLanguage)
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Header Section
                Section {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.2), .purple.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: "globe")
                                .font(.system(size: 35))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(spacing: 4) {
                            Text("Choose Your Language")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Text("30 languages available")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                // Language Options
                Section {
                    ForEach(AppLanguage.allCases) { language in
                        LanguageOptionRow(
                            language: language,
                            isSelected: selectedLanguage == language,
                            action: {
                                selectLanguage(language)
                            }
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.06),
                        Color.purple.opacity(0.04),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Language")
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
        }
    }
    
    private func selectLanguage(_ language: AppLanguage) {
        UISelectionFeedbackGenerator().selectionChanged()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            selectedLanguage = language
            localization.currentLanguage = language
        }
        
        // Show success feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

struct LanguageOptionRow: View {
    let language: AppLanguage
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Flag
                Text(language.flag)
                    .font(.system(size: 32))
                
                // Language name
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.rawValue)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(.primary)
                    
                    Text(language.code.uppercased())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            isSelected ? Color.blue.opacity(0.08) : Color(.systemBackground)
        )
    }
}

#Preview {
    LanguageSelectionView()
}
