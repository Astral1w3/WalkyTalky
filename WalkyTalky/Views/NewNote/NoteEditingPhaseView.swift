//
//  NoteEditingPhaseView.swift
//  WalkyTalky
//
//  Created by Apple Developer on 20/10/2026.
//

import SwiftUI
import AVFoundation

/// Review and editing screen presented after on-device dictation concludes.
/// Allows the user to inspect and polish their voice transcription, playback
/// the captured on-device `.m4a` recording, review physical walk metrics,
/// and save the thought to SwiftData.
struct NoteEditingPhaseView: View {
    let snapshot: ThoughtSnapshotPayload
    let initialText: String
    let audioFileName: String?
    let audioDuration: TimeInterval
    
    let onSave: (WalkThought) -> Void
    let onDiscard: () -> Void
    
    // MARK: - State
    @State private var title: String = ""
    @State private var bodyText: String = ""
    
    // Audio Player State
    @State private var keepAudioRecording: Bool = true
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying: Bool = false
    @State private var playbackProgress: Double = 0.0
    @State private var playbackTimer: Timer?
    
    @FocusState private var isFocused: Bool
    
    // MARK: - Initialization
    init(
        snapshot: ThoughtSnapshotPayload,
        initialText: String,
        audioFileName: String?,
        audioDuration: TimeInterval,
        onSave: @escaping (WalkThought) -> Void,
        onDiscard: @escaping () -> Void
    ) {
        self.snapshot = snapshot
        self.initialText = initialText
        self.audioFileName = audioFileName
        self.audioDuration = audioDuration
        self.onSave = onSave
        self.onDiscard = onDiscard
        
        // Auto-generate title from the first sentence or words
        let trimmed = initialText.trimmingCharacters(in: .whitespacesAndNewlines)
        let generatedTitle = Self.extractTitle(from: trimmed)
        _title = State(initialValue: generatedTitle)
        _bodyText = State(initialValue: trimmed)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Walk Metrics Info Strip
                walkMetricsStrip
                
                // Title Field (Unified SF Pro Semibold)
                VStack(alignment: .leading, spacing: 6) {
                    Text("TITLE")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(Theme.Colors.secondaryText)
                    
                    TextField("Thought Title", text: $title)
                        .font(.system(size: 22, weight: .semibold, design: .default))
                        .foregroundStyle(Theme.Colors.primaryText)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(Theme.Colors.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Body Transcription Editor
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("TRANSCRIPTION")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(Theme.Colors.secondaryText)
                        
                        Spacer()
                        
                        Text("100% On-Device")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.Colors.accent)
                    }
                    
                    TextEditor(text: $bodyText)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.primaryText)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 160)
                        .padding(12)
                        .background(Theme.Colors.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Audio Retention & Preview (if audio was recorded)
                if let fileName = audioFileName, !fileName.isEmpty {
                    VStack(spacing: 12) {
                        Toggle(isOn: $keepAudioRecording) {
                            HStack(spacing: 8) {
                                Image(systemName: Theme.Symbols.waveform)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Theme.Colors.accent)
                                Text("Keep audio recording")
                                    .font(Theme.Typography.callout)
                                    .foregroundStyle(Theme.Colors.primaryText)
                            }
                        }
                        .tint(Theme.Colors.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Theme.Colors.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        if keepAudioRecording {
                            audioPlayerSection(fileName: fileName)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Layout.standardPadding)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Theme.Colors.primaryBackground)
        .navigationTitle("Review Thought")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Discard") {
                    stopAudioPlayback()
                    if let fileName = audioFileName {
                        AudioFileManager.shared.deleteAudioFile(fileName: fileName)
                    }
                    onDiscard()
                }
                .foregroundStyle(Theme.Colors.secondaryText)
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveThought()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Colors.accent)
            }
        }
        .onDisappear {
            stopAudioPlayback()
        }
    }
    
    // MARK: - Walk Metrics Strip
    private var walkMetricsStrip: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: Theme.Symbols.steps)
                    .foregroundStyle(Theme.Colors.accent)
                Text(snapshot.formattedSteps)
                    .font(Theme.Typography.subheadline.bold())
                    .foregroundStyle(Theme.Colors.primaryText)
            }
            
            Divider()
                .frame(height: 16)
            
            HStack(spacing: 6) {
                Image(systemName: Theme.Symbols.distance)
                    .foregroundStyle(Theme.Colors.accent)
                Text(snapshot.formattedDistance)
                    .font(Theme.Typography.subheadline.bold())
                    .foregroundStyle(Theme.Colors.primaryText)
            }
            
            if let place = snapshot.locationName, !place.isEmpty {
                Divider()
                    .frame(height: 16)
                
                HStack(spacing: 6) {
                    Image(systemName: Theme.Symbols.location)
                        .foregroundStyle(Theme.Colors.accent)
                    Text(place)
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryText)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.Colors.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Audio Player Section
    private func audioPlayerSection(fileName: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AUDIO RECORDING")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Theme.Colors.secondaryText)
            
            HStack(spacing: 14) {
                // Play / Pause Button
                Button(action: {
                    toggleAudioPlayback(fileName: fileName)
                }) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(width: 44, height: 44)
                        .background(Theme.Colors.accent)
                        .clipShape(Circle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Progress Slider
                    ProgressView(value: playbackProgress, total: 1.0)
                        .tint(Theme.Colors.accent)
                    
                    HStack {
                        let currentSec = (audioPlayer?.currentTime ?? 0.0)
                        Text(formatDuration(currentSec))
                            .font(Theme.Typography.caption2)
                            .foregroundStyle(Theme.Colors.secondaryText)
                        
                        Spacer()
                        
                        Text(formatDuration(audioDuration))
                            .font(Theme.Typography.caption2)
                            .foregroundStyle(Theme.Colors.secondaryText)
                    }
                }
            }
            .padding(14)
            .background(Theme.Colors.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Audio Playback Helpers
    private func toggleAudioPlayback(fileName: String) {
        if isPlaying {
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
            isPlaying = true
            
            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                if let player = audioPlayer {
                    playbackProgress = player.duration > 0 ? player.currentTime / player.duration : 0.0
                    if !player.isPlaying {
                        isPlaying = false
                        playbackProgress = 0.0
                        playbackTimer?.invalidate()
                        playbackTimer = nil
                    }
                }
            }
        } catch {
            print("Playback error: \(error.localizedDescription)")
        }
    }
    
    private func pauseAudio() {
        audioPlayer?.pause()
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func stopAudioPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        playbackProgress = 0.0
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        return WalkFormatter.formatAudioTimer(seconds: seconds)
    }
    
    // MARK: - Save Thought
    private func saveThought() {
        stopAudioPlayback()
        
        // Clean up audio file if user opted out of preserving original recording
        if !keepAudioRecording, let fileName = audioFileName {
            AudioFileManager.shared.deleteAudioFile(fileName: fileName)
        }
        
        let savedAudioFileName = keepAudioRecording ? audioFileName : nil
        let savedAudioDuration = keepAudioRecording ? audioDuration : 0.0
        
        let finalTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Walking Thought"
            : title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let finalBody = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let newThought = WalkThought(
            title: finalTitle,
            bodyText: finalBody,
            audioFileName: savedAudioFileName,
            audioDurationSeconds: savedAudioDuration,
            stepCountSnapshot: snapshot.stepCount,
            distanceSnapshotMeters: snapshot.distanceMeters,
            sessionDurationSeconds: snapshot.sessionDurationSeconds,
            latitude: snapshot.latitude,
            longitude: snapshot.longitude,
            reverseGeocodedPlace: snapshot.locationName
        )
        
        onSave(newThought)
    }
    
    // MARK: - Auto Title Extraction
    private static func extractTitle(from text: String) -> String {
        guard !text.isEmpty else { return "Walking Thought" }
        
        // Take up to the first period, question mark, exclamation point, or newline
        let delimiters = CharacterSet(charactersIn: ".?!\n")
        let components = text.components(separatedBy: delimiters)
        if let first = components.first?.trimmingCharacters(in: .whitespacesAndNewlines), !first.isEmpty {
            // Cap at 45 characters cleanly
            if first.count <= 45 {
                return first
            } else {
                let index = first.index(first.startIndex, offsetBy: 45)
                return String(first[..<index]) + "..."
            }
        }
        
        return "Walking Thought"
    }
}

struct NoteEditingPhaseView_Previews: PreviewProvider {
    static var previews: some View {
        NoteEditingPhaseView(
            snapshot: ThoughtSnapshotPayload(
                stepCount: 1420,
                distanceMeters: 1200,
                sessionDurationSeconds: 900,
                latitude: 40.8518,
                longitude: 14.2681,
                locationName: "Old Port"
            ),
            initialText: "Walking past the old port right now, the breeze is finally cooling things down after a humid morning.",
            audioFileName: "mock.m4a",
            audioDuration: 18.5,
            onSave: { _ in },
            onDiscard: { }
        )
    }
}
