//
//  ContentView.swift
//  PencilKitTesting
//
//  Created by James Booth on 21/06/2024.

import SwiftUI
import PencilKit

struct ContentView: View {
    @State private var canvasView = PKCanvasView()
    @State private var savedStrokes: [PKStroke] = []
    @State private var animationTimer: Timer?
    @State private var currentStrokeIndex: Int = 0
    @State private var animationParametricValue: CGFloat = 0
    @State private var animationLastFrameTime = Date()

    var body: some View {
        VStack {
            CanvasView(canvasView: $canvasView)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
            HStack(spacing: 32) {
                Button(action: {
                    clearCanvas()
                }) {
                    Text("Clear")
                }
                Button(action: {
                    replayStrokes()
                }) {
                    Text("Replay")
                }
            }
            .padding()
        }
        .padding()
    }

    func clearCanvas() {
        canvasView.drawing = PKDrawing()
    }

    func replayStrokes() {
        savedStrokes = canvasView.drawing.strokes
        canvasView.drawing = PKDrawing()
        
        guard !savedStrokes.isEmpty else { return }

        currentStrokeIndex = 0
        animationParametricValue = 0
        animationLastFrameTime = Date()

        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { _ in self.stepAnimation() }
    }

    func stepAnimation() {
        guard currentStrokeIndex < savedStrokes.count else {
            animationTimer?.invalidate()
            return
        }

        let stroke = savedStrokes[currentStrokeIndex]
        let path = stroke.path
        let currentTime = Date()
        let delta = currentTime.timeIntervalSince(animationLastFrameTime)
        animationLastFrameTime = currentTime

        animationParametricValue = path.parametricValue(animationParametricValue, offsetBy: .time(delta))

        // Create a new path up to the current parametric value
        var newPathPoints: [PKStrokePoint] = []
        for i in 0..<Int(animationParametricValue) {
            if i < path.count {
                newPathPoints.append(path[i])
            }
        }

        let newStrokePath = PKStrokePath(controlPoints: newPathPoints, creationDate: path.creationDate)
        let newStroke = PKStroke(ink: stroke.ink, path: newStrokePath)

        // Update the drawing incrementally
        var currentDrawing = canvasView.drawing
        if currentStrokeIndex < currentDrawing.strokes.count {
            currentDrawing.strokes[currentStrokeIndex] = newStroke
        } else {
            currentDrawing.strokes.append(newStroke)
        }
        canvasView.drawing = currentDrawing

        // Move to the next stroke if the current one is fully drawn
        if animationParametricValue >= CGFloat(path.count - 1) {
            animationParametricValue = 0
            currentStrokeIndex += 1
        }
    }
}

struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .systemBlue, width: 10)
        canvasView.backgroundColor = .clear
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}

#Preview {
    ContentView()
}
