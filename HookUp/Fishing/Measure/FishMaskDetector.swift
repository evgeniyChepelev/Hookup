import Vision
import UIKit
import CoreVideo

/// Uses Vision's foreground-instance segmentation (iOS 17+) to auto-detect the
/// fish's silhouette in a photo, then estimates its "nose-to-tail" axis as the
/// longest chord of the foreground blob along its principal (PCA) direction.
enum FishMaskDetector {
    struct DetectionResult: Equatable {
        /// Normalized (0...1) point in image space.
        let nose: CGPoint
        /// Normalized (0...1) point in image space.
        let tail: CGPoint
    }

    static func detectFishAxis(in image: UIImage) -> DetectionResult? {
        guard let cgImage = image.cgImage else { return nil }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])

        do {
            try handler.perform([request])
        } catch {
            return nil
        }

        guard let result = request.results?.first, !result.allInstances.isEmpty else { return nil }

        guard let maskBuffer = try? result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler) else {
            return nil
        }

        return axisEndpoints(fromMask: maskBuffer)
    }

    private static func axisEndpoints(fromMask pixelBuffer: CVPixelBuffer) -> DetectionResult? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        guard width > 0, height > 0, let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
        let buffer = base.assumingMemoryBound(to: UInt8.self)

        // Downsample the scan so this stays fast on high-resolution photos.
        let stride = max(1, min(width, height) / 200)

        var points: [(x: Double, y: Double)] = []
        var y = 0
        while y < height {
            let row = buffer + y * bytesPerRow
            var x = 0
            while x < width {
                if row[x] > 128 {
                    points.append((Double(x), Double(y)))
                }
                x += stride
            }
            y += stride
        }

        guard points.count > 4 else { return nil }

        let n = Double(points.count)
        let meanX = points.reduce(0) { $0 + $1.x } / n
        let meanY = points.reduce(0) { $0 + $1.y } / n

        var sxx = 0.0, sxy = 0.0, syy = 0.0
        for p in points {
            let dx = p.x - meanX
            let dy = p.y - meanY
            sxx += dx * dx
            sxy += dx * dy
            syy += dy * dy
        }
        sxx /= n; sxy /= n; syy /= n

        // Principal axis of the foreground blob (2x2 symmetric-matrix eigenvector).
        let theta = 0.5 * atan2(2 * sxy, sxx - syy)
        let dirX = cos(theta)
        let dirY = sin(theta)

        var minProj = Double.greatestFiniteMagnitude
        var maxProj = -Double.greatestFiniteMagnitude
        var minPoint = points[0]
        var maxPoint = points[0]

        for p in points {
            let proj = (p.x - meanX) * dirX + (p.y - meanY) * dirY
            if proj < minProj { minProj = proj; minPoint = p }
            if proj > maxProj { maxProj = proj; maxPoint = p }
        }

        let nose = CGPoint(x: minPoint.x / Double(width), y: minPoint.y / Double(height))
        let tail = CGPoint(x: maxPoint.x / Double(width), y: maxPoint.y / Double(height))
        return DetectionResult(nose: nose, tail: tail)
    }
}

private extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
