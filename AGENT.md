# AGENT.md: Architectural & Design Source of Truth for "Walky Talky"

> **Status:** Final Architectural Specification  
> **App Name:** Walky Talky  
> **Platform:** iOS 17.0+ (Swift 5.10 / Swift 6, SwiftUI)  
> **Target Devices:** iPhone (Optimized for Dynamic Island, Notch, and Home Indicator layouts)  
> **Design Philosophy:** 100% Native Apple HIG, Decoupled Design System, 100% Offline-First, Privacy-Preserving  

---

## 1. Project Overview & Offline Constraints

### 1.1 Product Vision
**Walky Talky** is an introspective, voice-first walking companion for iOS. Designed around the rhythm of solitary walking, it empowers users to capture spoken thoughts, stream-of-consciousness ideas, and perceptual notes on the move. The app pairs each recorded thought with real-time physical metrics—step counts, distance traveled, timestamps, and GPS coordinates—creating a rich sensory record of both mental and physical journeys.

### 1.2 The 100% Offline-First Paradigm
The core technical and philosophical mandate of Walky Talky is **absolute local privacy and zero network dependency**:
* **No Cloud Authentication or User Accounts:** There are no login screens, registration forms, user accounts, analytics trackers, or remote servers. All data belongs strictly to the device.
* **On-Device Speech Recognition:** Transcription is executed entirely on-device via Apple's `SFSpeechRecognizer` with `requiresOnDeviceRecognition = true`. Audio never leaves the handset.
* **Local Persistence:** All thought metadata, metric snapshots, tags, and spatial coordinates are stored in a local `SwiftData` store. Audio recordings are stored in the app sandbox's `Application Support` or `Documents` directory.
* **Resilient Offline Mapping & Geocoding:** The app gracefully handles offline states. Map views render locally cached tiles or display clear geometric/coordinate fallbacks. Reverse geocoding (`CLGeocoder`) is performed opportunistically: when offline, raw GPS coordinates are rendered immediately, and reverse-geocoding requests are queued for when network availability is restored.
* **No Standalone Map Tab, Saved Tab, or Profile View:** Prototypes featuring superfluous tabs or profile screens are deprecated. The UI is strictly streamlined into a focused 3-view navigation hierarchy.

---

## 2. Design System & Extracted Color Palette

The visual identity of Walky Talky is extracted directly from the high-fidelity prototype (featuring the natural sage card surfaces, deep evergreen accents, and warm mineral paper backgrounds). It evokes a calm, organic, outdoor aesthetic reminiscent of a physical field journal or trail notebook.

### 2.1 Extracted Color Palette (Prototypes Reference)

| Semantic Role | Hex Code | Visual Tone | HIG / Contrast Notes |
|---|---|---|---|
| **Primary Background** (`primaryBackground`) | `#F5F5F3` | Warm Mineral Off-White / Natural Stone | Replaces sterile pure white `#FFFFFF` with a natural, paper-like warm substrate. High contrast against dark text. |
| **Card Surface** (`cardSurface`) | `#D5D9D1` | Muted Lichen / Soft Sage Gray | Card container background. Gives tangible tactile elevation without drop-shadow clutter. |
| **Accent Evergreen** (`accentColor`) | `#162E14` | Deep Forest Pine / Evergreen | Used for primary action buttons (Dictation FAB, active tab indicators, primary button fills). High contrast against light surfaces. |
| **Badge Surface (Light)** (`badgeSurface`) | `#D4D9CE` | Pale Sage Tint | Capsule badge background for tags, step pills, and status tags. |
| **Badge Surface (Dark)** (`badgeDarkSurface`) | `#395238` | Deep Moss Green | Contrast badge fill for active walk indicator or highlighted tags. |
| **Primary Text** (`primaryText`) | `#112120` | Deep Pine Charcoal | Main headlines, note body text, metrics values. WCAG AAA compliance on `#F5F5F3`. |
| **Secondary Text** (`secondaryText`) | `#707973` | Earthy Slate Gray | Subtitles, timestamps, distance units, metadata labels. |
| **Search Bar Surface** (`searchBarSurface`) | `#EAECE8` | Soft Neutral Field | Native search background blending organically with the view substrate. |
| **Destructive / Alert** (`destructiveColor`) | `#B33A3A` | Earthy Terracotta Red | Discard actions, stop walk confirmation, deletion. |

