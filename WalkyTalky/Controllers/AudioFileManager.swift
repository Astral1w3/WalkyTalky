//
//  AudioFileManager.swift
//  WalkyTalky
//
//  Created by Apple Developer on 20/10/2026.
//

import Foundation
import AVFoundation

/// Robust, sandboxed local file manager responsible for storing, reading,
/// and cleaning up `.m4a` voice recordings. Audio is never stored as raw BLOBs
/// inside SwiftData; only the lightweight relative `fileName` is persisted.
public final class AudioFileManager {
    public static let shared = AudioFileManager()
    
    private let fileManager = FileManager.default
    private let recordingsDirectoryName = "Recordings"
    
    private init() {
        createRecordingsDirectoryIfNeeded()
    }
    
    // MARK: - Directory Resolution
    /// The dedicated directory where all voice notes are saved:
    /// `<Application_Documents>/Recordings/`
    public var recordingsDirectoryURL: URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(recordingsDirectoryName, isDirectory: true)
    }
    
    private func createRecordingsDirectoryIfNeeded() {
        let dirURL = recordingsDirectoryURL
        if !fileManager.fileExists(atPath: dirURL.path) {
            do {
                try fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("❌ [AudioFileManager] Failed to create recordings directory: \(error)")
            }
        }
    }
    
    // MARK: - File Lifecycle
    /// Generates a fresh unique filename and corresponding destination URL for a new recording.
    public func createNewRecordingURL() -> (fileName: String, fileURL: URL) {
        createRecordingsDirectoryIfNeeded()
        let fileName = "\(UUID().uuidString).m4a"
        let destinationURL = recordingsDirectoryURL.appendingPathComponent(fileName)
        return (fileName, destinationURL)
    }
    
    /// Resolves the absolute URL for a given relative filename.
    public func url(for fileName: String) -> URL {
        return recordingsDirectoryURL.appendingPathComponent(fileName)
    }
    
    /// Checks if the audio file exists on disk.
    public func fileExists(fileName: String) -> Bool {
        let path = url(for: fileName).path
        return fileManager.fileExists(atPath: path)
    }
    
    /// Deletes the audio file associated with a deleted WalkThought note.
    public func deleteAudioFile(fileName: String) {
        let fileURL = url(for: fileName)
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        
        do {
            try fileManager.removeItem(at: fileURL)
            print("🗑️ [AudioFileManager] Removed audio file: \(fileName)")
        } catch {
            print("⚠️ [AudioFileManager] Error deleting file \(fileName): \(error)")
        }
    }
    
    /// Returns the exact duration in seconds of a locally saved audio file.
    public func audioDuration(for fileName: String) -> Double {
        let fileURL = url(for: fileName)
        guard fileManager.fileExists(atPath: fileURL.path) else { return 0.0 }
        
        do {
            let player = try AVAudioPlayer(contentsOf: fileURL)
            return player.duration
        } catch {
            let asset = AVURLAsset(url: fileURL)
            return CMTimeGetSeconds(asset.duration)
        }
    }
    
    /// Cleans up any orphaned audio files on disk that no longer have a parent WalkThought in SwiftData.
    public func pruneOrphanedRecordings(validFileNames: Set<String>) {
        do {
            let existingFiles = try fileManager.contentsOfDirectory(atPath: recordingsDirectoryURL.path)
            for file in existingFiles where file.hasSuffix(".m4a") {
                if !validFileNames.contains(file) {
                    deleteAudioFile(fileName: file)
                }
            }
        } catch {
            print("⚠️ [AudioFileManager] Error reading directory for pruning: \(error)")
        }
    }
}
