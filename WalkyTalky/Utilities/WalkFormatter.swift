//
//  WalkFormatter.swift
//  WalkyTalky
//
//  Created by Apple Developer on 21/10/2026.
//

import Foundation

/// Unified, Apple-standard formatting utility ensuring consistent locale conventions
/// across all metrics, step counts, distances, and timestamps.
/// Strictly enforces US English locale conventions (e.g. "1,420 steps · 1.12 km").
public enum WalkFormatter {
    
    public static let enUSLocale = Locale(identifier: "en_US")
    
    // MARK: - Step Count Formatting
    /// Formats step count with comma thousands separator: e.g. 1420 -> "1,420"
    public static func formatStepNumber(_ steps: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = enUSLocale
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
    
    /// Formats step count with units: e.g. 1420 -> "1,420 steps"
    public static func formatSteps(_ steps: Int) -> String {
        return "\(formatStepNumber(steps)) steps"
    }
    
    // MARK: - Distance Formatting
    /// Formats distance in kilometers with 2 decimal places: e.g. 1120 meters -> "1.12 km"
    public static func formatDistance(meters: Double) -> String {
        let km = meters / 1000.0
        let formatter = NumberFormatter()
        formatter.locale = enUSLocale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let formattedNumber = formatter.string(from: NSNumber(value: km)) ?? String(format: "%.2f", km)
        return "\(formattedNumber) km"
    }
    
    // MARK: - Combined Metric String
    /// Formats steps and distance combined with a middle dot: e.g. "1,420 steps · 1.12 km"
    public static func formatStepsAndDistance(steps: Int, meters: Double) -> String {
        return "\(formatSteps(steps)) · \(formatDistance(meters: meters))"
    }
    
    /// Header uppercase format: e.g. "1,420 STEPS · 1.12 KM"
    public static func formatHeaderMetrics(steps: Int, meters: Double) -> String {
        return "\(formatStepNumber(steps)) STEPS · \(formatDistance(meters: meters).uppercased())"
    }
    
    // MARK: - Date & Time Formatting
    /// Short date and time: e.g. "Oct 21 · 9:41 AM"
    public static func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = enUSLocale
        formatter.dateFormat = "MMM d · h:mm a"
        return formatter.string(from: date)
    }
    
    /// Full date with weekday: e.g. "Wednesday, Oct 21 · 9:41 AM"
    public static func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = enUSLocale
        formatter.dateFormat = "EEEE, MMM d · h:mm a"
        return formatter.string(from: date)
    }
    
    /// Date only: e.g. "Oct 21, 2026"
    public static func formatDayOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = enUSLocale
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    /// Time only: e.g. "9:41 AM"
    public static func formatTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = enUSLocale
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    // MARK: - Duration Formatting
    /// Formats seconds into "24m 15s" or "42s"
    public static func formatDuration(seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        if m > 0 {
            return "\(m)m \(s)s"
        } else {
            return "\(s)s"
        }
    }
    
    /// Audio timer format: "0:42" or "1:15"
    public static func formatAudioTimer(seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