#### Dark Mode Equivalents
To ensure full native HIG compliance, `Theme.swift` provides adaptive dynamic tokens:
* `primaryBackground`: `#121513` (Deep Earth Slate)
* `cardSurface`: `#1C221E` (Muted Pine Slate)
* `accentColor`: `#4E8A52` (Vibrant Foliage Green)
* `primaryText`: `#F2F4F1` (Pale Stone)
* `secondaryText`: `#9BA49C` (Muted Lichen)
* `searchBarSurface`: `#1E2520` (Dark Olive Surface)

---

### 2.2 Decoupled Theme System (`Theme.swift`)

All colors, typographic scales, spacing units, and corner radii must be defined in a centralized `Theme.swift` file. No hardcoded hex values, arbitrary paddings, or raw font names are permitted in SwiftUI view files.

```swift
// Theme.swift
import SwiftUI

public enum Theme {
    public enum Colors {
        public static let primaryBackground = Color("PrimaryBackground", bundle: .main)
        public static let cardSurface = Color("CardSurface", bundle: .main)
        public static let accent = Color("AccentColor", bundle: .main)
        public static let badgeSurface = Color("BadgeSurface", bundle: .main)
        public static let badgeDarkSurface = Color("BadgeDarkSurface", bundle: .main)
        public static let primaryText = Color("PrimaryText", bundle: .main)
        public static let secondaryText = Color("SecondaryText", bundle: .main)
        public static let searchBarSurface = Color("SearchBarSurface", bundle: .main)
        public static let destructive = Color("DestructiveColor", bundle: .main)
        
        // Direct Fallbacks for programmatic initialization
        public static let fallbackBackground = Color(hex: "#F5F5F3")
        public static let fallbackCard = Color(hex: "#D5D9D1")
        public static let fallbackAccent = Color(hex: "#162E14")
        public static let fallbackText = Color(hex: "#112120")
        public static let fallbackSecondary = Color(hex: "#707973")
    }
    
    public enum Typography {
        public static let largeTitle = Font.system(.largeTitle, design: .serif, weight: .bold)
        public static let title = Font.system(.title, design: .serif, weight: .semibold)
        public static let title2 = Font.system(.title2, design: .default, weight: .semibold)
        public static let headline = Font.system(.headline, design: .default, weight: .medium)
        public static let body = Font.system(.body, design: .default, weight: .regular)
        public static let callout = Font.system(.callout, design: .default, weight: .regular)
        public static let subheadline = Font.system(.subheadline, design: .default, weight: .regular)
        public static let footnote = Font.system(.footnote, design: .default, weight: .regular)
        public static let caption = Font.system(.caption, design: .default, weight: .medium)
        public static let metricNumber = Font.system(.title3, design: .rounded, weight: .bold)
    }
    
    public enum Layout {
        public static let standardPadding: CGFloat = 16.0
        public static let cardPadding: CGFloat = 14.0
        public static let cardCornerRadius: CGFloat = 20.0
        public static let badgeCornerRadius: CGFloat = 10.0
        public static let buttonCornerRadius: CGFloat = 28.0
        public static let gridSpacing: CGFloat = 12.0
    }
}

// Color hex helper
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var int: UInt64 = 0
        scanner.scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

---

## 3. Technical Stack & iOS Permissions

### 3.1 Framework Architecture

| Domain | Apple Framework | Role in Walky Talky |
|---|---|---|
| **UI & Navigation** | `SwiftUI`, `MapKit` | Modern declarative interface, `NavigationStack`, sheets, `.searchable`, native filter menus, embedded location snippet. |
| **Local Persistence** | `SwiftData` (`@Model`) | Offline persistence for `WalkThought` entities, query filtering, and auto-sync to UI. |
| **Speech-to-Text** | `Speech` (`SFSpeechRecognizer`) | On-device dictation (`requiresOnDeviceRecognition = true`). |
| **Audio Capture** | `AVFoundation` (`AVAudioEngine`, `AVAudioSession`, `AVAudioRecorder`) | High-quality audio capture with live microphone buffer streaming. |
| **Step Tracking (Live)** | `CoreMotion` (`CMPedometer`) | High-resolution real-time step and distance counting during Active Walk sessions. |
| **Step Tracking (Historical)** | `HealthKit` (`HKHealthStore`) | Access to system-level daily steps, distance running/walking, and background updates. |
| **Location & Geocoding** | `CoreLocation` (`CLLocationManager`, `CLGeocoder`) | Background location tracking, GPS snapshotting on thought creation, offline fallback geocoding. |
| **Local Notifications** | `UserNotifications` (`UNUserNotificationCenter`) | Background step-milestone alerts that deep-link directly into dictation mode. |

---

### 3.2 Required `Info.plist` Keys

Walky Talky requires explicit permission strings and background execution keys. These must be registered in `WalkyTalky/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Background Modes for Continuous Step Tracking & Audio -->
    <key>UIBackgroundModes</key>
    <array>
        <string>location</string>
        <string>audio</string>
        <string>processing</string>
    </array>

    <!-- Microphone Permission for Voice Dictation -->
    <key>NSMicrophoneUsageDescription</key>
    <string>Walky Talky uses your microphone to transcribe your walking thoughts into text while you walk.</string>

    <!-- Speech Recognition Permission -->
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>Walky Talky uses on-device speech recognition to privately convert your spoken thoughts into notes without internet access.</string>

    <!-- Motion & Pedometer Permission -->
    <key>NSMotionUsageDescription</key>
    <string>Walky Talky accesses motion data to count your steps in real time and notify you at your configured walking milestones.</string>

    <!-- Core Location Permissions -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Walky Talky logs your walking location to pin where your thoughts and insights occurred along your route.</string>

    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>Walky Talky requires background location access to accurately track steps and distance during an Active Walk session when your screen is locked.</string>

    <!-- HealthKit Read Permission -->
    <key>NSHealthShareUsageDescription</key>
    <string>Walky Talky reads step count and walking distance from HealthKit to display cumulative walk statistics alongside your notes.</string>
