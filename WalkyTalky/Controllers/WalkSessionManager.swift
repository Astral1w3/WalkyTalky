//
//  WalkSessionManager.swift
//  WalkyTalky
//
//  Created by Apple Developer on 20/10/2026.
//

import Foundation
import CoreMotion
import HealthKit
import Combine
import CoreLocation

/// Orchestrates "Active Walk Mode", real-time step and distance counting via `CMPedometer`,
/// background location execution, and automated step-milestone notification dispatch.
@MainActor
public final class WalkSessionManager: ObservableObject {
    
    // MARK: - Published State
    @Published public private(set) var isWalking: Bool = false
    @Published public private(set) var isPaused: Bool = false
    @Published public private(set) var sessionSteps: Int = 0
    @Published public private(set) var sessionDistanceMeters: Double = 0.0
    @Published public private(set) var sessionDurationSeconds: TimeInterval = 0.0
    @Published public private(set) var currentPaceSecondsPerMeter: Double? = nil
    @Published public private(set) var dailyTotalSteps: Int = 0
    @Published public var stepMilestoneInterval: Int = 500 // Configurable step alert threshold
    
    // MARK: - Dependencies
    public let locationService: LocationService
    public let notificationManager: NotificationManager
    
    private let pedometer = CMPedometer()
    private let healthStore = HKHealthStore()
    
    // MARK: - Internal Session Tracking
    private var walkStartTime: Date?
    private var durationTimer: Timer?
    private var lastMilestoneFiredStepCount: Int = 0
    private var simulatedPedometerTimer: Timer?
    
    // MARK: - Summary Struct
    public struct WalkSessionSummary {
        public let totalSteps: Int
        public let totalDistanceMeters: Double
        public let durationSeconds: TimeInterval
        public let startedAt: Date
        public let endedAt: Date
    }
    
    // MARK: - Initialization
    public init(
        locationService: LocationService? = nil,
        notificationManager: NotificationManager? = nil
    ) {
        let loc = locationService ?? LocationService()
        let notif = notificationManager ?? NotificationManager.shared
        self.locationService = loc
        self.notificationManager = notif
        
        // Load user-configured step milestone interval
        let savedInterval = UserDefaults.standard.integer(forKey: "stepAlertInterval")
        if savedInterval > 0 {
            self.stepMilestoneInterval = savedInterval
        }
        
        Task {
            await requestHealthKitAuthorization()
            await queryDailySteps()
        }
    }
    
