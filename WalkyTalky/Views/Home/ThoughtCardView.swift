//
//  ThoughtCardView.swift
//  WalkyTalky
//
//  Created by Apple Developer on 20/10/2026.
//

import SwiftUI

/// Individual thought card rendered inside the Home View thoughts feed.
/// Styled after the larger aspect reference (`tg3.jpg`) with a spacious
/// card canvas and the note title anchored cleanly at the bottom.
struct ThoughtCardView: View {
    let thought: WalkThought
    
    // TOGGLE: Set to `true` to re-enable drop shadow, or `false` for flat Apple HIG look
    private let enableDropShadow: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Upper Note Content Preview Area
            VStack(alignment: .leading, spacing: 6) {
                let previewText = thought.bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
                
                Text(previewText.isEmpty ? "No transcription text recorded." : previewText)
                    .font(.system(size: 14.5, weight: .regular, design: .default))
                    .foregroundStyle(previewText.isEmpty ? Theme.Colors.secondaryText.opacity(0.55) : Theme.Colors.secondaryText)
                    .lineSpacing(4)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Bottom Title Section anchored at the bottom of the note
            HStack(alignment: .center, spacing: 10) {
                Text(thought.displayTitle)
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .foregroundStyle(Theme.Colors.primaryText)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if thought.audioFileName != nil {
                    Image(systemName: "waveform")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.Colors.accent)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .background(Theme.Colors.searchBarSurface)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Theme.Colors.primaryText.opacity(0.06)),
                alignment: .top
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(Theme.Colors.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.Colors.primaryText.opacity(0.07), lineWidth: 1)
        )
        // Apple HIG Flat Style (Change `enableDropShadow = true` above to restore shadow)
        .shadow(
            color: enableDropShadow ? Color.black.opacity(0.04) : Color.clear,
            radius: 6,
            x: 0,
            y: 3
        )
    }
}

struct ThoughtCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            if let thought = MockData.sampleThoughts.first {
                ThoughtCardView(thought: thought)
            }
        }
        .padding()
        .background(Theme.Colors.primaryBackground)
    }
}
