# Walky Talky — Compact Context (`compact_context.md`)

## System & Project Identity
* **App:** Walky Talky (iOS 17.0+, SwiftUI, SwiftData).
* **Source of Truth:** `AGENT.md` (Architecture, design tokens, data models, workflows).
* **Offline-First:** 100% offline on-device speech-to-text (`SFSpeechRecognizer.requiresOnDeviceRecognition = true`). Zero cloud, zero accounts, no profile view, no standalone map/saved tabs.
* **Architecture:** Clean modular architecture: `App/`, `Models/`, `Views/` (`Home`, `NewNote`, `Detail`), `Controllers/`, `DesignSystem/`, `Resources/`, `Utilities/`.
* **Views (Strictly 3):**
  1. `HomeView` (single-column spacious feed matching `reference/apple1`-`4` & `tg3` with 150pt cards featuring a 3-line body preview and bottom-anchored title bar). Apple 100% native `.searchable` modifier in navigation bar drawer with native `ContentUnavailableView.search`, subtle `ellipsis.circle` menu, Active Walk banner, and a floating terracotta `+` action button in the bottom trailing corner acting as a direct `NavigationLink`.
  2. `NewNoteFlowView` (`DictationPhaseView` matching `reference/page2.jpg` pushed onto `NavigationStack` with Apple's 100% original navigation back button and interactive edge swipe $\rightarrow$ `NoteEditingPhaseView`).
  3. `ThoughtDetailView` (SF Pro bold title, walk stats strip, audio player for local `.m4a`, map snippet + offline GPS fallback, edit mode, delete with audio cleanup, share sheet).

## Design System (`Theme.swift`, `Assets.xcassets`, iOS System Font SF Pro)
* **Visual Reference:** Apple HIG (`apple1`-`apple4.png`) and recording reference (`page2.jpg`).
* **Theme Colors:**
  * `primaryBackground`: Warm linen `#FAF2E8` (Light) / `#1A1612` (Dark)
  * `cardSurface`: Soft oatmeal `#EFE6D8` (Light) / `#26201B` (Dark)
  * `accent`: Terracotta clay `#CE6E4C` (Light) / `#E28463` (Dark)
  * `primaryText`: Espresso charcoal `#14110A` (Light) / `#F5EFEB` (Dark)
  * `secondaryText`: Muted umber `#7D7569` (Light) / `#A39A8E` (Dark)
  * `terracottaPrompt`: Guidance ochre `#C17C59` (Light) / `#D89472` (Dark)
  * `waveformLine`: Beige/grey `#CCC5B9` (Light) / `#5A5248` (Dark)
  * `searchBarSurface`: Cream `#EAE1D2` (Light) / `#2C251F` (Dark)
* **Typography:**
  * Unified iOS System Font (SF Pro-style) across all headers, titles, cards, and buttons. Hierarchy created strictly through weight, size, and semantic color.
* **Formatting Engine (`WalkFormatter.swift`):**
  * Strictly enforces consistent US English locale conventions (`en_US`): e.g. `1,420 steps · 1.12 km`, `Oct 21 · 9:41 AM`. Zero delimiter mismatch.
* **Layout:** `cardCornerRadius: 20`, `buttonCornerRadius: 28`, `cardPadding: 14`.

## Motion & Step Notification Engine
* **Issue:** Passive HealthKit queries throttled by iOS to $\approx 1$/hr in background.
* **Solution:** "Active Walk Mode" using `CMPedometer` live updates + background location (`allowsBackgroundLocationUpdates = true`, `showsBackgroundLocationIndicator = true`).
* **Milestone Alert:** Steps threshold (default 500) fires `UNUserNotificationCenter` local alert. Tapping deep-links into `NewNoteFlowView` with pre-filled step/distance/GPS snapshot.

## Environment & Toolchain Constraints
* **Xcode Path:** Set `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
* **Build Command:** `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcodebuild -scheme WalkyTalky -destination "generic/platform=iOS Simulator" -derivedDataPath .build/DerivedData build`
* **Sandbox Rule:** Standard sandbox mode blocks `swift-plugin-server` when expanding Swift Macros (`@Model`, `#Preview`) because nested `sandbox-exec` is disallowed. Run builds with `BypassSandbox: true`.
* **Previews:** Use standard `PreviewProvider` instead of `#Preview` macro for preview definitions.

## Progress Tracker
* [x] **Phase 1: Foundations, Permissions & Design Tokens** (Info.plist, entitlements, Assets.xcassets, Theme.swift). Build succeeded.
* [x] **Phase 2: SwiftData Schema & Storage Service** (`WalkThought` model, `AudioFileManager`, `ModelContainer` in `WalkyTalkyApp.swift`, `MockData.swift`). Build succeeded.
* [x] **Phase 3: Speech Recognition & Audio Engine** (`SpeechRecognitionService` with multi-utterance pause accumulator & `taskHint = .dictation`, `AudioRecordingService`, `DictationCoordinator`). Build succeeded.
* [x] **Phase 4: CoreMotion, HealthKit & Walk Manager** (`WalkSessionManager`, `NotificationManager`, `LocationService`, `ThoughtSnapshotPayload`). Build succeeded.
* [x] **Phase 5: Home View Redesign** (`HomeView`, `ThoughtCardView`, `ActiveWalkBannerView`, `MiniMapSnapshotView`). Bottom dock search + plus button, clean minimal cards, Karma 600. Build succeeded.
* [x] **Phase 6: New Note Flow & page2.jpg Mockup** (`RecordingWaveformView` with continuous multi-sine harmonic wave and strict screen bounding, `DictationPhaseView`, `NoteEditingPhaseView`, `NewNoteFlowView`). Build succeeded.
* [x] **Phase 7: Thought Detail View & Offline Map Fallback** (`ThoughtDetailView` with audio player & scrubber, `MiniMapSnapshotView` with pending resolution capsule & offline fallback, tag capsules, in-place editing, sharing, safe deletion). Build succeeded.
* [ ] **Phase 8: Polish & QA Testing**.
