//
//  Theme.swift
//  WalkyTalky
//
//  Created by Apple Developer on 20/10/2026.
//

import SwiftUI

/// Centralized, decoupled Design System and Theme configuration for Walky Talky.
/// Uses the organic warm terracotta and linen palette extracted from the prototype mockup (`page2.jpg`),
/// powered by Google Fonts Karma 600 (SemiBold) for expressive headlines.
public enum Theme {
    
    // MARK: - Semantic Colors (Extracted from page2.jpg mockup)
    public enum Colors {
        // Dynamic Asset Catalog Colors (Adapts between Light and Dark mode)
        public static let primaryBackground = Color("PrimaryBackground")
        public static let cardSurface = Color("CardSurface")
        public static let accent = Color("AccentColor") // Warm Terracotta Clay (#CE6E4C)
        public static let badgeSurface = Color("BadgeSurface")
        public static let badgeDarkSurface = Color("BadgeDarkSurface")
        public static let primaryText = Color("PrimaryText") // Espresso Charcoal (#14110A)
        public static let secondaryText = Color("SecondaryText") // Warm Slate Stone (#8C8276)
        public static let searchBarSurface = Color("SearchBarSurface")
        public static let destructive = Color("DestructiveColor")
        
        // Mockup Specific Tones (page2.jpg)
        public static let terracottaPrompt = Color(hex: "#C17C59") // "Just speak, I'm listening..."
        public static let waveformLine = Color(hex: "#CCC5B9")     // Bottom live audio waveform
        
        // Raw Extracted Hex Codes for Reference and Direct Fallbacks
        public static let lightBackgroundHex = "#FAF2E8"
        public static let lightCardHex = "#EFE6D8"
        public static let lightAccentHex = "#CE6E4C"
        public static let lightPrimaryTextHex = "#14110A"
        public static let lightSecondaryTextHex = "#8C8276"
        public static let lightBadgeHex = "#F0E5D4"
        public static let lightBadgeDarkHex = "#CE6E4C"
        public static let lightSearchHex = "#F0E8DC"
        public static let lightDestructiveHex = "#B33A3A"
        
        // Static Programmatic Fallbacks
        public static let fallbackBackground = Color(hex: lightBackgroundHex)
        public static let fallbackCard = Color(hex: lightCardHex)
        public static let fallbackAccent = Color(hex: lightAccentHex)
        public static let fallbackPrimaryText = Color(hex: lightPrimaryTextHex)
        public static let fallbackSecondaryText = Color(hex: lightSecondaryTextHex)
    }
    
    // MARK: - Typography Scale (Apple SF Pro Unified Design System)
    public enum Typography {
        /// Fallback compatibility helper mapping to the iOS System Font (SF Pro Semibold)
        public static func karma600(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
            return Font.system(size: size, weight: .semibold, design: .default)
        }
        
        /// Large bold heading for the navigation title (SF Pro Bold)
        public static let largeTitle = Font.system(.largeTitle, design: .default, weight: .bold)
        
        /// Large recording dictation headline in SF Pro Semibold
        public static let recordingSpoken = Font.system(size: 32, weight: .semibold, design: .default)
        
        /// Detail view thought title (SF Pro Bold)
        public static let title = Font.system(.title, design: .default, weight: .bold)
        
        /// Section titles and modal card headers (SF Pro Bold)
        public static let title2 = Font.system(.title2, design: .default, weight: .bold)
        
        /// Subsection titles (SF Pro Semibold)
        public static let title3 = Font.system(.title3, design: .default, weight: .semibold)
        
        /// Note card title in feed (SF Pro Semibold)
        public static let headline = Font.system(.headline, design: .default, weight: .semibold)
        
        /// Standard reading body text
        public static let body = Font.system(.body, design: .default, weight: .regular)
        
        /// Secondary reading text and metrics
        public static let callout = Font.system(.callout, design: .default, weight: .medium)
        