</dict>
</plist>
```

### 3.3 Entitlements (`WalkyTalky.entitlements`)
The target must include the HealthKit entitlement key:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.healthkit</key>
    <true/>
    <key>com.apple.developer.healthkit.access</key>
    <array/>
</dict>
</plist>
```

---

## 4. Data Model Schema (`SwiftData`)

### 4.1 The `WalkThought` Model
The persistent record representing an individual walking thought or insight.

```swift
// WalkThought.swift
import Foundation
import SwiftData
import CoreLocation

@Model
final class WalkThought {
    // Unique Identifier
    @Attribute(.unique) var id: UUID
    
    // Temporal Metadata
    var createdAt: Date
    var modifiedAt: Date
    
    // Content Payload
    var title: String
    var bodyText: String
    var tags: [String]
    var isFavorite: Bool
    
    // Optional Local Audio File Reference
    var audioFileName: String? // Relative file name stored in Documents/Recordings/
    var audioDurationSeconds: Double
    
    // Sensor Snapshot at Time of Recording
    var stepCountSnapshot: Int           // Total steps walked during the active session up to this point
    var distanceSnapshotMeters: Double   // Total distance walked during the active session up to this point
    var sessionDurationSeconds: Double   // Seconds since walk session began
    
    // Spatial Metadata (Offline GPS)
    var latitude: Double?
    var longitude: Double?
    var altitude: Double?
    
    // Geocoding Fallback Metadata
    var reverseGeocodedPlace: String?    // e.g. "Sacramento, CA" or "Central Park, NY"
    var isGeocodePending: Bool           // True if recorded offline and awaiting connectivity
    
    // Initialization
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
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
        self.modifiedAt = createdAt
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
    
    // Computed coordinate helper
    var coordinate: CLLocationCoordinate2D? {
        guard let latitude = latitude, let longitude = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // Formatted distance helper
    var formattedDistance: String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.maximumFractionDigits = 2
        let measurement = Measurement(value: distanceSnapshotMeters, unit: UnitLength.meters)
        return formatter.string(from: measurement)
    }
}
```

### 4.2 Local File Storage Strategy
Audio recordings (`.m4a` format encoded via AAC) must **never** be stored as raw BLOBs inside SwiftData. Instead:
1. Audio recordings are saved to `<Application_Home>/Documents/Recordings/<UUID>.m4a`.
2. The `audioFileName` string attribute in `WalkThought` references `<UUID>.m4a`.
3. An explicit `FileManager` cleanup hook deletes the audio file on disk whenever its parent `WalkThought` entity is deleted from SwiftData.

---

## 5. View Hierarchy & Navigation Flow (Strictly 3 Core Views)

