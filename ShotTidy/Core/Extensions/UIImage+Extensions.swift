//
//  UIImage+Extensions.swift
//  ShotTidy
//
//  UIImage extensions used throughout the app.
//

import UIKit

extension UIImage {
    /// Scales the image down so that its longest side does not exceed maxDim.
    func resized(toMaxDimension maxDim: CGFloat) -> UIImage {
        let size = self.size
        guard size.width > maxDim || size.height > maxDim else { return self }
        let ratio = min(maxDim / size.width, maxDim / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        // Force scale 1 so the output pixel size equals newSize; the default
        // renderer format uses the screen scale (2–3x), which would produce
        // an image 2–3x larger than requested.
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

extension UIImage {
    /// EXIF-style orientation matching `imageOrientation`, for APIs that take a
    /// raw `CGImage` plus orientation (Vision, Foundation Models attachments).
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up:            return .up
        case .upMirrored:    return .upMirrored
        case .down:          return .down
        case .downMirrored:  return .downMirrored
        case .left:          return .left
        case .leftMirrored:  return .leftMirrored
        case .right:         return .right
        case .rightMirrored: return .rightMirrored
        @unknown default:    return .up
        }
    }
}
