import SwiftUI

struct DraggableResizableRectangle: View {
    @State private var position = CGPoint(x: 100, y: 100)
    @State private var size = CGSize(width: 150, height: 150)
    @State private var dragOffset = CGSize.zero

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: size.width, height: size.height)
                .position(x: position.x + dragOffset.width, y: position.y + dragOffset.height)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            position.x += value.translation.width
                            position.y += value.translation.height
                            dragOffset = .zero
                        }
                )
                .overlay(
                    ResizableHandles(position: $position, size: $size)
                )
        }
    }
}

struct ResizableHandles: View {
    @Binding var position: CGPoint
    @Binding var size: CGSize

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Handle(position: .topLeading, rectPosition: $position, size: $size, geometry: geometry)
                Handle(position: .topTrailing, rectPosition: $position, size: $size, geometry: geometry)
                Handle(position: .bottomLeading, rectPosition: $position, size: $size, geometry: geometry)
                Handle(position: .bottomTrailing, rectPosition: $position, size: $size, geometry: geometry)
            }
        }
    }
}

struct Handle: View {
    enum HandlePosition {
        case topLeading, topTrailing, bottomLeading, bottomTrailing
    }

    let position: HandlePosition
    @Binding var rectPosition: CGPoint
    @Binding var size: CGSize
    let geometry: GeometryProxy

    var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 20, height: 20)
            .position(handlePosition(in: geometry))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        switch position {
                        case .topLeading:
                            size.width -= value.translation.width
                            size.height -= value.translation.height
                            rectPosition.x += value.translation.width / 2
                            rectPosition.y += value.translation.height / 2
                        case .topTrailing:
                            size.width += value.translation.width
                            size.height -= value.translation.height
                            rectPosition.x += value.translation.width / 2
                            rectPosition.y += value.translation.height / 2
                        case .bottomLeading:
                            size.width -= value.translation.width
                            size.height += value.translation.height
                            rectPosition.x += value.translation.width / 2
                            rectPosition.y += value.translation.height / 2
                        case .bottomTrailing:
                            size.width += value.translation.width
                            size.height += value.translation.height
                            rectPosition.x += value.translation.width / 2
                            rectPosition.y += value.translation.height / 2
                        }
                    }
                    .onEnded { value in
                        if size.width < 20 { size.width = 20 }
                        if size.height < 20 { size.height = 20 }
                    }
            )
    }

    private func handlePosition(in geometry: GeometryProxy) -> CGPoint {
        switch position {
        case .topLeading:
            return CGPoint(x: 0, y: 0)
        case .topTrailing:
            return CGPoint(x: geometry.size.width, y: 0)
        case .bottomLeading:
            return CGPoint(x: 0, y: geometry.size.height)
        case .bottomTrailing:
            return CGPoint(x: geometry.size.width, y: geometry.size.height)
        }
    }
}