```
                            ┌────────────────────────────────────────┐
                            │               WalkyTalkyApp            │
                            │        (SwiftData ModelContainer)      │
                            └───────────────────┬────────────────────┘
                                                │
                                                ▼
                            ┌────────────────────────────────────────┐
                            │              HomeView                  │
                            │   (Thoughts Feed & Walk Controller)    │
                            │                                        │
                            │  * Search & Filter Menu                │
                            │  * Active Walk Bar (Steps, Distance)   │
                            │  * Responsive Note Card Grid           │
                            │  * Dictation Trigger (FAB)             │
                            └──────────┬──────────────────┬──────────┘
                                       │                  │
                Tap Note Card          │                  │ Tap "+", Walk Bar,
                                       │                  │ or Step Notification
                                       ▼                  ▼
              ┌──────────────────────────────────┐      ┌──────────────────────────────────┐
              │      ThoughtDetailView           │      │        NewNoteFlowSheet          │
              │                                  │      │                                  │
              │  * Formatted Timestamp & Badges  │      │  [Phase 1: Dictation]            │
              │  * Metric Cards (Steps, Dist)    │      │  * Offline Speech Recognizer     │
              │  * Full Note Body Text           │      │  * Live Waveform / Audio Meter   │
              │  * MapKit Snippet / Offline GPS  │      │  * Live Walk Snapshot            │
              │  * Audio Playback Bar (if saved) │      │                 │                │
              │  * Share / Delete / Edit Actions │      │                 ▼ (Tap Stop)     │
              └──────────────────────────────────┘      │  [Phase 2: Editing & Review]     │
                                                        │  * Edit Transcribed Title & Body │
                                                        │  * Assign Tags                   │
                                                        │  * Save to SwiftData / Discard   │
                                                        └──────────────────────────────────┘
```

---

### 5.1 View 1: Home View (`HomeView.swift`)
The central command center and entry point of the app.

#### Structural Elements
* **Native Navigation Bar:**
  * Title: *"My Thoughts"* with dynamic subtitle *"A collection of everything on my mind."*
  * Trailing Toolbar: Settings / Filter Menu (`Menu`) with options:
    * Sort: *Newest First*, *Oldest First*, *Most Steps*, *Favorites Only*.
    * Tag Filter: Horizontal scrollable tag filter pills (`All`, `#Ideas`, `#Reflections`, `#Nature`, `#Drafts`).
* **Active Walk Status Bar:**
  * Displays when an Active Walk session is engaged.
  * Shows a pulsing green indicator, live session step count (e.g. `"1,420 steps"`), cumulative distance (e.g. `"1.1 km"`), and a pause/stop toggle.
* **Native Search:**
  * Implemented via `.searchable(text: $searchText, prompt: "Search notes, tags, or locations...")`.
  * Filters thought titles, body text, tags, and cached reverse-geocoded place names in real time.
* **Thought Feed (Adaptive Grid or Vertical List):**
  * Modern card presentation with `Theme.Colors.cardSurface` background and rounded corners (`Theme.Layout.cardCornerRadius = 20`).
  * **Card Visual Hierarchy:**
    1. Header: Tag badge pill (e.g., `DAJE`, `WALK`) and relative timestamp (e.g., `"Today, 2:48 PM"`).
    2. Title: Bold serif typography (`Theme.Typography.headline`).
    3. Excerpt: 2-line preview of `bodyText`.
    4. Footer Metrics: Miniature SF Symbols for steps (`figure.walk`), distance (`point.topleft.down.to.point.bottomright.curvepath`), and optional audio badge (`waveform`).
    5. Map Thumbnail Snippet: Embedded small map preview for notes captured with valid coordinates.
* **Floating Action Button (FAB):**
  * Positioned in the bottom trailing corner or anchored in the bottom toolbar.
  * Rendered in `Theme.Colors.accent` (Deep Evergreen `#162E14`) with a white plus icon.
  * Tapping presents the `NewNoteFlowSheet`.

---

### 5.2 View 2: New Note Flow (`NewNoteFlowView.swift`)
A modal or navigation experience split into two clearly distinct, smooth phases.