        /// Subheadlines and secondary labels
        public static let subheadline = Font.system(.subheadline, design: .default, weight: .regular)
        
        /// Metadata annotations (timestamps, coordinates)
        public static let footnote = Font.system(.footnote, design: .default, weight: .regular)
        
        /// Captions and small labels
        public static let caption = Font.system(.caption, design: .default, weight: .medium)
        
        /// Micro captions
        public static let caption2 = Font.system(.caption2, design: .default, weight: .regular)
        
        /// High-visibility rounded typography for step counters and distance numbers
        public static let metricNumber = Font.system(.title2, design: .rounded, weight: .bold)
        
        /// Compact metric number
        public static let metricSmall = Font.system(.headline, design: .rounded, weight: .bold)
        
        /// Spaced header step & distance tracker (`1,420 STEPS · 1.12 KM`)
        public static let stepHeader = Font.system(.subheadline, design: .rounded, weight: .semibold)
    }
    
    // MARK: - Layout Constants
    public enum Layout {
        public static let standardPadding: CGFloat = 16.0
        public static let smallPadding: CGFloat = 8.0
        public static let cardPadding: CGFloat = 14.0
        public static let cardCornerRadius: CGFloat = 20.0
        public static let badgeCornerRadius: CGFloat = 8.0
        public static let buttonCornerRadius: CGFloat = 28.0
        public static let gridSpacing: CGFloat = 12.0
        public static let touchTargetMin: CGFloat = 44.0
    }
    
    // MARK: - Common SF Symbols
    public enum Symbols {
        public static let steps = "figure.walk"
        public static let distance = "point.topleft.down.to.point.bottomright.curvepath"
        public static let location = "mappin.and.ellipse"
        public static let calendar = "calendar"
        public static let clock = "clock"
        public static let mic = "mic.fill"
        public static let micStop = "stop.fill"
        public static let checkmark = "checkmark"
        public static let plus = "plus"
        public static let search = "magnifyingglass"
        public static let filter = "line.3.horizontal.decrease.circle"
        public static let options = "ellipsis.circle"
        public static let favorite = "star"
        public static let favoriteFilled = "star.fill"
        public static let trash = "trash"
        public static let share = "square.and.arrow.up"
        public static let waveform = "waveform"
        public static let play = "play.fill"
        public static let pause = "pause.fill"
        public static let leaf = "leaf.fill"
    }
}

// MARK: - Color Hex Initializer
extension Color {
    public init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
}

// MARK: - Semantic View Modifiers
public struct WalkyCardModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(Theme.Layout.cardPadding)
            .background(Theme.Colors.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardCornerRadius, style: .continuous))
    }
}

public struct WalkyTagBadgeModifier: ViewModifier {
    public var isDark: Bool = false
    
    public func body(content: Content) -> some View {
        content
            .font(Theme.Typography.caption)
            .fontWeight(.semibold)
            .foregroundStyle(isDark ? Color.white : Theme.Colors.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(isDark ? Theme.Colors.badgeDarkSurface : Theme.Colors.badgeSurface)
            .clipShape(Capsule())
    }
}

extension View {
    public func walkyCardStyle() -> some View {
        modifier(WalkyCardModifier())
    }
    
    public func walkyTagBadge(isDark: Bool = false) -> some View {
        modifier(WalkyTagBadgeModifier(isDark: isDark))
    }
}

// MARK: - Previews
struct Theme_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Theme.Layout.standardPadding) {
            Text("Walky Talky")
                .font(Theme.Typography.largeTitle)
                .foregroundStyle(Theme.Colors.primaryText)
            
            Text("Terracotta & Linen Palette from Mockup")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.secondaryText)
            
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: Theme.Symbols.steps)
                    Text("1,420")
                        .font(Theme.Typography.metricSmall)
                }
                .foregroundStyle(Theme.Colors.accent)
            }
            .walkyCardStyle()
        }
        .padding()
        .background(Theme.Colors.primaryBackground)
    }
}
