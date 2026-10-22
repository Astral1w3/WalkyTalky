//
//  WalkyTalkyApp.swift
//  WalkyTalky
//
//  Created by Angelo Marcone on 19/10/2026.
//

import SwiftUI
import SwiftData

@main
struct WalkyTalkyApp: App {
    /// Shared SwiftData container for persistent on-device storage
    let sharedModelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                WalkThought.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not initialize WalkyTalky SwiftData ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(sharedModelContainer)
    }
}
