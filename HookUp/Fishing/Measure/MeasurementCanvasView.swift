import SwiftUI
import AVFoundation

/// Photo overlay with two draggable line handles: one to trace the fish
/// (nose-to-tail), one to trace a reference object of known real-world length.
struct MeasurementCanvasView: View {
    let image: UIImage
    @Binding var fishStart: CGPoint
    @Binding var fishEnd: CGPoint
    @Binding var referenceStart: CGPoint
    @Binding var referenceEnd: CGPoint
    var autoDetected: FishMaskDetector.DetectionResult?

    @State private var hasPositionedFish = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width, height: geo.size.height)

                Path { path in
                    path.move(to: fishStart)
                    path.addLine(to: fishEnd)
                }
                .stroke(Color.yellow, style: StrokeStyle(lineWidth: 3, lineCap: .round))

                Path { path in
                    path.move(to: referenceStart)
                    path.addLine(to: referenceEnd)
                }
                .stroke(Color.cyan, style: StrokeStyle(lineWidth: 3, lineCap: .round))

                handle(binding: $fishStart, color: .yellow)
                handle(binding: $fishEnd, color: .yellow)
                handle(binding: $referenceStart, color: .cyan)
                handle(binding: $referenceEnd, color: .cyan)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear { positionIfNeeded(containerSize: geo.size) }
            .onChange(of: autoDetected) { _, _ in positionIfNeeded(containerSize: geo.size) }
        }
    }

    private func handle(binding: Binding<CGPoint>, color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 26, height: 26)
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .shadow(radius: 2)
            .position(binding.wrappedValue)
            .gesture(
                DragGesture(coordinateSpace: .local)
                    .onChanged { value in binding.wrappedValue = value.location }
            )
    }

    private func positionIfNeeded(containerSize: CGSize) {
        guard containerSize.width > 0, containerSize.height > 0 else { return }

        if referenceStart == .zero && referenceEnd == .zero {
            referenceStart = CGPoint(x: containerSize.width * 0.35, y: containerSize.height * 0.85)
            referenceEnd = CGPoint(x: containerSize.width * 0.65, y: containerSize.height * 0.85)
        }

        guard !hasPositionedFish else { return }

        if let detected = autoDetected {
            fishStart = viewPoint(forNormalized: detected.nose, containerSize: containerSize)
            fishEnd = viewPoint(forNormalized: detected.tail, containerSize: containerSize)
            hasPositionedFish = true
        } else if fishStart == .zero && fishEnd == .zero {
            fishStart = CGPoint(x: containerSize.width * 0.25, y: containerSize.height * 0.5)
            fishEnd = CGPoint(x: containerSize.width * 0.75, y: containerSize.height * 0.5)
        }
    }

    private func viewPoint(forNormalized normalized: CGPoint, containerSize: CGSize) -> CGPoint {
        let rect = AVMakeRect(aspectRatio: image.size, insideRect: CGRect(origin: .zero, size: containerSize))
        return CGPoint(x: rect.minX + normalized.x * rect.width, y: rect.minY + normalized.y * rect.height)
    }
}
