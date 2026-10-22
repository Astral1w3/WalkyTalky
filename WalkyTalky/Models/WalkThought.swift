//
//  WalkThought.swift
//  WalkyTalky
//
//  Created by Apple Developer on 20/10/2026.
//

import Foundation
import SwiftData
import CoreLocation

/// The persistent SwiftData model representing an individual walking thought or insight.
/// Fully offline, storing text, tags, sensor metrics at time of creation, and references
/// to local sandbox audio files.
@Model
final class WalkThought {
    // MARK: - Unique Identifier
    @Attribute(.unique) var id: UUID
    
    // MARK: - Temporal Metadata
    var createdAt: Date
    var modifiedAt: Date
    
    // MARK: - Content Payload
    var title: String
    var bodyText: String
    var tags: [String]
    var isFavorite: Bool
    
    // MARK: - Local Audio Storage Reference
    var audioFileName: String?        // Relative file name stored in Documents/Recordings/<UUID>.m4a
    var audioDurationSeconds: Double   // Duration of the audio recording in seconds
    
    // MARK: - Sensor Metrics Snapshot at Time of Recording
    var stepCountSnapshot: Int          // Steps taken during the active walk session up to this thought
    var distanceSnapshotMeters: Double  // Distance walked in meters during session up to this thought
    var sessionDurationSeconds: Double  // Elapsed seconds of the walk when this thought was recorded
    
    // MARK: - Spatial Metadata (Offline GPS)
    var latitude: Double?
    var longitude: Double?
    var altitude: Double?
    
    // MARK: - Geocoding Fallback Metadata
    var reverseGeocodedPlace: String?   // Human-readable place (e.g. "Sacramento, CA")
    var isGeocodePending: Bool          // True if captured offline and awaiting geocoding
    
    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        title: String = "",
        bodyText: String = "",
        tags: [String] = [],
        isFavorite: Bool = false,
        audioFileName: String? = nil,
        audioDurationSeconds: Double = 0.0,
        stepCountSnapshot: Int = 0,
        distanceSnapshotMeters: Double = 0.0,
        sessionDurationSeconds: Double = 0.0,
        latitude: Double? = nil,
        longitude: Double? = nil,
        altitude: Double? = nil,
        reverseGeocodedPlace: String? = nil,
        isGeocodePending: Bool = true
    ) {
        self.id = id
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.title = title
        self.bodyText = bodyText
        self.tags = tags
        self.isFavorite = isFavorite
        self.audioFileName = audioFileName
        self.audioDurationSeconds = audioDurationSeconds
        self.stepCountSnapshot = stepCountSnapshot
        self.distanceSnapshotMeters = distanceSnapshotMeters
        self.sessionDurationSeconds = sessionDurationSeconds
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.reverseGeocodedPlace = reverseGeocodedPlace
        self.isGeocodePending = isGeocodePending
    }
}

// MARK: - Computed Properties & Helpers
extension WalkThought {
    /// CLLocationCoordinate2D convenience wrapper
    var coordinate: CLLocationCoordinate2D? {
        guard let latitude = latitude, let longitude = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// True if an associated audio recording exists
    var hasAudio: Bool {
        guard let audioFileName = audioFileName else { return false }
        return !audioFileName.isEmpty
    }
    
    /// Formatted display title with sensible fallback
    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        let bodyTrimmed = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !bodyTrimmed.isEmpty {
            return String(bodyTrimmed.prefix(32)) + (bodyTrimmed.count > 32 ? "…" : "")
        }
        return "Quick Note"
    }
    
    /// User-friendly distance string (e.g. "1.12 km")
    var formattedDistance: String {
        return WalkFormatter.formatDistance(meters: distanceSnapshotMeters)
    }
    
    /// Formatted step counter (e.g. "1,420")
    var formattedSteps: String {
        return WalkFormatter.formatStepNumber(stepCountSnapshot)
    }
    
    /// Formatted timestamp (e.g. "Oct 21 · 9:41 AM")
    var formattedDate: String {
        return WalkFormatter.formatShortDate(createdAt)
    }
    
    /// Full date & time string (e.g. "Wednesday, Oct 21 · 9:41 AM")
    var formattedFullDate: String {
        return WalkFormatter.formatFullDate(createdAt)
    }
    
    /// Formatted GPS coordinates fallback string (e.g. "38.5816° N, 121.4944° W")
    var formattedCoordinates: String? {
        guard let lat = latitude, let lon = longitude else { return nil }
        let latDirection = lat >= 0 ? "N" : "S"
        let lonDirection = lon >= 0 ? "E" : "W"
        return String(format: "%.4f° %@, %.4f° %@", abs(lat), latDirection, abs(lon), lonDirection)
    }
    
    /// Formatted session duration string (e.g. "24m 15s")
    var formattedDuration: String {
        return WalkFormatter.formatDuration(seconds: sessionDurationSeconds)
    }
    
    /// Formatted audio recording duration string (e.g. "0:42")
    var formattedAudioDuration: String {
        return WalkFormatter.formatAudioTimer(seconds: audioDurationSeconds)
    }
}