#### Phase 1: Dictation (`DictationPhaseView.swift`)
* **Entry State:** Automatically initializes the `AVAudioEngine`, activates the audio session for recording, starts the `SFSpeechRecognizer` with `requiresOnDeviceRecognition = true`, and takes an immediate snapshot of current walk metrics (steps, distance, GPS coordinates).
* **UI Layout:**
  * **Top Header:** Step counter and distance badge reflecting the walk session.
  * **Center Stage:** A live, animated audio visualizer (e.g., pulsing concentric rings or dynamic waveform bars mapped to microphone peak/average decibel power).
  * **Live Stream Preview:** Real-time text output updating as the user speaks.
  * **Controls:** 
    * Prominent circular **"Done Recording"** button (Forest Green checkmark or stop button).
    * Subdued **"Cancel"** button.

#### Phase 2: Editing & Review (`NoteEditingPhaseView.swift`)
* **State Transition:** Triggered as soon as the user taps "Done Recording". The audio engine shuts down, final transcription text is committed, and the view smoothly morphs into a clean editing canvas.
* **UI Layout:**
  * **Top Toolbar:** `"Discard"` (leading) and `"Save Note"` (trailing, bold accent green).
  * **Metrics Bar:** Horizontal scrollable pills showing:
    * Step count at recording (e.g. `👣 840 steps`).
    * Distance covered (e.g. `📍 0.65 km`).
    * Captured coordinate preview (e.g. `37.7749° N, 122.4194° W` or resolved street name).
  * **Title Field:** Large, bold serif text field (`Theme.Typography.title2`) with placeholder `"Title of the Walk"`.
  * **Body Field:** Scrollable, auto-expanding `TextEditor` with transcribed text ready for typing, proofreading, or expanding.
  * **Tag Bar:** Add or toggle tag chips.
  * **Audio Preservation Toggle:** Toggle switch asking *"Keep original audio recording?"* (Defaults to on; saves audio to sandbox, or discards if only text is desired).

---

### 5.3 View 3: Thought Visualization (`ThoughtDetailView.swift`)
Dedicated inspection view reached by tapping any note card in the Home View.

#### Structural Elements
* **Navigation Bar:**
  * Back button (`< Back`).
  * Trailing options menu: `Toggle Favorite` (`star` / `star.fill`), `Share Text`, `Delete Thought`.
* **Header & Tag Badges:**
  * Tag capsules rendered in `Theme.Colors.badgeSurface`.
  * Note Title in large, elegant serif font (`Theme.Typography.title`).
  * Metadata row with calendar icon (`calendar`) for date/time and pin icon (`mappin.and.ellipse`) for location.
* **Walk Metrics Summary Card:**
  * A dedicated stats strip displaying:
    * Steps logged at time of thought.
    * Walk distance logged.
    * Duration into the walk when the thought struck.
* **Audio Playback Bar (Conditional):**
  * If `audioFileName` exists, presents a native audio player with play/pause button, scrubber slider, current playback time, and duration.
* **Body Text Canvas:**
  * Clean, distraction-free reading typography with generous line spacing (`lineSpacing(6)`).
* **Embedded MapKit Snippet (`LocationSnippetView.swift`):**
  * Displays an interactive or static `Map` view centered on `thought.coordinate`.
  * Annotated with a custom pin matching `Theme.Colors.accent`.
* **Offline Map & Geocoding Fallback:**
  * If the device is offline or `MapKit` tiles fail to render, the card displays a clean coordinate capsule (e.g. `"Coordinates: 38.5816° N, 121.4944° W"`).
  * If `isGeocodePending == true`, displays a subtle indicator: `"Location pending resolution..."` which resolves automatically in the background when connectivity returns.

---

## 6. Step Counter & Background Notification Architecture

### 6.1 The Background Execution Problem
iOS strictly regulates background operations:
1. **HealthKit Background Throttling:** Passive background delivery from `HKObserverQuery` on step count data is coalesced and throttled by the OS, firing at intervals of **once per hour at best**. This makes passive HealthKit queries entirely unsuitable for real-time walking notifications (e.g., notifying the user every 500 steps).
2. **Pedometer Background Suspension:** `CMPedometer` live updates (`startUpdates(from:withHandler:)`) cease when the app enters the background unless the app maintains an active background execution mode.

### 6.2 The Solution: "Active Walk Mode" Engine

To deliver guaranteed, accurate, real-time step notifications while the screen is locked and the user is walking, Walky Talky implements an **"Active Walk Mode"**:

