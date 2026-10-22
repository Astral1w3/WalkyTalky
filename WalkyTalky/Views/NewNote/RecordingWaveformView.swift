//
//  RecordingWaveformView.swift
//  WalkyTalky
//
//  Created by Apple Developer on 20/10/2026.
//

import SwiftUI

/// Continuous horizontal audio-frequency waveform line matching the recording mockup (`page2.jpg`).
/// Renders a responsive, smooth, single-line wave that dynamically reacts
/// to live decibel input (`audioLevel`) using continuous trigonometric sine functions.
/// Strictly bounded in both dimensions so it can never exceed the screen or frame boundaries.
struct RecordingWaveformView: View {
    let audioLevel: Float // Normalized 0.0 (silent) to 1.0 (loud)
    var lineColor: Color = Theme.Colors.waveformLine
    var lineWidth: CGFloat = 2.2
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                let width = size.width
                let height = size.height
                guard width > 0, height > 0 else { return }
                
                let midY = height / 2.0
                
                // Continuous monotonic time parameter from timeline (infinitely differentiable, glitch-free)
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                // Strict vertical bounding: displacement must stay within canvas limits
                let safetyMargin: CGFloat = lineWidth + 4.0
                let maxAllowedAmplitude = max(4.0, (height / 2.0) - safetyMargin)
                
                // Normalized audio input clamped between [0.0, 1.0]
                let level = CGFloat(max(0.0, min(1.0, audioLevel)))
                
                // Continuous resting breathing modulation (smooth gentle pulse when silent)
                let breathing = 1.0 + 0.12 * sin(time * 2.0)
                let baseAmplitude: CGFloat = 3.5
                let dynamicAmplitude = baseAmplitude + (maxAllowedAmplitude - baseAmplitude) * level
                let activeAmplitude = min(maxAllowedAmplitude, dynamicAmplitude * breathing)
                
                // 160 sample steps across the screen width for smooth rendering
                let steps = 160
                let stepX = width / CGFloat(steps)
                
                var path = Path()
                path.move(to: CGPoint(x: 0, y: midY))
                
                for i in 1...steps {
                    let currentX = min(width, CGFloat(i) * stepX)
                    let normalizedX = currentX / width // Strictly 0.0 to 1.0
                    
                    // Smooth envelope function: anchors firmly at left & right screen edges (sin(0)=0, sin(pi)=0)
                    // and rises smoothly towards the center
                    let envelope = sin(normalizedX * .pi)
                    
                    // Superposition of continuous harmonic sine waves
                    // Component 1: Primary carrier wave drifting horizontally
                    let wave1 = sin(2.0 * .pi * (normalizedX * 3.0) - (time * 3.2)) * 0.52
                    
                    // Component 2: Counter-harmonic wave creating organic standing wave nodes
                    let wave2 = sin(2.0 * .pi * (normalizedX * 6.5) + (time * 2.1)) * 0.32
                    
                    // Component 3: Fine acoustic detail wave
                    let wave3 = sin(2.0 * .pi * (normalizedX * 12.0) - (time * 4.6)) * 0.16
                    
                    // Combined amplitude is strictly bounded: |0.52 + 0.32 + 0.16| = 1.0
                    let combinedWave = wave1 + wave2 + wave3
                    
                    // Continuous displacement bounded via hyperbolic tangent (tanh)
                    let rawDisplacement = combinedWave * activeAmplitude * envelope
                    let boundedDisplacement = tanh(rawDisplacement / maxAllowedAmplitude) * maxAllowedAmplitude
                    
                    // Clamped final Y guaranteed strictly within [safetyMargin, height - safetyMargin]
                    let finalY = max(safetyMargin, min(height - safetyMargin, midY - boundedDisplacement))
                    
                    path.addLine(to: CGPoint(x: currentX, y: finalY))
                }
                
                context.stroke(
                    path,
                    with: .color(lineColor),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .clipped()
    }
}

struct RecordingWaveformView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Theme.Colors.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("Waveform Preview")
                    .font(Theme.Typography.title3)
                
                RecordingWaveformView(audioLevel: 0.0)
                RecordingWaveformView(audioLevel: 0.4)
                RecordingWaveformView(audioLevel: 0.9)
            }
            .padding()
        }
    }
}
