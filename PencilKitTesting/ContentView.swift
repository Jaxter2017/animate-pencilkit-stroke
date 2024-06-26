//
//  ContentView.swift
//  PencilKitTesting
//
//  Created by James Booth on 21/06/2024.

import SwiftUI
import PencilKit

struct ContentView: View {
    @State private var canvasView1 = PKCanvasView()
    @State private var canvasView2 = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var drawings: [String] = []
    @State private var selectedDrawing: String = ""
    
    @State private var scaledDrawing = PKDrawing()
    @State private var animationTimer: Timer?
    @State private var currentStrokeIndex: Int = 0
    @State private var animationParametricValue: CGFloat = 0
    @State private var animationLastFrameTime = Date()
    
    @State private var isShareSheetPresented = false
    @State private var filesToShare: [URL] = []

    var body: some View {
        VStack {
            HStack {
                ZStack {
                    Color.white
                    VStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(Color.gray)
                            .frame(height: 1)
                            .padding(.bottom, 50)
                        Rectangle()
                            .fill(Color.gray)
                            .frame(height: 1)
                        Spacer()
                    }
                    CanvasView(canvasView: $canvasView1)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .border(Color.gray, width: 1)
                }
                CanvasView(canvasView: $canvasView2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    .border(Color.gray, width: 1)
            }
            HStack(spacing: 32) {
                Button(action: clearCanvas) {
                    Text("Clear")
                }
                Button(action: copyDrawingWithAnimation) {
                    Text("Draw")
                }
                Button(action: saveDrawing) {
                    Text("Save Drawing")
                }
                Picker("Load Drawing", selection: $selectedDrawing) {
                    ForEach(drawings, id: \.self) { drawing in
                        Text(drawing)
                    }
                }
                .onChange(of: selectedDrawing) { oldValue, newValue in
                    if !newValue.isEmpty {
                        loadDrawing(named: newValue)
                    }
                }
                Button(action: deleteDrawing) {
                    Text("Delete Drawing")
                }
                .disabled(selectedDrawing.isEmpty)
                Button(action: {
                    print("Button tapped")
                    prepareFilesForSharing()
                    print("filesToShare after preparation: \(filesToShare)")
                    if !filesToShare.isEmpty {
                        isShareSheetPresented = true
                    } else {
                        print("No files to share after preparation")
                    }
                }) {
                    Text("Share Drawings")
                }
                .sheet(isPresented: $isShareSheetPresented) {
                    if !filesToShare.isEmpty {
                        ActivityView(activityItems: filesToShare)
                    } else {
                        Text("No files to share")
                    }
                }
                .onChange(of: isShareSheetPresented) { oldValue, newValue in
                    if newValue {
                        print("Presenting ActivityView with files: \(filesToShare)")
                    } else {
                        print("Sheet dismissed")
                    }
                }
            }
            .padding()
        }
        .padding()
        .statusBarHidden()
        .onAppear {
            loadDrawingsList()
            if let firstDrawing = drawings.first {
                selectedDrawing = firstDrawing
            }
        }
    }
    
    func clearCanvas() {
        canvasView1.drawing = PKDrawing()
        canvasView2.drawing = PKDrawing()
    }
    
