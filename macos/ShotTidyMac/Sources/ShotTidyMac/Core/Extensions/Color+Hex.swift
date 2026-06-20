//
//  Color+Hex.swift
//  ShotTidyMac
//

import SwiftUI
import AppKit

extension Color {

    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else {
            self = Color.gray
            return
        }

        let r = Double((value & 0xFF0000) >> 16) / 255.0
        let g = Double((value & 0x00FF00) >> 8) / 255.0
        let b = Double(value & 0x0000FF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? NSColor.gray
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ns.getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = Int((r * 255).rounded())
        let gi = Int((g * 255).rounded())
        let bi = Int((b * 255).rounded())
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
}