    // MARK: - HealthKit Authorization & Sync
    public func requestHealthKitAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let stepType = HKQuantityType(.stepCount)
        let distanceType = HKQuantityType(.distanceWalkingRunning)
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: [stepType, distanceType])
            print("🩺 [WalkSessionManager] HealthKit authorization granted.")
            await queryDailySteps()
        } catch {
            print("⚠️ [WalkSessionManager] HealthKit authorization failed: \(error)")
        }
    }
    
    public func queryDailySteps() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let stepType = HKQuantityType(.stepCount)
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, stats, error in
            guard let self = self, let sum = stats?.sumQuantity() else { return }
            let total = Int(sum.doubleValue(for: HKUnit.count()))
            Task { @MainActor in
                self.dailyTotalSteps = total
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Active Walk Mode Lifecycle
    /// Engages "Active Walk Mode": begins live pedometer counting and starts background location
    /// updates to keep the process running while the handset is locked in the user's pocket.
    public func startWalk() {
        guard !isWalking else { return }
        
        let startTime = Date()
        self.walkStartTime = startTime
        self.isWalking = true
        self.isPaused = false
        self.sessionSteps = 0
        self.sessionDistanceMeters = 0.0
        self.sessionDurationSeconds = 0.0
        self.lastMilestoneFiredStepCount = 0
        
        // 1. Start continuous background location to maintain process execution
        locationService.startBackgroundTracking()
        
        // 2. Start duration timer
        startDurationTimer()
        
        // 3. Start live CoreMotion pedometer stream
        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: startTime) { [weak self] data, error in
                guard let data = data else { return }
                let steps = data.numberOfSteps.intValue
                let distance = data.distance?.doubleValue
                let pace = data.currentPace?.doubleValue
                
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.sessionSteps = steps
                    if let dist = distance {
                        self.sessionDistanceMeters = dist
                    } else {
                        // Fallback average step length approximation (~0.76 meters per step)
                        self.sessionDistanceMeters = Double(steps) * 0.76
                    }
                    self.currentPaceSecondsPerMeter = pace
                    self.evaluateStepMilestoneThreshold()
                }
            }
        } else {
            // Simulator fallback: simulate gentle walking pace (~2 steps per second)
            print("👟 [WalkSessionManager] CMPedometer unavailable on this hardware. Running simulator step simulation.")
            startSimulatedPedometer()
        }
        
        print("🚶 [WalkSessionManager] Active Walk Mode started.")
    }
    
    /// Pauses the active walk session.
    public func pauseWalk() {
        guard isWalking && !isPaused else { return }
        isPaused = true
        pedometer.stopUpdates()
        stopDurationTimer()
        stopSimulatedPedometer()
        print("⏸️ [WalkSessionManager] Walk session paused.")
    }
    
    /// Resumes the active walk session.
    public func resumeWalk() {
        guard isWalking && isPaused else { return }
        isPaused = false
        startDurationTimer()
        
        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: walkStartTime ?? Date()) { [weak self] data, error in
                guard let data = data else { return }
                let steps = data.numberOfSteps.intValue
                let distance = data.distance?.doubleValue
                
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.sessionSteps = steps
                    self.sessionDistanceMeters = distance ?? (Double(steps) * 0.76)
                    self.evaluateStepMilestoneThreshold()
                }
            }
        } else {
            startSimulatedPedometer()
        }
        print("▶️ [WalkSessionManager] Walk session resumed.")
    }
    
    /// Concludes the active walk session, stops background tracking, and returns the session summary.
    public func stopWalk() -> WalkSessionSummary {
        let summary = WalkSessionSummary(
            totalSteps: sessionSteps,
            totalDistanceMeters: sessionDistanceMeters,
            durationSeconds: sessionDurationSeconds,
            startedAt: walkStartTime ?? Date(),
            endedAt: Date()
        )
        
        pedometer.stopUpdates()
        stopDurationTimer()
        stopSimulatedPedometer()
        locationService.stopTracking()
        
        isWalking = false
        isPaused = false
        walkStartTime = nil
        
        print("🛑 [WalkSessionManager] Walk session completed with \(summary.totalSteps) steps.")
        return summary
    }
    
    // MARK: - Step-Trigger Notification Evaluation
    private func evaluateStepMilestoneThreshold() {
        let delta = sessionSteps - lastMilestoneFiredStepCount
        if delta >= stepMilestoneInterval {
            // Update milestone baseline
            lastMilestoneFiredStepCount = sessionSteps - (sessionSteps % stepMilestoneInterval)
            
            // Capture snapshot of instantaneous walk data
            let snapshot = captureCurrentSnapshot()
            
            // Dispatch notification via NotificationManager
            notificationManager.dispatchStepMilestoneNotification(payload: snapshot)
        }
    }
    
    // MARK: - Snapshot Capture
    /// Captures the instantaneous physical and spatial metrics at the current moment in the walk.
    public func captureCurrentSnapshot() -> ThoughtSnapshotPayload {
        return ThoughtSnapshotPayload(
            stepCount: sessionSteps,
            distanceMeters: sessionDistanceMeters,
            sessionDurationSeconds: sessionDurationSeconds,
            latitude: locationService.currentCoordinate?.latitude,
            longitude: locationService.currentCoordinate?.longitude,
            altitude: locationService.currentAltitude,
            capturedAt: Date()
        )
    }
    
    // MARK: - Timers
    private func startDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isWalking, !self.isPaused else { return }
                self.sessionDurationSeconds += 1.0
            }
        }
    }
    
    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }
    
    // Simulator mock step generator
    private func startSimulatedPedometer() {
        simulatedPedometerTimer?.invalidate()
        simulatedPedometerTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isWalking, !self.isPaused else { return }
                self.sessionSteps += 2
                self.sessionDistanceMeters += 1.5
                self.evaluateStepMilestoneThreshold()
            }
        }
    }
    
    private func stopSimulatedPedometer() {
        simulatedPedometerTimer?.invalidate()
        simulatedPedometerTimer = nil
    }
    
    // MARK: - Formatters
    public var formattedDuration: String {
        let total = Int(sessionDurationSeconds)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    public var formattedSteps: String {
        return WalkFormatter.formatStepNumber(sessionSteps)
    }
    
    public var formattedDistance: String {
        return WalkFormatter.formatDistance(meters: sessionDistanceMeters)
    }
    
    public var formattedStepsAndDistance: String {
        return WalkFormatter.formatStepsAndDistance(steps: sessionSteps, meters: sessionDistanceMeters)
    }
}
