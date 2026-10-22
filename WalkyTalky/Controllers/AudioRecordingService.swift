//
//  AudioRecordingService.swift
//  WalkyTalky
//
//  Created by Apple Developer on 20/10/2026.
//

import Foundation
import AVFoundation
import Combine

/// Manages the low-level audio recording pipeline using `AVAudioEngine`.
/// Streams real-time audio PCM buffers to the offline speech recognizer, computes
/// live audio levels for smooth waveform visualization, and persists compressed
/// `.m4a` audio files to the sandbox.
@MainActor
public final class AudioRecordingService: ObservableObject {
    
    // MARK: - Published State
    @Published public private(set) var isRecording: Bool = false
    @Published public private(set) var audioLevel: Float = 0.0 // 0.0 (silent) to 1.0 (loud)
    @Published public private(set) var recordingDuration: TimeInterval = 0.0
    @Published public private(set) var activeFileName: String? = nil
    @Published public private(set) var activeFileURL: URL? = nil
    @Published public private(set) var errorMessage: String? = nil
    @Published public private(set) var isMicrophoneAuthorized: Bool = false
    
    // MARK: - Buffer Callback for Speech Recognition
    public var onBufferCaptured: ((AVAudioPCMBuffer) -> Void)?
    
    // MARK: - Audio Engine Components
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var timer: Timer?
    private var startTime: Date?
    
    // MARK: - Initialization
    public init() {
        checkMicrophonePermission()
    }
    
    // MARK: - Permission Handling
    public func requestMicrophonePermission() async -> Bool {
        if #available(iOS 17.0, *) {
            let granted = await AVAudioApplication.requestRecordPermission()
            self.isMicrophoneAuthorized = granted
            return granted
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                    Task { @MainActor in
                        self?.isMicrophoneAuthorized = granted
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }
    
    private func checkMicrophonePermission() {
        if #available(iOS 17.0, *) {
            self.isMicrophoneAuthorized = AVAudioApplication.shared.recordPermission == .granted
        } else {
            self.isMicrophoneAuthorized = AVAudioSession.sharedInstance().recordPermission == .granted
        }
    }
    
