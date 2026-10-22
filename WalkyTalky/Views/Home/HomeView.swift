//
//  HomeView.swift
//  WalkyTalky
//
//  Created by Apple Developer on 20/10/2026.
//

import SwiftUI
import SwiftData

/// The primary command center of Walky Talky.
/// Features a clean feed of walking thoughts, live Active Walk Mode controls,
/// Apple native navigation search (.searchable), and a floating action button for dictating notes.
struct HomeView: View {     
    // MARK: - SwiftData Query
    @Query(sort: \WalkThought.createdAt, order: .reverse) private var allThoughts: [WalkThought]
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State & Managers
    @StateObject private var walkManager = WalkSessionManager()
    @StateObject private var notificationManager = NotificationManager.shared
    
    @State private var searchText: String = ""
    @State private var sortOption: SortOption = .newest
    
    @State private var isDeepLinkActive: Bool = false
    @State private var activeSnapshot: ThoughtSnapshotPayload? = nil
    
    // MARK: - Sort Options
    enum SortOption: String, CaseIterable, Identifiable {
        case newest = "Newest First"
        case oldest = "Oldest First"
        case mostSteps = "Most Steps"
        case longestDistance = "Longest Distance"
        
        var id: String { rawValue }
    }
    
    // MARK: - Filtered Thoughts
    private var filteredThoughts: [WalkThought] {
        var thoughts = allThoughts
        
        // Search filter (searches title, body, and location)
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !trimmedQuery.isEmpty {
            thoughts = thoughts.filter { thought in
                thought.title.lowercased().contains(trimmedQuery) ||
                thought.bodyText.lowercased().contains(trimmedQuery) ||
                (thought.reverseGeocodedPlace?.lowercased().contains(trimmedQuery) ?? false)
            }
        }
        
        // Sorting
        switch sortOption {
        case .newest:
            return thoughts.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            return thoughts.sorted { $0.createdAt < $1.createdAt }
        case .mostSteps:
            return thoughts.sorted { $0.stepCountSnapshot > $1.stepCountSnapshot }
        case .longestDistance:
            return thoughts.sorted { $0.distanceSnapshotMeters > $1.distanceSnapshotMeters }
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // Guaranteed unified background across entire screen
                Theme.Colors.primaryBackground
                    .ignoresSafeArea()
                
                // 1. Scrollable Content Layer
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Layout.standardPadding) {
                        
                        // Subtitle
                        Text("A collection of everything on my mind.")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.secondaryText)
                            .padding(.horizontal, Theme.Layout.standardPadding)
                        
                        // Active Walk Session Banner
                        ActiveWalkBannerView(walkManager: walkManager)
                            .padding(.horizontal, Theme.Layout.standardPadding)
                        
                        // Section Header: Thoughts Count
                        HStack {
                            Text("Thoughts")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Theme.Colors.primaryText)
                            
                            Spacer()
                            
                            if !filteredThoughts.isEmpty {
                                Text("\(filteredThoughts.count) \(filteredThoughts.count == 1 ? "thought" : "thoughts")")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(Theme.Colors.secondaryText)
                            }
                        }
                        .padding(.horizontal, Theme.Layout.standardPadding)
                        .padding(.top, 4)
                        
                        // Thoughts Feed (Single Column, Larger Cards matching tg3)
                        if filteredThoughts.isEmpty {
                            if !searchText.isEmpty {
                                ContentUnavailableView.search(text: searchText)
                                    .padding(.top, 40)
                            } else {
                                emptyStateView
                            }
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredThoughts) { thought in
                                    NavigationLink(value: thought) {
                                        ThoughtCardView(thought: thought)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, Theme.Layout.standardPadding)
                        }
                    }
                    .padding(.top, 4)
                    // Inset so the last thought card can be scrolled comfortably above the floating action button
                    .padding(.bottom, 88)
                }
                
                // 2. Floating Add Thought Button (Terracotta Accent)
                floatingActionButton
            }
            .navigationTitle("My Mind")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search thoughts or places...")
            .toolbar {
                // Top-right Menu: Filter & Sorting options (Apple-style subtle secondary icon)
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section("Sort By") {
                            ForEach(SortOption.allCases) { option in
                                Button {
                                    sortOption = option
                                } label: {
                                    HStack {
                                        Text(option.rawValue)
                                        if sortOption == option {
                                            Image(systemName: Theme.Symbols.checkmark)
                                        }
                                    }
                                }
                            }
                        }
                        
                        if allThoughts.isEmpty {
                            Section {
                                Button("Add Prototype Notes") {
                                    loadPrototypeMockData()
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(Theme.Colors.secondaryText)
                    }
                }
            }
            // Navigate to detail view when a card is selected
            .navigationDestination(for: WalkThought.self) { thought in
                ThoughtDetailView(thought: thought)
            }
            // Deep linking from step notification
            .navigationDestination(isPresented: $isDeepLinkActive) {
                if let snapshot = activeSnapshot {
                    NewNoteFlowView(
                        snapshot: snapshot,
                        onSave: { newThought in
                            modelContext.insert(newThought)
                            isDeepLinkActive = false
                            activeSnapshot = nil
                        }
                    )
                }
            }
            // React to notification deep linking
            .onChange(of: notificationManager.pendingDeepLinkSnapshot) { _, snapshot in
                if let snapshot = snapshot {
                    self.activeSnapshot = snapshot
                    self.isDeepLinkActive = true
                    notificationManager.pendingDeepLinkSnapshot = nil
                }
            }
        }
    }
    
    // MARK: - Floating Add Thought Button (NavigationLink to Dictation Phase)
    private var floatingActionButton: some View {
        NavigationLink {
            NewNoteFlowView(
                snapshot: walkManager.captureCurrentSnapshot(),
                onSave: { newThought in
                    modelContext.insert(newThought)
                }
            )
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 54, height: 54)
                .background(Theme.Colors.accent)
                .clipShape(Circle())
                .shadow(color: Theme.Colors.accent.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .padding(.trailing, Theme.Layout.standardPadding)
        .padding(.bottom, Theme.Layout.standardPadding)
        .accessibilityLabel("New Thought")
    }
    
    // MARK: - Intentional Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.badgeSurface)
                    .frame(width: 60, height: 60)
                
                Image(systemName: "figure.walk.motion")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Theme.Colors.accent)
            }
            .padding(.top, 10)
            
            Text("No Thoughts Yet")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.Colors.primaryText)
            
            Text("Start an active walk above to record your journey, or tap + below to dictate your thoughts.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Button(action: {
                loadPrototypeMockData()
            }) {
                Text("Load Sample Thoughts")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Colors.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.Colors.cardSurface)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Theme.Colors.primaryText.opacity(0.08), lineWidth: 1)
                    )
            }
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(Theme.Colors.cardSurface.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.Colors.primaryText.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal, Theme.Layout.standardPadding)
    }
    
    private func loadPrototypeMockData() {
        for thought in MockData.sampleThoughts {
            modelContext.insert(thought)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .modelContainer(MockData.previewContainer)
    }
}
