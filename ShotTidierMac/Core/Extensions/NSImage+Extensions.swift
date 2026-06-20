//
//  NSImage+Extensions.swift
//  ShotTidierMac
//

import AppKit

extension NSImage {

    func resized(toMaxDimension maxDim: CGFloat) -> NSImage {
        let s = self.size
        guard s.width > maxDim || s.height > maxDim else { return self }
        let ratio = min(maxDim / s.width, maxDim / s.height)
        let newSize = NSSize(width: s.width * ratio, height: s.height * ratio)
        let result = NSImage(size: newSize)
        result.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        self.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: s),
            operation: .copy,
            fraction: 1.0
        )
        result.unlockFocus()
        return result
    }

    func jpegData(compressionQuality: CGFloat = 0.85) -> Data? {
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }

    func thumbnailData() -> Data? {
        resized(toMaxDimension: 800).jpegData(compressionQuality: 0.85)
    }
}
