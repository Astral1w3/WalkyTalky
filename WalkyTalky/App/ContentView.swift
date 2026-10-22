//
//  ContentView.swift
//  WalkyTalky
//
//  Created by Angelo Marcone on 19/10/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \WalkThought.createdAt, order: .reverse) private var thoughts: [WalkThought]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: Theme.Layout.standardPadding) {
            Image(systemName: Theme.Symbols.steps)
                .font(.system(size: 44))
                .foregroundStyle(Theme.Colors.accent)
            
            Text("Walky Talky")
                .font(Theme.Typography.largeTitle)
                .foregroundStyle(Theme.Colors.primaryText)
            
            Text("100% Offline Walking Thoughts")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.secondaryText)
            
            HStack(spacing: 8) {
                Text("SWIFTDATA ACTIVE")
                    .walkyTagBadge(isDark: false)
                
                Text("\(thoughts.count) NOTES")
                    .walkyTagBadge(isDark: true)
            }
            
            if thoughts.isEmpty {
                VStack(spacing: 8) {
                    Text("No thoughts recorded yet.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.secondaryText)
                    
                    Button(action: insertSampleNote) {
                        Text("Add Sample Thought")
                            .font(Theme.Typography.callout)
                            .fontWeight(.medium)
                            .foregroundStyle(Theme.Colors.accent)
                    }
                }
                .padding()
                .walkyCardStyle()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(thoughts.prefix(3)) { thought in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(thought.displayTitle)
                                    .font(Theme.Typography.headline)
                                    .foregroundStyle(Theme.Colors.primaryText)
                                Text(thought.formattedDate)
                                    .font(Theme.Typography.footnote)
                                    .foregroundStyle(Theme.Colors.secondaryText)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: Theme.Symbols.steps)
                                Text(thought.formattedSteps)
                                    .font(Theme.Typography.metricSmall)
                            }
                            .foregroundStyle(Theme.Colors.accent)
                        }
                        .padding(.vertical, 4)
                        if thought.id != thoughts.prefix(3).last?.id {
                            Divider()
                        }
                    }
                }
                .walkyCardStyle()
            }
        }
        .padding(Theme.Layout.standardPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.primaryBackground)
    }
    
    private func insertSampleNote() {
        if let first = MockData.sampleThoughts.first {
            modelContext.insert(first)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .modelContainer(MockData.previewContainer)
    }
}
