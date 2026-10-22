//
//  LocationService.swift
//  WalkyTalky
//
//  Created by Apple Developer on 20/10/2026.
//

import Foundation
import CoreLocation
import Combine

/// Manages CoreLocation updates with support for continuous background tracking
/// during Active Walk sessions. Opportunistically reverse geocodes locations when online
/// and falls back gracefully to raw formatted GPS coordinates when offline.
@MainActor
public final class LocationService: NSObject, ObservableObject {
    
    // MARK: - Published State
    @Published public private(set) var currentLocation: CLLocation?
    @Published public private(set) var currentCoordinate: CLLocationCoordinate2D?
    @Published public private(set) var currentAltitude: Double?
    @Published public private(set) var isTrackingLocation: Bool = false
    @Published public private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published public private(set) var errorMessage: String? = nil
    
    // MARK: - CoreLocation Components
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    // MARK: - Initialization
    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5.0 // Meters before receiving an update
        self.authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Permissions
    public func requestWhenInUsePermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    public func requestAlwaysPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    public var hasLocationPermission: Bool {
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    // MARK: - Tracking Control
    /// Starts background location updates for "Active Walk Mode".
    /// Setting `allowsBackgroundLocationUpdates = true` and `showsBackgroundLocationIndicator = true`
    /// guarantees that iOS will not suspend the app in the background while the user walks.
    public func startBackgroundTracking() {
        guard hasLocationPermission else {
            requestWhenInUsePermission()
            return
        }
        
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        locationManager.startUpdatingLocation()
        self.isTrackingLocation = true
        self.errorMessage = nil
        print("📍 [LocationService] Started continuous background location tracking.")
    }
    
    /// Stops continuous location tracking.
    public func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.showsBackgroundLocationIndicator = false
        self.isTrackingLocation = false
        print("📍 [LocationService] Stopped location tracking.")
    }
    
    // MARK: - Geocoding (Online Opportunistic / Offline Fallback)
    /// Attempts to reverse-geocode a location to a human-readable city/neighborhood.
    /// Returns nil if offline or if reverse-geocoding fails, allowing the caller to
    /// render formatted GPS coordinates as an immediate offline fallback.
    public func reverseGeocode(location: CLLocation) async -> String? {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }
            
            // Format into "City, State" or "Name, City"
            if let locality = placemark.locality, let administrativeArea = placemark.administrativeArea {
                return "\(locality), \(administrativeArea)"
            } else if let name = placemark.name, let locality = placemark.locality {
                return "\(name), \(locality)"
            } else if let locality = placemark.locality {
                return locality
            } else if let name = placemark.name {
                return name
            }
            return nil
        } catch {
            print("⚠️ [LocationService] Reverse geocode failed (offline or network error): \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    nonisolated public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            print("📍 [LocationService] Authorization changed: \(status.rawValue)")
        }
    }
    
    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
            self.currentCoordinate = location.coordinate
            self.currentAltitude = location.altitude
        }
    }
    
    nonisolated public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = error.localizedDescription
            print("⚠️ [LocationService] Location error: \(error.localizedDescription)")
        }
    }
}