    func prepareFilesForSharing() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let drawingsFolder = documentsURL.appendingPathComponent("Drawings")
        print("Preparing files from folder: \(drawingsFolder.path)")
        do {
            let files = try fileManager.contentsOfDirectory(at: drawingsFolder, includingPropertiesForKeys: nil)
            filesToShare = files
            print("Retrieved files: \(files)")
            print("filesToShare is now: \(filesToShare)")
        } catch {
            print("Error preparing files for sharing: \(error)")
        }
    }
    
    struct ActivityView: UIViewControllerRepresentable {
        let activityItems: [Any]
        
        func makeUIViewController(context: Context) -> UIActivityViewController {
            let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            return controller
        }

        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    }
    
    func loadDrawingsList() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let drawingsFolder = documentsURL.appendingPathComponent("Drawings")

        // Check if Drawings folder exists in documents directory
        if !fileManager.fileExists(atPath: drawingsFolder.path) {
            do {
                try fileManager.createDirectory(at: drawingsFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating directory: \(error)")
            }
        }

        // Load drawings from documents directory
        do {
            let documentDrawingFiles = try fileManager.contentsOfDirectory(at: drawingsFolder, includingPropertiesForKeys: nil)
            let documentDrawingFileNames = documentDrawingFiles.map { $0.lastPathComponent }
            drawings = documentDrawingFileNames
        } catch {
            print("Error accessing documents directory: \(error)")
        }
    }

    func loadDrawing(named name: String) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let drawingsFolder = documentsURL.appendingPathComponent("Drawings")
        let fileURL = drawingsFolder.appendingPathComponent(name)

        print("Loading drawing from: \(fileURL.path)")

        do {
            let data = try Data(contentsOf: fileURL)
            let drawing = try PKDrawing(data: data)
            canvasView1.drawing = drawing
            print("Loaded drawing: \(name)")
        } catch {
            print("Error loading drawing: \(error)")
        }
    }

    func saveDrawing() {
        let drawing = canvasView1.drawing
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let drawingsFolder = documentsURL.appendingPathComponent("Drawings")

        if !fileManager.fileExists(atPath: drawingsFolder.path) {
            do {
                try fileManager.createDirectory(at: drawingsFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating directory: \(error)")
                return
            }
        }

        // Determine the next index for the file name
        do {
            let documentDrawingFiles = try fileManager.contentsOfDirectory(at: drawingsFolder, includingPropertiesForKeys: nil)
            let indices = documentDrawingFiles.compactMap { fileURL -> Int? in
                return Int(fileURL.deletingPathExtension().lastPathComponent)
            }
            let nextIndex = (indices.max() ?? 0) + 1
            let fileName = "\(nextIndex).drawing"
            let fileURL = drawingsFolder.appendingPathComponent(fileName)

            let data = drawing.dataRepresentation()
            try data.write(to: fileURL)
            loadDrawingsList()  // Refresh the list
            // switch to new drawing
//            loadDrawing(named: fileName)
            selectedDrawing = fileName
        } catch {
            print("Error saving drawing: \(error)")
        }
    }

    func deleteDrawing() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let drawingsFolder = documentsURL.appendingPathComponent("Drawings")
        let fileURL = drawingsFolder.appendingPathComponent(selectedDrawing)

        do {
            try fileManager.removeItem(at: fileURL)
            loadDrawingsList()  // Refresh the list
            selectedDrawing = ""  // Clear the selection
            // wait 1 sec
            let delay = DispatchTime.now() + 0.25
            DispatchQueue.main.asyncAfter(deadline: delay) {
                self.clearCanvas()
            }
        } catch {
            print("Error deleting drawing: \(error)")
        }
    }
    
    func applyTransformation(to drawing: inout PKDrawing, x: CGFloat, y: CGFloat, height: CGFloat, width: CGFloat? = nil) {
        let drawingBounds = drawing.bounds
        let scaleY = height / drawingBounds.height
        let scaleX: CGFloat

        if let width = width {
            scaleX = width / drawingBounds.width
        } else {
            scaleX = scaleY // preserve aspect ratio
        }

        // Calculate the new width based on the preserved aspect ratio if width is not provided
        let scaledWidth = drawingBounds.width * scaleX
        let scaledHeight = drawingBounds.height * scaleY

        // Calculate the translation needed after scaling
        let translationX = x + (scaledWidth - drawingBounds.width * scaleX) / 2 - drawingBounds.minX * scaleX
        let translationY = y + (height - scaledHeight) / 2 - drawingBounds.minY * scaleY

        var transform = CGAffineTransform.identity
        // Scale the drawing
        transform = transform.scaledBy(x: scaleX, y: scaleY)
        // Translate the scaled drawing to the correct position within the bounding box
        transform = transform.translatedBy(x: translationX / scaleX, y: translationY / scaleY)
        
        var transformedStrokes = [PKStroke]()
        for stroke in drawing.strokes {
            let transformedPoints = stroke.path.map { point -> PKStrokePoint in
                let transformedLocation = point.location.applying(transform)
                return PKStrokePoint(location: transformedLocation, timeOffset: point.timeOffset, size: point.size, opacity: point.opacity, force: point.force, azimuth: point.azimuth, altitude: point.altitude)
            }
            let transformedPath = PKStrokePath(controlPoints: transformedPoints, creationDate: stroke.path.creationDate)
            let transformedStroke = PKStroke(ink: stroke.ink, path: transformedPath)
            transformedStrokes.append(transformedStroke)
        }
        
        drawing = PKDrawing(strokes: transformedStrokes)
    }

    func copyDrawingWithAnimation() {
        canvasView2.drawing = PKDrawing()
        scaledDrawing = canvasView1.drawing
        
        guard !scaledDrawing.strokes.isEmpty else { return }
        
        currentStrokeIndex = 0
        animationParametricValue = 0
        animationLastFrameTime = Date()
        animationTimer?.invalidate()
        
//        let smallerBounds = CGRect(x: 100, y: 300, width: 400, height: 100)
        
//        applyTransformation(to: &scaledDrawing, with: smallerBounds)
        applyTransformation(to: &scaledDrawing, x: 100, y: 300, height: 100)
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { _ in stepAnimation() }
    }

    func stepAnimation() {
        guard currentStrokeIndex < scaledDrawing.strokes.count else {
            animationTimer?.invalidate()
            return
        }
        
        let stroke = scaledDrawing.strokes[currentStrokeIndex]
        let path = stroke.path
        let delta = Date().timeIntervalSince(animationLastFrameTime)
        animationLastFrameTime = Date()

        animationParametricValue = path.parametricValue(animationParametricValue, offsetBy: .time(delta))

        var newPathPoints: [PKStrokePoint] = []
        for i in 0..<Int(animationParametricValue) where i < path.count {
            newPathPoints.append(path[i])
        }

        let newStrokePath = PKStrokePath(controlPoints: newPathPoints, creationDate: path.creationDate)
        let newStroke = PKStroke(ink: stroke.ink, path: newStrokePath)

        var currentDrawing = canvasView2.drawing
        if currentStrokeIndex < currentDrawing.strokes.count {
            currentDrawing.strokes[currentStrokeIndex] = newStroke
        } else {
            currentDrawing.strokes.append(newStroke)
        }
        canvasView2.drawing = currentDrawing

        if animationParametricValue >= CGFloat(path.count - 1) {
            animationParametricValue = 0
            currentStrokeIndex += 1
        }
    }
}

struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let picker = PKToolPicker()

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .systemBlue, width: 10)
        canvasView.backgroundColor = .clear
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        picker.addObserver(canvasView)
        picker.setVisible(true, forFirstResponder: uiView)
        DispatchQueue.main.async {
            uiView.becomeFirstResponder()
        }
    }
}

#Preview {
    ContentView()
}