    // MARK: - Recording Lifecycle
    /// Starts recording audio to disk and streaming buffers to the speech recognition pipeline.
    /// - Parameter shouldSaveAudioFile: If true, writes compressed .m4a audio to disk; if false, only streams to recognizer.
    public func startRecording(shouldSaveAudioFile: Bool = true) throws {
        _ = stopRecording() // Clean up any active session
        
        guard isMicrophoneAuthorized else {
            throw AudioRecordingError.microphonePermissionDenied
        }
        
        // 1. Configure and activate audio session FIRST to ensure valid sample rate
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .spokenAudio,
                options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP]
            )
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw AudioRecordingError.audioSessionConfigurationFailed(error.localizedDescription)
        }
        
        // 2. Initialize AVAudioEngine
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // Guard against invalid or 0.0 sample rate (can occur in simulator or before hardware initialization)
        let sampleRate = inputFormat.sampleRate > 0 ? inputFormat.sampleRate : 44100.0
        
        // 3. Prepare destination file if needed
        if shouldSaveAudioFile {
            let (fileName, fileURL) = AudioFileManager.shared.createNewRecordingURL()
            self.activeFileName = fileName
            self.activeFileURL = fileURL
            
            // Standard AAC compressed recording settings for crystal-clear voice at tiny file size
            let recordingSettings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: 1, // Mono voice recording
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                AVEncoderBitRateKey: 64000 // 64 kbps mono AAC is optimal for voice
            ]
            
            do {
                self.audioFile = try AVAudioFile(
                    forWriting: fileURL,
                    settings: recordingSettings,
                    commonFormat: .pcmFormatFloat32,
                    interleaved: false
                )
            } catch {
                print("⚠️ [AudioRecordingService] Failed to create audio file, continuing without file save: \(error)")
                self.audioFile = nil
            }
        } else {
            self.activeFileName = nil
            self.activeFileURL = nil
            self.audioFile = nil
        }
        
        // 4. Capture references locally to avoid cross-actor shared mutable access on audio thread
        let localAudioFile = self.audioFile
        let bufferCallback = self.onBufferCaptured
        let bufferSize: AVAudioFrameCount = 1024
        
        inputNode.removeTap(onBus: 0)
        
        let tapFormat = inputFormat.sampleRate > 0 && inputFormat.channelCount > 0 ? inputFormat : nil
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: tapFormat) { [weak self] buffer, time in
            // Thread-safe file writing on audio callback thread
            if let file = localAudioFile {
                do {
                    try file.write(from: buffer)
                } catch {
                    print("⚠️ [AudioRecordingService] Error writing audio buffer: \(error)")
                }
            }
            
            // Forward buffer directly to speech recognition without main thread hop
            bufferCallback?(buffer)
            
            // Calculate RMS level for live waveform animation
            guard let self = self else { return }
            let level = self.calculateRMSLevel(buffer: buffer)
            
            Task { @MainActor in
                self.audioLevel = level
            }
        }
        
        // 5. Prepare and start engine
        do {
            engine.prepare()
            try engine.start()
            self.audioEngine = engine
            self.isRecording = true
            self.startTime = Date()
            self.recordingDuration = 0.0
            self.errorMessage = nil
            startDurationTimer()
        } catch {
            throw AudioRecordingError.engineStartFailed(error.localizedDescription)
        }
    }
    
    /// Stops recording, finalizes the audio file, and tears down the engine.
    /// Returns the saved relative file name and duration.
    public func stopRecording() -> (fileName: String?, fileURL: URL?, duration: TimeInterval) {
        stopDurationTimer()
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        
        audioFile = nil
        isRecording = false
        audioLevel = 0.0
        
        let finalDuration = recordingDuration
        let finalFileName = activeFileName
        let finalFileURL = activeFileURL
        
        // Deactivate audio session to save battery
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        return (finalFileName, finalFileURL, finalDuration)
    }
    
    /// Cancels recording and deletes any audio file created during this session.
    public func cancelRecording() {
        let (fileName, _, _) = stopRecording()
        if let fileName = fileName {
            AudioFileManager.shared.deleteAudioFile(fileName: fileName)
        }
        self.activeFileName = nil
        self.activeFileURL = nil
        self.recordingDuration = 0.0
    }
    
    // MARK: - Duration Timer
    private func startDurationTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTime else { return }
            Task { @MainActor in
                self.recordingDuration = Date().timeIntervalSince(start)
            }
        }
    }
    
    private func stopDurationTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Decibel Level Calculation
    private nonisolated func calculateRMSLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0.0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0.0 }
        
        var sum: Float = 0.0
        for i in 0..<frameLength {
            let sample = channelData[i]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(frameLength))
        
        // Convert RMS to dB: 20 * log10(rms)
        let db = 20 * log10(max(rms, 0.0001))
        
        // Map dB [-50dB, 0dB] to normalized [0.0, 1.0]
        let minDb: Float = -50.0
        let maxDb: Float = 0.0
        let normalized = (db - minDb) / (maxDb - minDb)
        return min(max(normalized, 0.0), 1.0)
    }
    
    /// User-friendly duration string (e.g. "00:14")
    public var formattedDuration: String {
        let total = Int(recordingDuration)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Custom Errors
public enum AudioRecordingError: LocalizedError {
    case microphonePermissionDenied
    case audioSessionConfigurationFailed(String)
    case engineStartFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access has been denied. Please allow microphone access in Settings to dictate notes."
        case .audioSessionConfigurationFailed(let reason):
            return "Failed to configure audio session: \(reason)"
        case .engineStartFailed(let reason):
            return "Failed to start audio recording engine: \(reason)"
        }
    }
}