```
 ┌────────────────────────────────────────────────────────────────────────┐
 │                        ACTIVE WALK MODE LIFECYCLE                      │
 └───────────────────────────────────┬────────────────────────────────────┘
                                     │ User toggles "Start Walk"
                                     ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │ 1. Engage Continuous Background Location Updates                       │
 │    - CLLocationManager.allowsBackgroundLocationUpdates = true          │
 │    - CLLocationManager.pausesLocationUpdatesAutomatically = false      │
 │    - CLLocationManager.showsBackgroundLocationIndicator = true         │
 │    - DesiredAccuracy = kCLLocationAccuracyBestForNavigation            │
 └───────────────────────────────────┬────────────────────────────────────┘
                                     │ Keeps process alive in background
                                     ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │ 2. Start Live CoreMotion Pedometer Stream                              │
 │    - CMPedometer.startUpdates(from: walkStartTime)                     │
 │    - Receives live step increments every few seconds                   │
 └───────────────────────────────────┬────────────────────────────────────┘
                                     │ Step count crosses threshold
                                     ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │ 3. Check Milestone Threshold (e.g., cumulativeSteps >= lastAlert + 500)│
 └───────────────────────────────────┬────────────────────────────────────┘
                                     │ Threshold reached
                                     ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │ 4. Fire UNUserNotificationCenter Local Notification                    │
 │    - Title: "500 Steps Walked!"                                        │
 │    - Body: "You've walked 500 steps. What's on your mind? Tap to speak."│
 │    - UserInfo Payload: currentSteps, currentDistance, latitude, etc.   │
 └───────────────────────────────────┬────────────────────────────────────┘
                                     │ User taps notification
                                     ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │ 5. Deep-Link Handler Launches New Note Dictation Directly              │
 │    - Bypasses home feed                                                │
 │    - Pre-populates snapshot metrics (steps: 500, distance, GPS)       │
 │    - Immediately begins offline voice dictation                        │
 └────────────────────────────────────────────────────────────────────────┘
```

### 6.3 Notification Payload & Deep-Link Architecture

When the user taps the step-milestone notification, the app receives the `UNNotificationResponse`:
1. The notification payload includes:
   ```json
   {
       "action": "RECORD_THOUGHT",
       "sessionStepCount": 500,
       "sessionDistanceMeters": 380.5,
       "latitude": 38.5816,
       "longitude": -121.4944
   }
   ```
2. The `NotificationManager` passes this payload to a centralized `AppNavigationState` environment object.
3. The root `NavigationStack` catches the deep link and immediately presents the `NewNoteFlowView` sheet in `DictationPhase`, automatically attaching the pre-captured metrics.

### 6.4 Configurable Step Thresholds
The step threshold is stored in `UserDefaults` via `@AppStorage("stepAlertInterval") var stepAlertInterval: Int = 500`. Users can configure this in settings (e.g., 250, 500, 750, 1000 steps).

---

## 7. Step-by-Step Implementation Roadmap

The implementation of Walky Talky is divided into 7 distinct, sequential milestones.

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Phase 1    │     │   Phase 2    │     │   Phase 3    │     │   Phase 4    │
│ Foundations, │ ──> │ SwiftData &  │ ──> │ Speech &     │ ──> │ CoreMotion,  │
│ Permissions, │     │ Persistence  │     │ Audio Engine │     │ Location &   │
│ Theme System │     │ Architecture │     │ Service      │     │ Walk Manager │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
                                                                       │
                                                                       ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Completion  │     │   Phase 7    │     │   Phase 6    │     │   Phase 5    │
│  & HIG Audit │ <── │ Thought      │ <── │ New Note     │ <── │ Home View &  │
│              │     │ Detail View  │     │ Flow Views   │     │ Thought Feed │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
```

### Phase 1: Project Foundations, Permissions & Design Tokens
* **Objective:** Establish the build environment, entitlements, permission descriptions, and design tokens.
* **Tasks:**
  1. Verify and configure `WalkyTalky/Info.plist` with all required usage descriptions (`NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`, `NSMotionUsageDescription`, `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`, `UIBackgroundModes`).
  2. Ensure `WalkyTalky.entitlements` contains the HealthKit entitlement.
  3. Create `Theme.swift` with exact extracted color constants (`#F5F5F3`, `#D5D9D1`, `#162E14`, `#112120`, etc.), typography presets, and layout metrics.
  4. Create Color Sets in `Assets.xcassets` matching the theme semantic tokens for automatic light/dark mode adaptation.

