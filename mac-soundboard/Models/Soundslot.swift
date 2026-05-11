
//  Created by Doruk Arpali on 9.05.2026.
//
//
//  SoundSlot.swift
//  mac-soundboard
//

import SwiftUI
import Foundation

enum PlaybackMode: String, CaseIterable, Codable {
    case oneShot   = "One Shot"   // every press plays from start
    case toggle    = "Toggle"     // press starts, press again stops
    case hold      = "Hold"       // plays while key held, stops on release

    var icon: String {
        switch self {
        case .oneShot: return "play.fill"
        case .toggle:  return "repeat"
        case .hold:    return "hand.point.up.fill"
        }
    }
}

struct SoundSlot: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String = "Empty"
    var emoji: String = "🔊"
    var colorHex: String = "#4A9EFF"
    var audioFileURL: URL? = nil
    var volume: Double = 0.8
    var playbackMode: PlaybackMode = .oneShot
    var keyBinding: String? = nil  // e.g. "F1", "1", "q"
    var isEnabled: Bool = true

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    // Placeholder slot
    static func empty() -> SoundSlot {
        SoundSlot()
    }

    static let presetColors: [String] = [
        "#4A9EFF", "#FF6B6B", "#51CF66", "#FFD43B",
        "#CC5DE8", "#FF922B", "#20C997", "#F06595",
        "#74C0FC", "#A9E34B", "#FFA94D", "#E599F7"
    ]
}

// MARK: - Color Hex Extension
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        guard let components = NSColor(self).usingColorSpace(.sRGB)?.cgColor.components,
              components.count >= 3 else { return "#4A9EFF" }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
