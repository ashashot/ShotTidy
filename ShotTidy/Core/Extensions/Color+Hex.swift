//
//  Color+Hex.swift
//  ShotTidy
//
//  Hex <-> Color conversion for persisting custom category colors.
//  Colors are stored as "#RRGGBB" strings in SwiftData (CloudKit-safe).
//

import SwiftUI

extension Color {

    /// Creates a color from a "#RRGGBB" (or "RRGGBB") hex string.
    /// Falls back to system gray for malformed input.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else {
            self = Color(.systemGray)
            return
        }

        let r = Double((value & 0xFF0000) >> 16) / 255.0
        let g = Double((value & 0x00FF00) >> 8) / 255.0
        let b = Double(value & 0x0000FF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }

    /// Returns a "#RRGGBB" representation of the color.
    /// Resolves through UIColor so dynamic/system colors get a concrete value.
    func toHex() -> String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)

        let ri = Int((r * 255).rounded())
        let gi = Int((g * 255).rounded())
        let bi = Int((b * 255).rounded())
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
}
