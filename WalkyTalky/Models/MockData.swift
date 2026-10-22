//
//  MockData.swift
//  WalkyTalky
//
//  Created by Apple Developer on 20/10/2026.
//

import Foundation
import SwiftData

/// Provides realistic mock data for SwiftUI previews and offline testing,
/// faithfully matching the prototype cards and layout.
struct MockData {
    
    static var sampleThoughts: [WalkThought] {
        let calendar = Calendar.current
        let now = Date()
        
        let thought1 = WalkThought(
            id: UUID(),
            createdAt: calendar.date(byAdding: .minute, value: -35, to: now) ?? now,
            title: "Title of the Walk",
            bodyText: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. In dignissim sed turpis in mattis. Donec maximus orci vel lorem lobortis fringilla. Quisque nec aliquam risus. Mauris nec odio non eros viverra bibendum non ac mauris. Curabitur a porttitor metus. Mauris feugiat arcu diam, vitae iaculis nulla cursus eu.",
            tags: ["DAJE", "WALK"],
            isFavorite: true,
            audioFileName: nil,
            audioDurationSeconds: 42.0,
            stepCountSnapshot: 1420,
            distanceSnapshotMeters: 1120.0,
            sessionDurationSeconds: 1080.0,
            latitude: 38.5816,
            longitude: -121.4944,
            altitude: 9.0,
            reverseGeocodedPlace: "Sacramento, CA",
            isGeocodePending: false
        )
        
        let thought2 = WalkThought(
            id: UUID(),
            createdAt: calendar.date(byAdding: .hour, value: -2, to: now) ?? now,
            title: "Old Brick Building",
            bodyText: "Walking past the old brick building on 4th street, the warm afternoon light hit the facade just right. Reminded me of the terracotta rooftops in Rome.",
            tags: ["OBSERVATION", "ARCHITECTURE"],
            isFavorite: false,
            audioFileName: nil,
            audioDurationSeconds: 18.0,
            stepCountSnapshot: 840,
            distanceSnapshotMeters: 620.0,
            sessionDurationSeconds: 540.0,
            latitude: 38.5755,
            longitude: -121.4880,
            altitude: 8.5,
            reverseGeocodedPlace: "Sacramento, CA",
            isGeocodePending: false
        )
        
        let thought3 = WalkThought(
            id: UUID(),
            createdAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
            title: "Pacing & Clarity",
            bodyText: "The cadence of walking naturally paces cognition. When walking at 110 steps per minute, sentences flow in full, complete structures without hesitation.",
            tags: ["IDEAS", "REFLECTION"],
            isFavorite: true,
            audioFileName: nil,
            audioDurationSeconds: 30.0,
            stepCountSnapshot: 2150,
            distanceSnapshotMeters: 1680.0,
            sessionDurationSeconds: 1440.0,
            latitude: 38.5680,
            longitude: -121.4910,
            altitude: 10.0,
            reverseGeocodedPlace: "Midtown, Sacramento",
            isGeocodePending: false
        )
        
        let thought4 = WalkThought(
            id: UUID(),
            createdAt: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
            title: "River Trail Breeze",
            bodyText: "Cool delta breeze coming up the Sacramento River. Need to bring a windbreaker next time. The rustle of cottonwoods drowns out highway noise completely.",
            tags: ["NATURE"],
            isFavorite: false,
            audioFileName: nil,
            audioDurationSeconds: 15.0,
            stepCountSnapshot: 3200,
            distanceSnapshotMeters: 2540.0,
            sessionDurationSeconds: 2100.0,
            latitude: 38.5830,
            longitude: -121.5050,
            altitude: 7.0,
            reverseGeocodedPlace: "Sacramento River Trail",
            isGeocodePending: false
        )
        
        return [thought1, thought2, thought3, thought4]
    }
    
    /// Generates an in-memory ModelContainer populated with `sampleThoughts` for SwiftUI Previews.
    @MainActor
    static var previewContainer: ModelContainer = {
        do {
            let schema = Schema([WalkThought.self])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            
            for thought in sampleThoughts {
                container.mainContext.insert(thought)
            }
            try container.mainContext.save()
            return container
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }()
}
