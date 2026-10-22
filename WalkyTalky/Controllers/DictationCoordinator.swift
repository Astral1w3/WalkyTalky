//
//  DictationCoordinator.swift
//  WalkyTalky
//
//  Created by Apple Developer on 20/10/2026.
//

import Foundation
import SwiftUI
import Speech
import AVFoundation
import Combine

/// Central coordinator combining `SpeechRecognitionService` and `AudioRecordingService`.
/// Provides a unified, reactive interface for the New Note Dictation flow, managing
/// offline speech transcription, live decibel metering, and file capture in tandem.
@MainActor
public final class DictationCoordinator: ObservableObject {
    
    // MARK: - Services
    public let speechService: SpeechRecognitionService
    public let audioService: AudioRecordingService
    
    // MARK: - Published State
    @Published public private(set) var isDictating: Bool = false
    @Published public private(set) var currentTranscription: String = ""
    @Published public private(set) var liveAudioLevel: Float = 0.0
    @Published public private(set) var duration: TimeInterval = 0.0
    @Published public private(set) var statusMessage: String = "Ready to record"
    @Published public private(set) var errorMessage: String? = nil
    
    // MARK: - Subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Output Payload
    public struct DictationResult {
        public let text: String
        public let audioFileName: String?
        public let audioDuration: TimeInterval
    }
    
    // MARK: - Initialization
    public init(
        speechService: SpeechRecognitionService? = nil,
        audioService: AudioRecordingService? = nil
    ) {
        let speech = speechService ?? SpeechRecognitionService()
        let audio = audioService ?? AudioRecordingService()
        self.speechService = speech
        self.audioService = audio
        
        // Wire audio buffer streaming from microphone to offline speech recognizer
        self.audioService.onBufferCaptured = { [weak self] buffer in
            self?.speechService.appendAudioBuffer(buffer)
        }
        
        // Forward speech transcription
        self.speechService.$transcribedText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.currentTranscription = text
            }
            .store(in: &cancellables)
            
        // Forward live audio level
        self.audioService.$audioLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.liveAudioLevel = level
            }
            .store(in: &cancellables)
            
        // Forward recording duration
        self.audioService.$recordingDuration
            .receive(on: DispatchQueue.main)
            .sink { [weak self] dur in
                self?.duration = dur
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Permissions
    public var hasRequiredPermissions: Bool {
        return audioService.isMicrophoneAuthorized && speechService.isAvailable
    }
    
    /// Requests both Microphone and Speech Recognition permissions in one coordinated call.
    public func requestPermissions() async -> Bool {
        let micGranted = await audioService.requestMicrophonePermission()
        let speechGranted = await speechService.requestAuthorization()
        return micGranted && speechGranted
    }
    
    // MARK: - Dictation Flow
    /// Begins on-device dictation and audio recording.
    public func startDictation(saveAudioFile: Bool = true) async throws {
        errorMessage = nil
        
        // 1. Ensure permissions
        if !hasRequiredPermissions {
            let granted = await requestPermissions()
            guard granted else {
                let msg = "Microphone or Speech Recognition permissions were not granted."
                errorMessage = msg
                throw SpeechError.notAuthorized
            }
        }
        
        // 2. Start speech recognizer first
        do {
            try speechService.startRecognition()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        // 3. Start audio recording engine & buffer stream
        do {
            try audioService.startRecording(shouldSaveAudioFile: saveAudioFile)
        } catch {
            speechService.cancelRecognition()
            errorMessage = error.localizedDescription
            throw error
        }
        
        self.isDictating = true
        self.statusMessage = "Listening on-device..."
    }
    
    /// Stops dictation, finalizes the transcription and audio file, and returns the result.
    public func stopDictation() -> DictationResult {
        isDictating = false
        statusMessage = "Processing..."
        
        // Conclude audio recording
        let (fileName, _, finalDuration) = audioService.stopRecording()
        
        // Conclude speech recognition
        speechService.stopRecognition()
        let finalText = speechService.transcribedText
        
        statusMessage = "Done"
        return DictationResult(
            text: finalText,
            audioFileName: fileName,
            audioDuration: finalDuration
        )
    }
    
    /// Immediately aborts dictation, discarding any audio files.
    public func cancelDictation() {
        isDictating = false
        statusMessage = "Cancelled"
        audioService.cancelRecording()
        speechService.cancelRecognition()
        currentTranscription = ""
    }
}
