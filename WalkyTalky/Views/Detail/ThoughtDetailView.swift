//
//  ThoughtDetailView.swift
//  WalkyTalky
//
//  Created by Apple Developer on 21/10/2026.
//

import SwiftUI
import SwiftData
import AVFoundation
import MapKit

/// Full inspection and editing view for an individual walking thought.
/// Displays native Apple typography, embedded physical walk metrics,
/// local `.m4a` audio playback with scrubber controls, offline map visualization, and in-place note editing.
struct ThoughtDetailView: View {
    @Bindable var thought: WalkThought
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var isEditing: Bool = false
    @State private var editedTitle: String = ""
    @State private var editedBody: String = ""
    @State private var showDeleteConfirmation: Bool = false
    
    // Audio Player State
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlayingAudio: Bool = false
    @State private var audioProgress: Double = 0.0
    @State private var isScrubbing: Bool = false
    @State private var playbackTimer: Timer?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Timestamp & Geocoded Place Header
                headerMetadataView
                
                // Tag Pills (if tags assigned)
                if !thought.tags.isEmpty {
                    tagChipsView
                }
                
                // Note Title
                if isEditing {
                    TextField("Title", text: $editedTitle)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Theme.Colors.primaryText)
                        .padding(12)
                        .background(Theme.Colors.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Text(thought.displayTitle)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Theme.Colors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Physical Walk Metrics Strip
                walkMetricsStrip
                
                // Audio Player Card (if note has recorded audio)
                if thought.hasAudio, let fileName = thought.audioFileName {
                    audioPlaybackSection(fileName: fileName)
                }
                
                // Note Body Text
                if isEditing {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NOTE CONTENT")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(Theme.Colors.secondaryText)
                        
                        TextEditor(text: $editedBody)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.primaryText)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 180)
                            .padding(12)
                            .background(Theme.Colors.cardSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(thought.bodyText)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.primaryText)
                            .lineSpacing(6)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Theme.Colors.cardSurface.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                // Spatial Location & Map
                if thought.latitude != nil && thought.longitude != nil {
                    locationSection
                }
            }
            .padding(.horizontal, Theme.Layout.standardPadding)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(Theme.Colors.primaryBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                // Native ShareLink
                ShareLink(
                    item: sharePayloadText,
                    subject: Text(thought.displayTitle),
                    message: Text(thought.bodyText)
                ) {
                    Image(systemName: Theme.Symbols.share)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.Colors.accent)
                }
                
                // Edit / Done toggle
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        saveEdits()
                    } else {
                        beginEditing()
                    }
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.Colors.accent)
                
                // Delete button
                Button(role: .destructive, action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: Theme.Symbols.trash)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.red.opacity(0.85))
                }
            }
        }
        .confirmationDialog(
            "Delete this thought?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Thought", role: .destructive) {
                deleteThought()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently remove this thought and its local audio recording from your device.")
        }
        .onDisappear {
            stopAudioPlayback()
        }
    }
    
    // MARK: - Header Metadata
    private var headerMetadataView: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.secondaryText)
            
            Text(thought.formattedFullDate)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.secondaryText)
            
            if let place = thought.reverseGeocodedPlace, !place.isEmpty {
                Text("•")
                    .foregroundStyle(Theme.Colors.secondaryText)
                
                Image(systemName: Theme.Symbols.location)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Colors.accent)
                
                Text(place)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
                    .lineLimit(1)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Tag Badges
    private var tagChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(thought.tags, id: \.self) { tag in
                    Text(tag.hasPrefix("#") ? tag : "#\(tag)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.Colors.secondaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.Colors.badgeSurface)
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    // MARK: - Walk Metrics Strip
    private var walkMetricsStrip: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: Theme.Symbols.steps)
                    .foregroundStyle(Theme.Colors.accent)
                VStack(alignment: .leading, spacing: 1) {
                    Text(thought.formattedSteps)
                        .font(Theme.Typography.subheadline.bold())
                        .foregroundStyle(Theme.Colors.primaryText)
                    Text("STEPS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
            }
            
            Divider()
                .frame(height: 24)
            
            HStack(spacing: 6) {
                Image(systemName: Theme.Symbols.distance)
                    .foregroundStyle(Theme.Colors.accent)
                VStack(alignment: .leading, spacing: 1) {
                    Text(thought.formattedDistance)
                        .font(Theme.Typography.subheadline.bold())
                        .foregroundStyle(Theme.Colors.primaryText)
                    Text("DISTANCE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
            }
            
            if thought.sessionDurationSeconds > 0 {
                Divider()
                    .frame(height: 24)
                
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .foregroundStyle(Theme.Colors.accent)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(thought.formattedDuration)
                            .font(Theme.Typography.subheadline.bold())
                            .foregroundStyle(Theme.Colors.primaryText)
                        Text("WALK TIME")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Theme.Colors.secondaryText)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.Colors.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    // MARK: - Audio Playback Section
    private func audioPlaybackSection(fileName: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("YOUR THOUGHTS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.Colors.secondaryText)
                
                Spacer()
                
                Text(thought.formattedAudioDuration)
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            
            HStack(spacing: 14) {
                // Play / Pause Button
                Button(action: {
                    toggleAudioPlayback(fileName: fileName)
                }) {
                    Image(systemName: isPlayingAudio ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(width: 44, height: 44)
                        .background(Theme.Colors.accent)
                        .clipShape(Circle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Interactive Scrubber Slider
                    Slider(
                        value: $audioProgress,
                        in: 0.0...1.0,
                        onEditingChanged: { editing in
                            isScrubbing = editing
                            if !editing, let player = audioPlayer {
                                player.currentTime = audioProgress * player.duration
                            }
                        }
                    )
                    .tint(Theme.Colors.accent)
                    
                    HStack {
                        let currentSec = isScrubbing
                            ? (audioPlayer?.duration ?? 0.0) * audioProgress
                            : (audioPlayer?.currentTime ?? 0.0)
                        Text(formatTime(currentSec))
                            .font(Theme.Typography.caption2)
                            .foregroundStyle(Theme.Colors.secondaryText)
                        
                        Spacer()
                        
                        Text(thought.formattedAudioDuration)
                            .font(Theme.Typography.caption2)
                            .foregroundStyle(Theme.Colors.secondaryText)
                    }
                }
            }
            .padding(14)
            .background(Theme.Colors.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("LOCATION")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.Colors.secondaryText)
                
                Spacer()
                
                if let coords = thought.formattedCoordinates {
                    Text(coords)
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
            }
            
            MiniMapSnapshotView(
                coordinate: thought.coordinate,
                placeName: thought.reverseGeocodedPlace,
                isPending: thought.isGeocodePending
            )
        }
    }
    
    // MARK: - Edit Handlers
    private func beginEditing() {
        editedTitle = thought.title
        editedBody = thought.bodyText
        isEditing = true
    }
    
    private func saveEdits() {
        thought.title = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        thought.bodyText = editedBody.trimmingCharacters(in: .whitespacesAndNewlines)
        thought.modifiedAt = Date()
        isEditing = false
    }
    
    // MARK: - Delete Handler
    private func deleteThought() {
        stopAudioPlayback()
        if let fileName = thought.audioFileName {
            AudioFileManager.shared.deleteAudioFile(fileName: fileName)
        }
        modelContext.delete(thought)
        dismiss()
    }
    
    // MARK: - Audio Playback Helpers
    private func toggleAudioPlayback(fileName: String) {
        if isPlayingAudio {
            pauseAudio()
        } else {
            playAudio(fileName: fileName)
        }
    }
    
    private func playAudio(fileName: String) {
        guard AudioFileManager.shared.fileExists(fileName: fileName) else { return }
        let url = AudioFileManager.shared.url(for: fileName)
        
        do {
            if audioPlayer == nil {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                audioPlayer = try AVAudioPlayer(contentsOf: url)
            }
            
            audioPlayer?.play()
            isPlayingAudio = true
            
            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                if let player = audioPlayer, !isScrubbing {
                    audioProgress = player.duration > 0 ? player.currentTime / player.duration : 0.0
                    if !player.isPlaying {
                        isPlayingAudio = false
                        audioProgress = 0.0
                        playbackTimer?.invalidate()
                        playbackTimer = nil
                    }
                }
            }
        } catch {
            print("Audio playback failed: \(error.localizedDescription)")
        }
    }
    
    private func pauseAudio() {
        audioPlayer?.pause()
        isPlayingAudio = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func stopAudioPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlayingAudio = false
        audioProgress = 0.0
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        return WalkFormatter.formatAudioTimer(seconds: seconds)
    }
    
    private var sharePayloadText: String {
        """
        “\(thought.displayTitle)”
        
        \(thought.bodyText)
        
        🚶‍♂️ \(WalkFormatter.formatStepsAndDistance(steps: thought.stepCountSnapshot, meters: thought.distanceSnapshotMeters))
        📅 \(thought.formattedFullDate)
        """
    }
}

struct ThoughtDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ThoughtDetailView(thought: MockData.sampleThoughts[0])
                .modelContainer(MockData.previewContainer)
        }
    }
}
