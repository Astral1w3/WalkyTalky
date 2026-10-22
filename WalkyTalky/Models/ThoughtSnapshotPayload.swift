//
//  ThoughtSnapshotPayload.swift
//  WalkyTalky
//
//  Created by Apple Developer on 20/10/2026.
//

import Foundation
import CoreLocation

/// Immutable snapshot of physical and spatial walk metrics captured at the
/// exact moment a note is created or when a step milestone notification is fired.
public struct ThoughtSnapshotPayload: Sendable, Hashable {
    public let stepCount: Int
    public let distanceMeters: Double
    public let sessionDurationSeconds: Double
    public let latitude: Double?
    public let longitude: Double?
    public let altitude: Double?
    public let locationName: String?
    public let capturedAt: Date
    
    public init(
        stepCount: Int = 0,
        distanceMeters: Double = 0.0,
        sessionDurationSeconds: Double = 0.0,
        latitude: Double? = nil,
        longitude: Double? = nil,
        altitude: Double? = nil,
        locationName: String? = nil,
        capturedAt: Date = Date()
    ) {
        self.stepCount = stepCount
        self.distanceMeters = distanceMeters
        self.sessionDurationSeconds = sessionDurationSeconds
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.locationName = locationName
        self.capturedAt = capturedAt
    }
    
    // MARK: - Dictionary Serialization for UNNotificationCenter UserInfo
    public var userInfoRepresentation: [String: Any] {
        var dict: [String: Any] = [
            "stepCount": stepCount,
            "distanceMeters": distanceMeters,
            "sessionDurationSeconds": sessionDurationSeconds,
            "capturedAt": capturedAt.timeIntervalSince1970
        ]
        if let lat = latitude { dict["latitude"] = lat }
        if let lon = longitude { dict["longitude"] = lon }
        if let alt = altitude { dict["altitude"] = alt }
        if let name = locationName { dict["locationName"] = name }
        return dict
    }
    
    public init?(userInfo: [AnyHashable: Any]) {
        guard let steps = userInfo["stepCount"] as? Int,
              let distance = userInfo["distanceMeters"] as? Double,
              let duration = userInfo["sessionDurationSeconds"] as? Double else {
            return nil
        }
        
        self.stepCount = steps
        self.distanceMeters = distance
        self.sessionDurationSeconds = duration
        self.latitude = userInfo["latitude"] as? Double
        self.longitude = userInfo["longitude"] as? Double
        self.altitude = userInfo["altitude"] as? Double
        self.locationName = userInfo["locationName"] as? String
        
        if let timestamp = userInfo["capturedAt"] as? TimeInterval {
            self.capturedAt = Date(timeIntervalSince1970: timestamp)
        } else {
            self.capturedAt = Date()
        }
    }
    
    // MARK: - Formatters
    public var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    public var formattedSteps: String {
        return WalkFormatter.formatStepNumber(stepCount)
    }
    
    public var formattedDistance: String {
        return WalkFormatter.formatDistance(meters: distanceMeters)
    }
    
    public var formattedStepsAndDistance: String {
        return WalkFormatter.formatStepsAndDistance(steps: stepCount, meters: distanceMeters)
    }
}
