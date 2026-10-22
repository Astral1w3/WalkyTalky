//
//  MiniMapSnapshotView.swift
//  WalkyTalky
//
//  Created by Apple Developer on 20/10/2026.
//

import SwiftUI
import MapKit

/// Compact map snippet for note cards and detail view. Displays a clean, non-interactive map
/// centered on the note's GPS coordinates with a custom terracotta pin.
/// Includes an overlay badge with geocoded place or coordinates, and an offline fallback.
struct MiniMapSnapshotView: View {
    let coordinate: CLLocationCoordinate2D?
    let placeName: String?
    var isPending: Bool = false
    
    var body: some View {
        if let coordinate = coordinate {
            ZStack(alignment: .bottomLeading) {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                ))) {
                    Marker("", coordinate: coordinate)
                        .tint(Theme.Colors.accent)
                }
                .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
                .disabled(true)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                // Location / Geocode Status Overlay Capsule
                HStack(spacing: 6) {
                    Image(systemName: Theme.Symbols.location)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.Colors.accent)
                    
                    if let place = placeName, !place.isEmpty {
                        Text(place)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.Colors.primaryText)
                            .lineLimit(1)
                    } else if isPending {
                        Text("Location pending resolution...")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(Theme.Colors.secondaryText)
                            .lineLimit(1)
                    } else {
                        Text(String(format: "%.4f°, %.4f°", coordinate.latitude, coordinate.longitude))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.Colors.secondaryText)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(10)
            }
        } else {
            // Offline or no-GPS fallback placeholder
            HStack(spacing: 8) {
                Image(systemName: Theme.Symbols.location)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.secondaryText)
                
                Text(placeName ?? "Offline GPS Snapshot (Coordinates unavailable)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Theme.Colors.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

struct MiniMapSnapshotView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            MiniMapSnapshotView(
                coordinate: CLLocationCoordinate2D(latitude: 38.5816, longitude: -121.4944),
                placeName: "Sacramento, CA",
                isPending: false
            )
            
            MiniMapSnapshotView(
                coordinate: CLLocationCoordinate2D(latitude: 38.5816, longitude: -121.4944),
                placeName: nil,
                isPending: true
            )
        }
        .padding()
        .background(Theme.Colors.primaryBackground)
    }
}
