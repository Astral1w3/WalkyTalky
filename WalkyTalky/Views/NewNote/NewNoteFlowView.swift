//
//  NewNoteFlowView.swift
//  WalkyTalky
//
//  Created by Apple Developer on 20/10/2026.
//

import SwiftUI

/// Orchestrates the two-stage thought capture workflow:
/// 1. `DictationPhaseView`: Real-time on-device dictation with dynamic waveform matching `page2.jpg`.
/// 2. `NoteEditingPhaseView`: Review and polish note title, body, audio playback, and walk metrics.
struct NewNoteFlowView: View {
    @Environment(\.dismiss) private var dismiss
    let snapshot: ThoughtSnapshotPayload
    let onSave: (WalkThought) -> Void
    var onDismiss: (() -> Void)? = nil
    
    // MARK: - Flow Phase
    enum FlowPhase {
        case dictating
        case editing(DictationCoordinator.DictationResult)
    }
    
    @State private var currentPhase: FlowPhase = .dictating
    @StateObject private var dictationCoordinator = DictationCoordinator()
    
    var body: some View {
        ZStack {
            switch currentPhase {
            case .dictating:
                DictationPhaseView(
                    snapshot: snapshot,
                    dictationCoordinator: dictationCoordinator,
                    onFinish: { result in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentPhase = .editing(result)
                        }
                    },
                    onCancel: {
                        onDismiss?()
                        dismiss()
                    }
                )
                .transition(.opacity)
                
            case .editing(let result):
                NoteEditingPhaseView(
                    snapshot: snapshot,
                    initialText: result.text,
                    audioFileName: result.audioFileName,
                    audioDuration: result.audioDuration,
                    onSave: { thought in
                        onSave(thought)
                        dismiss()
                    },
                    onDiscard: {
                        onDismiss?()
                        dismiss()
                    }
                )
                .transition(.opacity)
            }
        }
    }
}

struct NewNoteFlowView_Previews: PreviewProvider {
    static var previews: some View {
        NewNoteFlowView(
            snapshot: ThoughtSnapshotPayload(
                stepCount: 1420,
                distanceMeters: 1200,
                sessionDurationSeconds: 900,
                latitude: 40.8518,
                longitude: 14.2681,
                locationName: "Old Port"
            ),
            onSave: { _ in },
            onDismiss: { }
        )
    }
}
