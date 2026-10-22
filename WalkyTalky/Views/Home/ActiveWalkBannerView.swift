//
//  ActiveWalkBannerView.swift
//  WalkyTalky
//
//  Created by Apple Developer on 20/10/2026.
//

import SwiftUI

/// Banner displayed at the top of the Home View feed.
/// When a walk is active, streams live step count, distance, and duration,
/// and provides pause/resume and stop controls.
/// When idle, offers an immediate one-tap trigger to start an Active Walk session.
struct ActiveWalkBannerView: View {
    @ObservedObject var walkManager: WalkSessionManager
    @State private var isShowingStopConfirmation: Bool = false
    
    var body: some View {
        if walkManager.isWalking {
            activeSessionView
        } else {
            idlePromptView
        }
    }
    
    // MARK: - Active Session State
    private var activeSessionView: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(walkManager.isPaused ? Color.orange : Theme.Colors.accent)
                        .frame(width: 8, height: 8)
                    
                    Text(walkManager.isPaused ? "WALK PAUSED" : "ACTIVE WALK")
                        .font(Theme.Typography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(walkManager.isPaused ? Color.orange : Theme.Colors.accent)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Theme.Colors.badgeSurface)
                .clipShape(Capsule())
                
                Spacer()
                
                // Elapsed time ticker
                HStack(spacing: 4) {
                    Image(systemName: Theme.Symbols.clock)
                        .font(.caption2)
                    Text(walkManager.formattedDuration)
                        .font(Theme.Typography.metricSmall)
                }
                .foregroundStyle(Theme.Colors.primaryText)
            }
            
            // Metrics Row
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Steps")
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(Theme.Colors.secondaryText)
                    Text(walkManager.formattedSteps)
                        .font(Theme.Typography.metricNumber)
                        .foregroundStyle(Theme.Colors.primaryText)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Distance")
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(Theme.Colors.secondaryText)
                    Text(walkManager.formattedDistance)
                        .font(Theme.Typography.metricNumber)
                        .foregroundStyle(Theme.Colors.primaryText)
                }
                
                Spacer()
                
                // Pause / Resume & End Controls
                HStack(spacing: 10) {
                    Button(action: {
                        if walkManager.isPaused {
                            walkManager.resumeWalk()
                        } else {
                            walkManager.pauseWalk()
                        }
                    }) {
                        Image(systemName: walkManager.isPaused ? Theme.Symbols.play : Theme.Symbols.pause)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.Colors.accent)
                            .frame(width: 36, height: 36)
                            .background(Theme.Colors.primaryBackground)
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        isShowingStopConfirmation = true
                    }) {
                        Image(systemName: Theme.Symbols.micStop)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(width: 36, height: 36)
                            .background(Theme.Colors.destructive)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(Theme.Layout.cardPadding)
        .background(Theme.Colors.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardCornerRadius, style: .continuous))
        .confirmationDialog(
            "End Walking Session?",
            isPresented: $isShowingStopConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Walk", role: .destructive) {
                _ = walkManager.stopWalk()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your recorded walk metrics will remain attached to all notes logged during this session.")
        }
    }
    
    // MARK: - Idle State Prompt
    private var idlePromptView: some View {
        HStack(spacing: 12) {
            Image(systemName: Theme.Symbols.steps)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 40, height: 40)
                .background(Theme.Colors.badgeSurface)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Start an Active Walk")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.primaryText)
                
                Text("Tracks live steps and triggers milestone note dictations.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            
            Spacer()
            
            Button(action: {
                walkManager.startWalk()
            }) {
                Text("Start")
                    .font(Theme.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.Colors.accent)
                    .clipShape(Capsule())
            }
        }
        .padding(Theme.Layout.cardPadding)
        .background(Theme.Colors.cardSurface.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardCornerRadius, style: .continuous))
    }
}

struct ActiveWalkBannerView_Previews: PreviewProvider {
    static var previews: some View {
        ActiveWalkBannerView(walkManager: WalkSessionManager())
            .padding()
            .background(Theme.Colors.primaryBackground)
    }
}
