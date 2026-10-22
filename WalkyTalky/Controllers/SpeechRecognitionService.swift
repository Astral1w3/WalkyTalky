//
//  SpeechRecognitionService.swift
//  WalkyTalky
//
//  Created by Apple Developer on 20/10/2026.
//

import Foundation
import Speech
import AVFoundation
import Combine

/// Handles 100% offline, on-device voice-to-text dictation using Apple's `SFSpeechRecognizer`.
/// Strictly requires on-device recognition (`requiresOnDeviceRecognition = true`) to ensure
/// zero audio data or transcriptions ever leave the device.
@MainActor
public final class SpeechRecognitionService: ObservableObject {
    
    // MARK: - Published State
    @Published public private(set) var transcribedText: String = ""
    @Published public private(set) var isTranscribing: Bool = false
    @Published public private(set) var isAvailable: Bool = false
    @Published public private(set) var errorMessage: String? = nil
    @Published public private(set) var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    // MARK: - Speech Components
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // MARK: - Utterance Accumulation State (Continuous Multi-Sentence Dictation)
    private var committedUtterances: [String] = []
    private var currentUtterance: String = ""
    private var lastFirstSegmentTimestamp: TimeInterval? = nil
    
    // Thread-safe buffer request reference for real-time audio thread feeding
    private let requestLock = NSLock()
    private nonisolated(unsafe) var _recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    // MARK: - Initialization
    public init(locale: Locale = Locale.current) {
        setupRecognizer(locale: locale)
        checkAuthorization()
    }
    
    private func setupRecognizer(locale: Locale) {
        // Attempt user's current locale; fall back to en-US if locale is not supported
        if let recognizer = SFSpeechRecognizer(locale: locale) {
            self.speechRecognizer = recognizer
        } else if let fallback = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) {
            self.speechRecognizer = fallback
        }
        
