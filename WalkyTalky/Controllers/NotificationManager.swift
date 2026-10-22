//
//  NotificationManager.swift
//  WalkyTalky
//
//  Created by Apple Developer on 20/10/2026.
//

import Foundation
import UserNotifications
import Combine

/// Manages local user notifications for step milestones and handles deep linking
/// directly into the New Note Dictation flow with pre-populated walk metrics.
@MainActor
public final class NotificationManager: NSObject, ObservableObject {
    public static let shared = NotificationManager()
    
    // MARK: - Published State
    @Published public private(set) var isNotificationAuthorized: Bool = false
    @Published public var pendingDeepLinkSnapshot: ThoughtSnapshotPayload? = nil
    
    // Notification category identifier
    public static let stepMilestoneCategoryIdentifier = "WALK_STEP_MILESTONE"
    
    // MARK: - Initialization
    public override init() {
        super.init()
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        checkAuthorization()
    }
    
    // MARK: - Permissions
    public func requestAuthorization() async -> Bool {
        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            self.isNotificationAuthorized = granted
            print("🔔 [NotificationManager] Notification permission granted: \(granted)")
            return granted
        } catch {
            print("⚠️ [NotificationManager] Permission error: \(error)")
            self.isNotificationAuthorized = false
            return false
        }
    }
    
    public func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.isNotificationAuthorized = (settings.authorizationStatus == .authorized)
            }
        }
    }
    
    // MARK: - Step Milestone Notification Dispatch
    /// Schedules an immediate local notification when the user crosses a step threshold.
    /// The notification carries an immutable snapshot of metrics for deep linking into dictation.
    public func dispatchStepMilestoneNotification(payload: ThoughtSnapshotPayload) {
        let content = UNMutableNotificationContent()
        content.title = "\(payload.formattedSteps) Steps Walked! 👣"
        content.body = "You've crossed \(payload.formattedSteps) steps on this walk. What's on your mind right now? Tap to record."
        content.sound = .default
        content.categoryIdentifier = Self.stepMilestoneCategoryIdentifier
        content.userInfo = payload.userInfoRepresentation
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "walk.milestone.\(payload.stepCount).\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ [NotificationManager] Error delivering milestone notification: \(error)")
            } else {
                print("🔔 [NotificationManager] Dispatched milestone notification for \(payload.stepCount) steps.")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    
    /// Called when a notification is delivered while the app is in the foreground.
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and play sound even in foreground
        completionHandler([.banner, .sound])
    }
    
    /// Called when the user taps the notification banner from background or lock screen.
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let snapshot = ThoughtSnapshotPayload(userInfo: userInfo) {
            Task { @MainActor in
                print("🚀 [NotificationManager] Deep-linking into dictation with snapshot (\(snapshot.stepCount) steps).")
                self.pendingDeepLinkSnapshot = snapshot
            }
        }
        completionHandler()
    }
}
