//
//  UIImage+Extensions.swift
//  ShotTidy
//
//  Расширения UIImage, используемые во всём приложении.
//

import UIKit

extension UIImage {
    /// Масштабирует изображение до максимального размера по большей стороне.
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