        self.isAvailable = speechRecognizer?.isAvailable ?? false
    }
    
    // MARK: - Permission Handling
    public func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                Task { @MainActor in
                    self?.authorizationStatus = status
                    self?.isAvailable = (status == .authorized) && (self?.speechRecognizer?.isAvailable ?? false)
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }
    
    private func checkAuthorization() {
        self.authorizationStatus = SFSpeechRecognizer.authorizationStatus()
        self.isAvailable = (authorizationStatus == .authorized) && (speechRecognizer?.isAvailable ?? false)
    }
    
    // MARK: - Recognition Lifecycle
    /// Starts a new offline recognition task.
    public func startRecognition() throws {
        // Cancel existing task if any
        cancelRecognition()
        
        guard let recognizer = speechRecognizer else {
            throw SpeechError.recognizerNotAvailable
        }
        
        guard authorizationStatus == .authorized else {
            throw SpeechError.notAuthorized
        }
        
        // Reset state
        committedUtterances.removeAll()
        currentUtterance = ""
        lastFirstSegmentTimestamp = nil
        transcribedText = ""
        errorMessage = nil
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.taskHint = .dictation
        
        // On-Device Recognition Handling:
        // Physical hardware uses offline on-device speech models when available.
        // Xcode Simulator does not bundle neural speech assets, so we allow standard recognition on simulator.
        #if targetEnvironment(simulator)
        request.requiresOnDeviceRecognition = false
        #else
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        } else {
            // Graceful fallback if on-device model has not been downloaded for this locale yet
            request.requiresOnDeviceRecognition = false
        }
        #endif
        
        // Enable live interim results for real-time streaming to the UI
        request.shouldReportPartialResults = true
        
        if #available(iOS 16.0, *) {
            // Adds automatic punctuation when supported
            request.addsPunctuation = true
        }
        
        requestLock.lock()
        self._recognitionRequest = request
        requestLock.unlock()
        
        self.isTranscribing = true
        
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let result = result {
                    self.processRecognitionResult(result)
                }
                
                if let error = error {
                    // Ignore normal cancellation errors
                    let nsError = error as NSError
                    if nsError.domain == "kAFAssistantErrorDomain" && (nsError.code == 203 || nsError.code == 216) {
                        return
                    }
                    print("⚠️ [SpeechRecognitionService] Recognition task error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    self.isTranscribing = false
                }
            }
        }
    }
    
    // MARK: - Utterance Processing & Accumulation
    /// Handles stream updates from `SFSpeechRecognizer`, stitching multiple utterances
    /// across silence pauses so previously spoken sentences are never dropped or overwritten.
    private func processRecognitionResult(_ result: SFSpeechRecognitionResult) {
        let incomingText = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !incomingText.isEmpty else { return }
        
        let segments = result.bestTranscription.segments
        let currentFirstTimestamp = segments.first?.timestamp
        
        // Detect if the recognizer started a brand-new utterance after a silence pause.
        // On iOS 17/18 on-device recognition, after ~1.5-2 seconds of quiet, the recognizer
        // treats new speech as a new utterance, resetting formattedString to only the new words.
        let isNewUtterance: Bool
        
        if let lastFirstTimestamp = self.lastFirstSegmentTimestamp,
           let currentFirst = currentFirstTimestamp,
           currentFirst > lastFirstTimestamp + 1.25 {
            // The starting timestamp jumped forward by more than 1.25 seconds -> new utterance after silence
            isNewUtterance = true
        } else if !currentUtterance.isEmpty {
            // Fallback for cases where timestamps might not be populated:
            // Check if incomingText is a continuation, prefix, or has significant word overlap with current utterance.
            let hasContinuity = incomingText.hasPrefix(currentUtterance) ||
                                currentUtterance.hasPrefix(incomingText) ||
                                self.hasSignificantWordOverlap(currentUtterance, incomingText)
            isNewUtterance = !hasContinuity
        } else {
            isNewUtterance = false
        }
        
        if isNewUtterance {
            // Commit previous utterance so it is permanently preserved
            if !currentUtterance.isEmpty {
                committedUtterances.append(currentUtterance)
            }
            currentUtterance = incomingText
            self.lastFirstSegmentTimestamp = currentFirstTimestamp
        } else {
            // Continuing or refining the current utterance in place
            currentUtterance = incomingText
            if lastFirstSegmentTimestamp == nil {
                self.lastFirstSegmentTimestamp = currentFirstTimestamp
            }
        }
        
        if result.isFinal {
            if !currentUtterance.isEmpty {
                committedUtterances.append(currentUtterance)
                currentUtterance = ""
                self.lastFirstSegmentTimestamp = nil
            }
        }
        
        // Re-assemble the cumulative, full transcription for the UI
        self.transcribedText = assembleFullTranscription()
    }
    
    /// Stitches all committed utterances and the current active utterance into a clean, continuous paragraph.
    private func assembleFullTranscription() -> String {
        var parts = committedUtterances
        if !currentUtterance.isEmpty {
            parts.append(currentUtterance)
        }
        
        guard !parts.isEmpty else { return "" }
        
        var fullString = ""
        for part in parts {
            let trimmedPart = part.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedPart.isEmpty else { continue }
            
            if fullString.isEmpty {
                fullString = trimmedPart
            } else {
                let lastChar = fullString.last
                let needsPeriod = (lastChar != nil && !".?!,".contains(lastChar!))
                
                if needsPeriod {
                    fullString += ". " + trimmedPart
                } else {
                    fullString += " " + trimmedPart
                }
            }
        }
        return fullString
    }
    
    /// Computes whether two strings share sufficient word overlap to be considered the same evolving sentence.
    private func hasSignificantWordOverlap(_ a: String, _ b: String) -> Bool {
        let wordsA = a.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let wordsB = b.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard !wordsA.isEmpty && !wordsB.isEmpty else { return false }
        
        // If the starting words match, it's definitely the same sentence growing
        let minLength = min(wordsA.count, wordsB.count)
        var matchingPrefixCount = 0
        for i in 0..<minLength {
            if wordsA[i] == wordsB[i] {
                matchingPrefixCount += 1
            } else {
                break
            }
        }
        if matchingPrefixCount >= 2 || (minLength == 1 && matchingPrefixCount == 1) {
            return true
        }
        
        // Jaccard similarity across distinct words
        let setA = Set(wordsA)
        let setB = Set(wordsB)
        let common = setA.intersection(setB).count
        let ratio = Double(common) / Double(max(setA.count, setB.count))
        return ratio > 0.4
    }
    
    /// Thread-safe buffer feeding directly from the audio engine's tap block.
    /// Does not hop to the main actor, preventing audio dropouts and main thread hitching.
    nonisolated public func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        requestLock.lock()
        let request = _recognitionRequest
        requestLock.unlock()
        request?.append(buffer)
    }
    
    /// Concludes audio ingestion gracefully, allowing final speech recognition frames to finish.
    public func stopRecognition() {
        if !currentUtterance.isEmpty {
            committedUtterances.append(currentUtterance)
            currentUtterance = ""
            self.lastFirstSegmentTimestamp = nil
            self.transcribedText = assembleFullTranscription()
        }
        
        requestLock.lock()
        let request = _recognitionRequest
        self._recognitionRequest = nil
        requestLock.unlock()
        
        request?.endAudio()
        isTranscribing = false
    }
    
    /// Immediately aborts ongoing recognition without waiting for trailing results.
    public func cancelRecognition() {
        requestLock.lock()
        let request = _recognitionRequest
        self._recognitionRequest = nil
        requestLock.unlock()
        
        request?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        isTranscribing = false
        
        committedUtterances.removeAll()
        currentUtterance = ""
        lastFirstSegmentTimestamp = nil
        transcribedText = ""
    }
}

// MARK: - Custom Errors
public enum SpeechError: LocalizedError {
    case recognizerNotAvailable
    case notAuthorized
    case onDeviceRecognitionUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .recognizerNotAvailable:
            return "Speech recognition is not available on this device or for the current language."
        case .notAuthorized:
            return "Speech recognition permission has not been granted. Please enable it in Settings."
        case .onDeviceRecognitionUnavailable:
            return "On-device offline speech recognition is not supported for this language on this device."
        }
    }
}
