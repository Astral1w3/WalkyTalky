# Walky Talky — Comprehensive Project Context (`context.md`)

## 1. Project Background & Vision
* **App Name:** Walky Talky
* **Role:** Expert iOS Architect and SwiftUI Developer
* **Platform Target:** iOS 17.0+ (Swift 5.10 / Swift 6, SwiftUI)
* **Design Philosophy:** 100% Native Apple Human Interface Guidelines (HIG), completely decoupled Theme/Design System, strictly 100% Offline-First.
* **Core Functionality:** Voice-first walking companion that allows users to record spoken thoughts while walking. Notes automatically capture physical sensor snapshots: cumulative steps, distance walked, timestamps, GPS coordinates, and optional local audio recordings.
* **Offline Mandate:** Zero cloud authentication, zero login views, zero external network dependency. On-device speech recognition (`SFSpeechRecognizer` with `requiresOnDeviceRecognition = true`), local persistence via `SwiftData`, local audio in sandbox documents, and offline map/geocoding fallbacks.
* **Scope Definition (Strictly 3 Core Views):**
  1. **Home View ("My Mind"):** Thoughts Feed, `.searchable`, filter `Menu`, Active Walk status banner, and dictation floating trigger.
  2. **New Note Flow:** Two-phase modal sheet (`Phase 1: Dictation` with real-time waveform and speech transcription $\rightarrow$ `Phase 2: Editing & Review` with text editing, tags, and local saving).
  3. **Thought Visualization (Detail View):** Rich detail presentation with walk metric badges, body text, optional audio playback, and embedded `MapKit` snippet with offline coordinate fallback.
  * *Note:* Prototype screens showing standalone "Map View", "Saved View", and "Profile" tabs have been explicitly removed.

---

## 2. Completed Work & Changelog

### A. Reference Asset Analysis & Color Extraction
* Extracted high-resolution image (`reference/extracted_full.png`, 1227x1281) from `reference/Pasted 20-10-2026 at 16.37.30.pdf`.
* Performed programmatic color sampling across prototype UI elements:
  * Primary Background (warm mineral stone paper): `#F5F5F3`
  * Card Surface (muted lichen/sage): `#D5D9D1`
  * Primary Accent (deep forest pine): `#162E14`
  * Light Badge Surface (pale sage): `#D4D9CE`
  * Dark Badge Surface (deep moss): `#395238`
  * Primary Text (deep pine charcoal): `#112120`
  * Secondary Text (earthy slate gray): `#707973`
  * Search Bar Surface: `#EAECE8`
  * Destructive Alert: `#B33A3A`
* Determined dark mode complementary tokens for full dynamic appearance support.