### Phase 2: SwiftData Schema & Storage Service
* **Objective:** Configure local offline database and file management.
* **Tasks:**
  1. Implement the `WalkThought` SwiftData `@Model` with full attribute schema.
  2. Implement `AudioFileManager` to handle storing, reading, and deleting `.m4a` files in the app's `Documents/Recordings` directory.
  3. Initialize the `ModelContainer` in `WalkyTalkyApp.swift` with preview and production configurations.
  4. Write sample preview mock data for SwiftUI canvas and development testing.

### Phase 3: Offline Speech Recognition & Audio Recording Engine
* **Objective:** Build the 100% offline dictation and audio recording service.
* **Tasks:**
  1. Build `SpeechRecognitionService` using `SFSpeechRecognizer(locale: Locale.current)` with `requiresOnDeviceRecognition = true`.
  2. Build `AudioRecordingService` using `AVAudioEngine` and `AVAudioInputNode` to capture microphone input, stream buffers to speech recognition, and simultaneously compute audio levels for live waveform rendering.
  3. Provide comprehensive error handling for microphone denied, speech recognition restricted, and offline model availability states.

### Phase 4: CoreMotion, HealthKit & Walk Session Manager
* **Objective:** Deliver the "Active Walk Mode" engine and step-milestone notifications.
* **Tasks:**
  1. Build `WalkSessionManager` (Observable Object) orchestrating `CMPedometer` live updates and `CLLocationManager` background tracking.
  2. Build `NotificationManager` using `UNUserNotificationCenter` to request authorization, schedule step-milestone notifications, and handle deep-link response payloads.
  3. Implement the threshold trigger: track `milestoneStepBaseline`, compare against cumulative steps, and dispatch notifications every `stepAlertInterval` steps.
  4. Implement `LocationService` with opportunistic offline fallback geocoding (`CLGeocoder`).

### Phase 5: Home View & Thoughts Feed
* **Objective:** Build the primary feed and navigation frame.
* **Tasks:**
  1. Create `HomeView.swift` wrapped in a native `NavigationStack`.
  2. Implement the top search bar using `.searchable` with dynamic filtering across titles, bodies, and tags.
  3. Add the native filter `Menu` for sorting (date ascending/descending, steps, favorites).
  4. Create `ActiveWalkBannerView` showing live walk status, step count, and pause/stop controls.
  5. Create `ThoughtCardView` using `Theme.Colors.cardSurface`, custom badges, typography, and optional mini-map preview.
  6. Add the prominent Floating Action Button / bottom bar action to trigger note creation.

### Phase 6: New Note Flow (Dictation & Editing)
* **Objective:** Build the two-phase recording and editing experience.
* **Tasks:**
  1. Create `NewNoteFlowView.swift` managing phase switching (`.dictating` -> `.editing`).
  2. Implement `DictationPhaseView`: live waveform animation, real-time transcription text stream, walk snapshot badges, and "Done" button.
  3. Implement `NoteEditingPhaseView`: title input, full text editor, tag selector, audio retention toggle, and Save/Discard buttons.
  4. Ensure saving persists `WalkThought` to SwiftData, saves audio to disk if enabled, and dismisses smoothly back to `HomeView`.

### Phase 7: Thought Detail View & Offline Map Fallback
* **Objective:** Build the full inspection view for captured thoughts.
* **Tasks:**
  1. Create `ThoughtDetailView.swift` displaying formatted date, title, tags, and complete thought text.
  2. Build `WalkMetricStrip` showing steps, distance, and duration snapshots.
  3. Implement `AudioPlayerView` for playing back the locally saved `.m4a` file with scrubber controls.
  4. Build `LocationSnippetView`: embedded `MapKit` map centering on coordinates with custom evergreen pin.
  5. Implement the offline fallback UI: formatted coordinates capsule and pending geocoding status if offline.

### Phase 8: Quality Assurance, HIG Audit & Deep-Link Testing
* **Objective:** Validate privacy, offline capabilities, HIG aesthetics, and notification transitions.
* **Tasks:**
  1. Test offline voice dictation with Airplane Mode enabled (confirm transcription functions with zero connectivity).
  2. Test Active Walk Mode in the simulator/device: verify background location keeps the app running and step milestone notifications fire properly.
  3. Test tapping the notification to confirm seamless deep linking directly into `NewNoteFlowView` with pre-filled metrics.
  4. Audit UI against Apple HIG: Dynamic Type scaling, touch target sizes (minimum 44x44pt), VoiceOver accessibility labels, and Dark Mode contrast.
