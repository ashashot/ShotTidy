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
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