### B. Architectural Specification (`AGENT.md`)
* Authored the architectural and design source of truth in [`AGENT.md`](file:///Users/angelomarcone/Desktop/academy/WalkyTalky/AGENT.md).
* Established:
  1. Project Overview & Offline Constraints.
  2. Design System and complete `Theme.swift` code specification.
  3. Technical Stack, `Info.plist` permissions, and HealthKit entitlements.
  4. `SwiftData` Schema (`WalkThought`) and audio file storage strategy.
  5. 3 Core Views structure and navigation transitions.
  6. "Active Walk Mode" engine combining `CMPedometer` live updates and background `CLLocationManager` to bypass iOS passive HealthKit throttling, scheduling `UNUserNotificationCenter` step milestone alerts.
  7. 8-Phase Step-by-Step Implementation Roadmap.

### C. Phase 1 Implementation (Project Foundations, Permissions & Design System)
* **Configuration & Permissions (`WalkyTalky/Info.plist`):**
  * Added `UIBackgroundModes`: `location`, `audio`, `processing`.
  * Added descriptive usage strings for `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`, `NSMotionUsageDescription`, `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`, and `NSHealthShareUsageDescription`.
* **Entitlements (`WalkyTalky/WalkyTalky.entitlements`):**
  * Configured `com.apple.developer.healthkit = true` with empty access array.
* **Asset Catalog (`WalkyTalky/Assets.xcassets`):**
  * Generated 9 dual-mode (Universal Light + Dark luminosity) `.colorset` folders:
    * `AccentColor` (`#162E14` / `#4E8A52`)
    * `PrimaryBackground` (`#F5F5F3` / `#121513`)
    * `CardSurface` (`#D5D9D1` / `#1C221E`)
    * `BadgeSurface` (`#D4D9CE` / `#263328`)
    * `BadgeDarkSurface` (`#395238` / `#426141`)
    * `PrimaryText` (`#112120` / `#F2F4F1`)
    * `SecondaryText` (`#707973` / `#9BA49C`)
    * `SearchBarSurface` (`#EAECE8` / `#1E2520`)
    * `DestructiveColor` (`#B33A3A` / `#E05D5D`)
* **Design System (`WalkyTalky/Theme.swift`):**
  * Implemented `Theme.Colors` with dynamic asset references and programmatic hex fallbacks.
  * Implemented `Theme.Typography` (serif titles, rounded metric numbers, readable body).
  * Implemented `Theme.Layout` tokens (corner radii 20pt / 28pt, paddings, touch targets 44pt).
  * Implemented `Theme.Symbols` mapping common SF Symbols.
  * Implemented `.walkyCardStyle()` and `.walkyTagBadge()` view modifiers.
* **Build System & Toolchain Notes:**
  * Xcode 27.1 is active at `/Applications/Xcode.app/Contents/Developer`.
  * The `#Preview` macro invokes `swift-plugin-server` which fails in sandboxed CLI environments (`external macro implementation type 'PreviewsMacros.SwiftUIView' could not be found`); standard `PreviewProvider` is used instead for preview definitions.
  * Configured `.gitignore` to prevent tracking `.build`, DerivedData, `.DS_Store`, and `xcuserdata`.
  * Updated `WalkyTalky/ContentView.swift` to verify theme rendering.
  * Build verified with `xcodebuild`: **`** BUILD SUCCEEDED **`**.

---

### D. Phase 2 Implementation (SwiftData Schema & Storage Service)
* **SwiftData Model (`WalkyTalky/WalkThought.swift`):**
  * Created `@Model final class WalkThought` implementing:
    * Identity: `@Attribute(.unique) var id: UUID`.
    * Temporal: `createdAt: Date`, `modifiedAt: Date`.
    * Content: `title: String`, `bodyText: String`, `tags: [String]`, `isFavorite: Bool`.
    * Audio Reference: `audioFileName: String?` (pointing to sandbox `.m4a`), `audioDurationSeconds: Double`.
    * Sensor Snapshots: `stepCountSnapshot: Int`, `distanceSnapshotMeters: Double`, `sessionDurationSeconds: Double`.
    * Spatial: `latitude: Double?`, `longitude: Double?`, `altitude: Double?`.
    * Offline Geocode State: `reverseGeocodedPlace: String?`, `isGeocodePending: Bool`.
    * Formatting helpers: `coordinate`, `displayTitle`, `formattedDistance`, `formattedSteps`, `formattedDate`, `formattedFullDate`, `formattedCoordinates`, `formattedDuration`.
* **Audio Storage Service (`WalkyTalky/AudioFileManager.swift`):**
  * Implemented singleton managing sandbox directory `<Application_Documents>/Recordings/`.
  * Generates unique `.m4a` URLs (`createNewRecordingURL`), deletes recordings on note deletion (`deleteAudioFile`), computes durations (`audioDuration`), and cleans orphaned files (`pruneOrphanedRecordings`).
* **Preview Mock Data (`WalkyTalky/MockData.swift`):**
  * Created sample thoughts mirroring prototype notes ("Title of the Walk", "Old Brick Building", "Pacing & Clarity", "River Trail Breeze").
  * Provided an in-memory `ModelContainer` (`MockData.previewContainer`) for SwiftUI canvas rendering and testing.
* **App Entry & Host View Integration (`WalkyTalkyApp.swift`, `ContentView.swift`):**
  * Initialized shared `ModelContainer` with persistent configuration in `WalkyTalkyApp.swift`.
  * Verified SwiftData `@Query` live fetching and insertion in `ContentView.swift`.
  * Verified build with Xcode 27.1: **`BUILD SUCCEEDED`**.

---

### E. Phase 3 Implementation (Offline Speech Recognition & Audio Recording Engine)
* **Offline Speech Recognizer (`WalkyTalky/SpeechRecognitionService.swift`):**
  * `SFSpeechRecognizer` forced to `requiresOnDeviceRecognition = true` ensuring 100% offline transcription.
  * Live buffer streaming via `appendAudioBuffer(_ buffer: AVAudioPCMBuffer)` with `shouldReportPartialResults = true` and automatic punctuation.
  * Locale fallback logic: attempts `Locale.current` and falls back to `en-US` if locale lacks offline speech recognition models.
  * Thread-safe real-time streaming: marked `appendAudioBuffer` as `nonisolated` with an `NSLock` protecting `_recognitionRequest` (`nonisolated(unsafe)`), allowing zero-latency audio buffer delivery directly from the CoreAudio thread without `@MainActor` thread hopping.
  * Graceful completion in `stopRecognition()` by allowing trailing speech frames to commit before terminating.
* **Audio Engine & Decibel Metering (`WalkyTalky/AudioRecordingService.swift`):**
  * Built using low-latency `AVAudioEngine` tapping `inputNode` with `1024` buffer size.
  * Activated `AVAudioSession` first to avoid `0.0Hz` sample rate bugs, with fallback to 44.1kHz.
  * Generates compressed voice `.m4a` files (Mono AAC, 64kbps, 44.1kHz/48kHz) in the sandbox documents directory.
  * Computes root-mean-square (RMS) decibel levels mapped to normalized `[0.0, 1.0]` for live waveform and pulsing UI rendering.
  * Eliminated cross-actor state access inside the audio tap block by capturing local immutable handles before installing the tap.
* **Audio File Manager (`WalkyTalky/AudioFileManager.swift`):**
  * Hardened directory creation in `createNewRecordingURL()`.
  * Modernized duration calculation using `AVAudioPlayer` with `AVURLAsset` fallback.
* **Unified Dictation Coordinator (`WalkyTalky/DictationCoordinator.swift`):**
  * Links `AudioRecordingService` and `SpeechRecognitionService` into a cohesive, `@MainActor` reactive pipeline.
  * Pipes incoming audio PCM buffers from the microphone directly into the speech recognizer.
  * Exposes unified lifecycle: `startDictation(saveAudioFile:)`, `stopDictation() -> DictationResult`, and `cancelDictation()`.
* **Build Verification:**
  * Clean build succeeded with Xcode 27.1: **`BUILD SUCCEEDED`**.

---

### F. Phase 4 Implementation (CoreMotion, HealthKit & Walk Session Manager)
* **Background Location & Geocoding (`WalkyTalky/LocationService.swift`):**
  * `CLLocationManager` background tracking configured with `allowsBackgroundLocationUpdates = true` and `showsBackgroundLocationIndicator = true` to maintain execution during active walks.
  * Opportunistic reverse-geocoding via `CLGeocoder`: returns "City, State" when connected to network; fails gracefully when offline so raw GPS coordinates (`38.5816° N, 121.4944° W`) can be displayed.
* **Thought Snapshot Payload (`WalkyTalky/ThoughtSnapshotPayload.swift`):**
  * `Sendable` immutable contract capturing instantaneous walk metrics: `stepCount`, `distanceMeters`, `sessionDurationSeconds`, `latitude`, `longitude`, `altitude`, `capturedAt`.
  * Bi-directional dictionary serialization for local notification `userInfo` payload delivery.
* **Notification & Deep-Link Manager (`WalkyTalky/NotificationManager.swift`):**
  * Manages `UNUserNotificationCenter` authorization, foreground presentation, and background notification action delivery.
  * Dispatches rich step-milestone alerts (`"1,000 Steps Walked! 👣"`).
  * Tapping a milestone notification from the lock screen or banner captures the payload into `@Published var pendingDeepLinkSnapshot`, triggering direct presentation of the dictation flow.
* **Walk Session Manager (`WalkyTalky/WalkSessionManager.swift`):**
  * Orchestrates "Active Walk Mode": coordinates `CMPedometer` live updates, `LocationService` background updates, and `NotificationManager`.
  * Monitors real-time step increments: when `sessionSteps` crosses `stepMilestoneInterval` (configurable, default 500 steps), automatically snapshots the walk and fires the notification.
  * HealthKit integration: requests `HKQuantityType(.stepCount)` and `HKQuantityType(.distanceWalkingRunning)` authorization and queries cumulative daily steps.
  * Simulator-aware: includes an automated simulated pedometer cadence for development on environments without physical CoreMotion hardware.
* **Build Verification:**
  * Clean build succeeded with Xcode 27.1: **`BUILD SUCCEEDED`**.

---

### G. Phase 5 Implementation (Home View & Thoughts Feed)
* **Mini Map Card Thumbnail (`WalkyTalky/MiniMapSnapshotView.swift`):**
  * Displays a non-interactive static `Map` preview centered on note coordinates with a custom evergreen pin.
  * Gracefully renders an offline placeholder when GPS coordinates are unavailable.
* **Typography & Custom Font Integration (`Theme.swift`, `Info.plist`):**
  * Integrated Google Fonts **Karma 600** (`Karma-SemiBold.ttf`) alongside Medium, Regular, and Bold variants into the app bundle.
  * Registered font family in `Info.plist` under `UIAppFonts`.
  * Updated `Theme.Typography` with `karma600(_:relativeTo:)` scaling `largeTitle`, `title`, `title2`, `title3`, and `headline` with native Dynamic Type support.
* **Thought Card View (`WalkyTalky/ThoughtCardView.swift`):**
  * Clean, minimalist card design: removed map thumbnails, body text excerpts, and favorite star icons per user directives.
  * Cards are sleek, compact tiles displaying relative timestamp, bold Karma 600 title, optional resolved location, and footer metrics (step count, distance, audio duration).
* **Active Walk Session Banner (`WalkyTalky/ActiveWalkBannerView.swift`):**
  * Displays at the top of the feed:
    * Active state: pulsing green indicator, live session steps, distance, duration ticker, pause/resume, and confirmation dialog stop button.
    * Idle state: one-tap "Start Active Walk" button.
* **Home Command Center & Bottom Ergonomic Dock (`WalkyTalky/HomeView.swift`):**
  * Embedded in a native `NavigationStack` with large serif title "My Thoughts" and prototype subtitle.
  * **Bottom-Docked Search Bar:** Relocated from navigation bar to a bottom-anchored floating dock via `.safeAreaInset(edge: .bottom)`, optimized for single-handed thumb reachability.
  * **Integrated Dictation Action:** Prominent floating "+" button docked right alongside the bottom search bar with a frosted glass background (`.ultraThinMaterial`).
  * Removed unnecessary tag filter chips row, keeping the focus entirely on chronological and searched thoughts.
  * Native trailing filter `Menu` for sorting (Newest, Oldest, Most Steps, Longest Distance) and "Favorites Only" filtering.
  * 2-column responsive adaptive grid layout (`LazyVGrid`).
  * Deep-link reactive trigger via `.onChange(of: notificationManager.pendingDeepLinkSnapshot)` automatically presenting the dictation sheet with snapshot metrics.
* **App Entry Update (`WalkyTalkyApp.swift`):**
  * Replaced `ContentView()` with `HomeView()` as the primary application scene.
* **Build Verification:**
  * Clean build succeeded with Xcode 27.1: **`BUILD SUCCEEDED`**.

---

## 3. Phase 6 Completion: New Note Flow & Mockup (`page2.jpg`) Alignment
* **Waveform Visualization (`WalkyTalky/RecordingWaveformView.swift`):**
  * Single continuous horizontal ECG / audio-frequency waveform line crossing from edge to edge near the bottom of the screen, matching `reference/page2.jpg`.
  * Utilizes SwiftUI `Canvas` and `TimelineView` (60fps) to generate dynamic harmonic oscillations combining fundamental waves and seismograph-style ECG spikes driven by live microphone `audioLevel` (`[0.0, 1.0]`).
  * Smooth resting pulse when quiet and responsive amplitude expansion during speech.
* **Recording Screen (`WalkyTalky/DictationPhaseView.swift`):**
  * Recreation of `reference/page2.jpg` harmonized with native SF Pro typography:
    * Warm papyrus linen background (`#FAF2E8`).
    * Top Header: Leading official Apple back chevron (`chevron.backward`) matching native NavigationStack back buttons, centered uppercase walk metrics header (`\(snapshot.formattedSteps) STEPS · \(snapshot.formattedDistance)`), and trailing terracotta microphone icon (`mic.fill`).
    * Center Spoken Thought: Large SF Pro Semibold typography wrapped in quotation marks `“...”`, displaying real-time offline transcription from `DictationCoordinator`.
    * Guidance Prompt: `"Just speak, I'm listening..."` in terracotta ochre (`#C17C59`).
    * Action Button: Signature `● Journaling` capsule button in solid terracotta (`#CE6E4C`) with a pulsing white indicator dot that concludes recording on tap.
    * Bottom: Responsive `RecordingWaveformView` powered by a 100% continuous multi-sine harmonic wave with smooth edge envelope (`sin(normalizedX * .pi)`), timeline-driven monotonic animation, and strict vertical bounding via `tanh` and frame clamping to prevent any overflow or clipping outside the screen.
* **Note Review & Polish (`WalkyTalky/NoteEditingPhaseView.swift`):**
  * Seamless transition after dictation concludes:
    * Auto-extracts a title from the first sentence or clause, editable in SF Pro Semibold.
    * Full editable `TextEditor` with transcription content.
    * Walk metrics strip (steps, distance, reverse geocoded place) using `WalkFormatter`.
    * **Audio Preservation Toggle (`AGENT.md` Spec):** Allows the user to toggle "Keep audio recording". When disabled, sandbox `.m4a` files are automatically purged to conserve device storage.
    * Integrated audio player preview allowing playback of the recorded `.m4a` file with play/pause and scrubber progress.
    * Actions: "Save" (persists `WalkThought` into SwiftData) or "Discard" (deletes sandbox `.m4a` file).
* **Flow Coordinator (`WalkyTalky/NewNoteFlowView.swift`):**
  * Coordinates `.dictating` $\rightarrow$ `.editing` phase state machine with crossfade transitions.
  * Auto-starts on-device dictation when presented via `.fullScreenCover`.

---

## 4. Phase 7 Completion: Thought Detail View
* **Full Thought Inspection (`WalkyTalky/Views/Detail/ThoughtDetailView.swift`):**
  * Deep inspection view styled in warm linen and espresso charcoal.
  * Header metadata: formatted full timestamp (e.g. "Wednesday, Oct 21 · 9:41 AM") and resolved location tag.
  * Tag Badges: Horizontal scrollable capsule badges rendered in `Theme.Colors.badgeSurface` when tags are present.
  * Title: SF Pro Bold font (`displayTitle`), editable in-place.
  * Physical Walk Metrics Strip: Steps count (`formattedSteps`), distance (`formattedDistance`), and walk session duration formatted cleanly via `WalkFormatter`.
  * Local Audio Player: In-card player labeled "YOUR THOUGHTS" using `AVAudioPlayer` with interactive `Slider` scrubber controls, live progress tracking, and remaining duration.
  * Full Note Content: Comfortable reading experience with text selection enabled.
  * Spatial Map (`WalkyTalky/Views/Detail/MiniMapSnapshotView.swift`): Embedded `MapKit` snippet centering on GPS coordinates with terracotta pin, an overlay status capsule with resolved place name or coordinates, pending resolution state (`"Location pending resolution..."`), and offline fallback.
  * In-place Editing: "Edit" toggle to modify title and body directly in SwiftData (`thought.modifiedAt = Date()`).
  * Export & Share: Native iOS `ShareLink` exporting thought text and physical walk metrics.
  * Safe Deletion: Confirmation dialog ensuring deletion of both the SwiftData model and the corresponding local audio file (`AudioFileManager.shared.deleteAudioFile`).
* **Home View Integration:**
  * Replaced all temporary placeholder stubs in `HomeView.swift` with `NewNoteFlowView` presented via `.fullScreenCover` for full-screen edge-to-edge presentation, and `ThoughtDetailView` in `.navigationDestination`.
* **Card Redesign (`reference/tg3.jpg` Alignment):**
  * Updated `ThoughtCardView.swift` to match the larger, elegant aspect ratio seen in `reference/tg3.jpg`:
    * Balanced card height to 150pt with a calm oatmeal canvas.
    * Anchored the note title cleanly at the bottom inside a distinct footer bar with subtle 1px border.
    * Uses unified SF Pro Semibold for the title (`displayTitle`).
    * Added a clean 3-line note body preview (`thought.bodyText`) in the upper card area with comfortable line spacing, while anchoring the title bar and optional audio badge at the bottom.
    * Completely stripped extraneous clutter from the card: no "Today 8:00 AM" or timestamps, no tags, no metric icons/badges.
    * Switched `HomeView.swift` feed from a 2-column grid to a single-column `LazyVStack(spacing: 16)` matching the `tg3` layout.

---

## 5. Apple-Style Design Consistency Updates (`reference/apple1`-`4`)
* **1. Typography Consistency (SF Pro Unified Scale):**
  * Eliminated the jarring clash between serif headlines and sans-serif titles.
  * Standardized the entire application on the native iOS System Font (SF Pro-style) across all views (`Theme.Typography`).
  * Created visual hierarchy purely through size, weight (`.bold`, `.semibold`, `.regular`), and semantic color, matching Apple HIG (`apple3.png`).
* **2. Intentional Empty Space & Layout Balance:**
  * Replaced the accidental-looking blank area with an intentional Apple-style hero empty state featuring a clean walking badge, clear guidance text, and a sample thought loader.
  * Added a dedicated "Thoughts" section header with a live item counter (`apple1.png` / `apple2.png`).
  * Tuned card height to 150pt so individual cards feel intentional and proportional rather than leaving a massive void.
* **3. Unified Visual Hierarchy & Primary Action Focus:**
  * Established "Start Active Walk" as the primary contextual action in the upper banner.
  * Made the top-right toolbar menu a subtle secondary Apple-style `ellipsis.circle` icon in `secondaryText`.
  * **100% Native Navigation Search & Floating Action Button:**
    * Removed the custom bottom floating search capsule and bottom gradient backdrop.
    * Implemented Apple's 100% native `.searchable(text: $searchText, prompt: "Search thoughts or places...")` modifier directly in the navigation bar drawer beneath `"My Mind"`.
    * Integrated Apple's native `ContentUnavailableView.search(text: searchText)` for zero search results.
    * Re-anchored the signature terracotta `+` button as a clean, elevated floating action button (FAB) in the `.bottomTrailing` corner (`54x54` circle, `#CE6E4C` accent, white plus icon, subtle drop shadow), acting as a native `NavigationLink` pushing directly onto `NavigationStack`.
    * Adjusted bottom scroll inset to `88pt` for clean card scrolling without visual interference.
  * **Native Navigation Transition to Recording & Original Apple Back Arrow:**
    * Converted the `+` floating action button in `HomeView` from a modal cover trigger to a direct `NavigationLink` pushing `NewNoteFlowView` onto the root `NavigationStack`.
    * Removed the custom-drawn back button (`chevron.backward` button in body `HStack`) from `DictationPhaseView`.
    * Handed back navigation control to iOS's native navigation bar: now uses the authentic, 100% original Apple back button (`< My Mind`) with native interactive edge-swipe gesture.
    * Formatted the navigation bar with real-time walk metrics (`1,420 STEPS · 1.12 KM`) and the official terracotta `mic.fill` icon integrated inside `.principal` (`titleView`), completely eliminating `ToolbarItem(placement: .topBarTrailing)` / `UIBarButtonItem`. The microphone is rendered as a pure static SwiftUI `Image` with zero button behaviors, zero touch handlers, and zero press highlights.
    * Integrated automatic dictation cancellation on navigation pop (`.onDisappear`), and removed redundant nested `NavigationStack` in `NoteEditingPhaseView`.
  * **Continuous Multi-Sentence Dictation Accumulator (iOS 17/18 Speech Pause Fix):**
    * Resolved the issue where Apple's on-device speech engine discards or overwrites previous transcripts after a silence pause (~1.5-2 seconds).
    * Implemented an intelligent multi-utterance accumulation engine in `SpeechRecognitionService`:
      * Tracks segment timestamp offsets (`SFTranscriptionSegment.timestamp`) to detect utterance boundaries.
      * Employs lexical continuity and word-overlap analysis to distinguish in-place word revisions from new post-pause sentences.
      * Automatically commits completed utterance blocks into a persistent array while streaming live interim text for the active utterance.
      * Reassembles all committed utterances into a unified, properly punctuated continuous transcription (`assembleFullTranscription`).
      * Explicitly set `request.taskHint = .dictation` on `SFSpeechAudioBufferRecognitionRequest` to prioritize continuous dictation models over single-command Siri heuristics.
  * **Asset Catalog & TDDistiller Fix:**
    * Cleaned `AppIcon.appiconset/Contents.json` to adhere to standard universal specifications without unpopulated dark/tinted appearance slots that caused `actool` variant thinning crashes (`Each TDDistiller instance can be distilled only one time!`).
    * Cleared intermediate build caches and permission locks on `assetcatalog_dependencies_thinned`.
* **4. Universal Metric & Date Formatting (`WalkFormatter.swift`):**
  * Built a centralized formatting engine enforcing consistent US English locale conventions (`en_US`).
  * Resolved the decimal/delimiter conflict: now consistently renders `1,420 steps · 1.12 km` with comma thousands separator, period decimal separator, and middle dot delimiter.
  * Aligned all dates to `MMM d · h:mm a` (e.g. `Oct 21 · 9:41 AM`).

---

## 6. Directory Layout (Architecture Refactor)
```
WalkyTalky/
├── AGENT.md                                # Architectural Source of Truth
├── context.md                              # Detailed Project Progress Log
├── compact_context.md                      # Compressed Summary for LLM Instances
├── .gitignore                              # Git exclusion rules
├── reference/
│   ├── Pasted 20-10-2026 at 16.37.30.pdf  # Raw Prototype PDF
│   ├── extracted_full.png                  # Extracted prototype visual reference
│   ├── page2.jpg                           # Recording screen visual reference mockup
│   ├── apple1.png - apple4.png             # Apple HIG visual references
│   └── tg1.jpg - tg3.jpg                   # Card aspect visual references
├── WalkyTalky.xcodeproj/                   # Xcode Project Package
└── WalkyTalky/
    ├── App/
    │   ├── WalkyTalkyApp.swift             # App Lifecycle & SwiftData Container
    │   └── ContentView.swift               # Host View Verification Stub
    ├── Models/
    │   ├── WalkThought.swift               # SwiftData Persistent Model
    │   ├── ThoughtSnapshotPayload.swift    # Sensor Snapshot & Notification Payload
    │   └── MockData.swift                  # In-Memory Preview Container & Fixtures
    ├── Views/
    │   ├── Home/
    │   │   ├── HomeView.swift              # Primary Feed ("My Mind"), Search & Floating Action
    │   │   ├── ThoughtCardView.swift       # Single-Column Note Card Component
    │   │   └── ActiveWalkBannerView.swift  # Live Active Walk Controls & Metric Ticker
    │   ├── NewNote/
    │   │   ├── NewNoteFlowView.swift       # Two-Phase Dictation & Editing Coordinator
    │   │   ├── DictationPhaseView.swift    # Mockup page2.jpg Dictation Screen
    │   │   ├── NoteEditingPhaseView.swift  # Review, Edit, Audio Player & Persistence
    │   │   └── RecordingWaveformView.swift # Continuous Bounded Sine Audio Waveform
    │   └── Detail/
    │       ├── ThoughtDetailView.swift     # Full Thought Inspection & Audio Player
    │       └── MiniMapSnapshotView.swift   # Map Thumbnail with Offline Fallback
    ├── Controllers/
    │   ├── WalkSessionManager.swift        # Active Walk Mode & CMPedometer Engine
    │   ├── DictationCoordinator.swift      # Unified Dictation & Buffer Pipeline
    │   ├── AudioRecordingService.swift     # AVAudioEngine Microphone & Waveform Engine
    │   ├── SpeechRecognitionService.swift  # On-Device Offline Speech Transcription
    │   ├── AudioFileManager.swift          # Sandbox Audio Storage Manager
    │   ├── NotificationManager.swift       # Step Milestones & Deep Linking
    │   └── LocationService.swift           # Background GPS & Offline Geocoding
    ├── DesignSystem/
    │   └── Theme.swift                     # Centralized Design System & HIG Tokens
    ├── Resources/
    │   ├── Assets.xcassets/                # Dual-mode Color Catalogs & App Icon
    │   └── Fonts/
    │       ├── Karma-Regular.ttf
    │       ├── Karma-Medium.ttf
    │       ├── Karma-SemiBold.ttf
    │       └── Karma-Bold.ttf
    ├── Utilities/
    │   └── WalkFormatter.swift             # Centralized Metric & Locale Engine
    ├── Info.plist                          # Background modes & Privacy Permissions
    └── WalkyTalky.entitlements             # HealthKit Entitlements
```

---

## 7. Build Status & Verification
* **Target:** iOS Simulator (arm64 / x86_64), iOS 17.0+
* **Build Result:** **`BUILD SUCCEEDED`** (Zero errors, zero compiler warnings).
