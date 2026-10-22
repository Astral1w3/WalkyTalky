//
//  DictationPhaseView.swift
//  WalkyTalky
//
//  Created by Apple Developer on 20/10/2026.
//

import SwiftUI

/// On-device dictation recording screen matching the visual reference (`page2.jpg`).
/// Displays real-time walk metrics, live offline speech-to-text in Karma 600,
/// the signature terracotta "Journaling" capsule, and a responsive bottom ECG waveform.
struct DictationPhaseView: View {
    let snapshot: ThoughtSnapshotPayload
    @ObservedObject var dictationCoordinator: DictationCoordinator
    let onFinish: (DictationCoordinator.DictationResult) -> Void
    let onCancel: () -> Void
    
    // Animation pulse for the recording indicator dot
    @State private var isDotPulsing: Bool = false
    @State private var permissionAlertPresented: Bool = false
    
    var body: some View {
        ZStack {
            // Warm papyrus linen background
            Theme.Colors.primaryBackground
                .ignoresSafeArea()
            
            // Main content layout
            VStack(spacing: 0) {
                Spacer(minLength: 20)
                
                // Center Spoken Thought & Prompt
                centerThoughtSection
                    .padding(.horizontal, 32)
                
                Spacer(minLength: 30)
                
                // "● Journaling" capsule finish button
                journalingActionButton
                    .padding(.bottom, 24)
                
                // Continuous bottom horizontal ECG waveform
                RecordingWaveformView(audioLevel: dictationCoordinator.liveAudioLevel)
                    .padding(.bottom, 12)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    // Invisible balancer ensuring walk metrics remain centered
                    Image(systemName: "mic.fill")
                        .font(.system(size: 17, weight: .medium))
                        .opacity(0)
                        .accessibilityHidden(true)
                    
                    Spacer()
                    
                    // Real-time walk metrics header: "1,420 STEPS · 1.12 KM"
                    Text(WalkFormatter.formatHeaderMetrics(steps: snapshot.stepCount, meters: snapshot.distanceMeters))
                        .font(.system(size: 13, weight: .semibold, design: .default))
                        .tracking(1.4)
                        .foregroundStyle(Theme.Colors.primaryText.opacity(0.85))
                    
                    Spacer()
                    
                    // Pure static indicator icon (not a button, no UIBarButtonItem)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Theme.Colors.terracottaPrompt)
                        .accessibilityLabel("Microphone active")
                }
                .frame(maxWidth: .infinity)
            }
        }
        .task {
            // Automatically launch on-device dictation when the view opens
            do {
                try await dictationCoordinator.startDictation()
            } catch {
                permissionAlertPresented = true
            }
        }
        .onDisappear {
            if dictationCoordinator.isDictating {
                dictationCoordinator.cancelDictation()
            }
        }
        .alert("Dictation Error", isPresented: $permissionAlertPresented) {
            Button("OK", role: .cancel) {
                onCancel()
            }
        } message: {
            Text(dictationCoordinator.errorMessage ?? "Microphone or Speech Recognition unavailable. Please check system permissions in Settings.")
        }
    }
    
    // MARK: - Center Thought Section
    private var centerThoughtSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Quotation mark wrapped spoken text in Karma 600
            let textToShow = dictationCoordinator.currentTranscription.trimmingCharacters(in: .whitespacesAndNewlines)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    if textToShow.isEmpty {
                        Text("“...”")
                            .font(Theme.Typography.karma600(34, relativeTo: .largeTitle))
                            .foregroundStyle(Theme.Colors.primaryText.opacity(0.45))
                            .lineSpacing(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("“\(textToShow)”")
                            .font(Theme.Typography.karma600(34, relativeTo: .largeTitle))
                            .foregroundStyle(Theme.Colors.primaryText)
                            .lineSpacing(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Terracotta guidance prompt
                    Text("Just speak, I'm listening...")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundStyle(Theme.Colors.terracottaPrompt)
                        .padding(.top, 8)
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 380)
        }
    }
    
    // MARK: - Action Button
    private var journalingActionButton: some View {
        Button(action: {
            let result = dictationCoordinator.stopDictation()
            onFinish(result)
        }) {
            HStack(spacing: 10) {
                // Pulsing dot indicator
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isDotPulsing ? 1.3 : 0.8)
                    .opacity(isDotPulsing ? 1.0 : 0.6)
                
                Text("Journaling")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white)
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 14)
            .background(Theme.Colors.accent)
            .clipShape(Capsule())
            .shadow(color: Theme.Colors.accent.opacity(0.35), radius: 10, x: 0, y: 5)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isDotPulsing = true
            }
        }
    }
}

struct DictationPhaseView_Previews: PreviewProvider {
    static var previews: some View {
        DictationPhaseView(
            snapshot: ThoughtSnapshotPayload(
                stepCount: 1420,
                distanceMeters: 1200,
                sessionDurationSeconds: 900,
                latitude: 40.8518,
                longitude: 14.2681,
                locationName: "Old Port"
            ),
            dictationCoordinator: DictationCoordinator(),
            onFinish: { _ in },
            onCancel: { }
        )
    }
}
