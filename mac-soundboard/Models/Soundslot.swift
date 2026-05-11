
//  Created by Doruk Arpali on 9.05.2026.
//
//
//  SoundSlot.swift
//  mac-soundboard
//

import SwiftUI
import Foundation

// Hold mode removed — only oneShot and toggle
enum PlaybackMode: String, CaseIterable, Codable {
    case oneShot = "One Shot"  // every press plays a new instance, sounds layer
    case toggle  = "Toggle"    // first press starts, second press stops

    var icon: String {
        switch self {
        case .oneShot: return "play.fill"
        case .toggle:  return "repeat"
        }
    }
}

struct SoundSlot: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String = "Empty"
    var emoji: String = "🔊"
    var colorHex: String = "#4A9EFF"
    var audioFileURL: URL? = nil
    var volume: Double = 0.8
    var playbackMode: PlaybackMode = .oneShot
    var keyBinding: String? = nil
    var isEnabled: Bool = true

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    static func empty() -> SoundSlot { SoundSlot() }

    static let presetColors: [String] = [
        "#4A9EFF", "#FF6B6B", "#51CF66", "#FFD43B",
        "#CC5DE8", "#FF922B", "#20C997", "#F06595",
        "#74C0FC", "#A9E34B", "#FFA94D", "#E599F7"
    ]
}

extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: h).scanHexInt64(&rgb) else { return nil }
        self.init(
            red:   Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8)  / 255.0,
            blue:  Double( rgb & 0x0000FF)         / 255.0
        )
    }

    func toHex() -> String {
        guard let c = NSColor(self).usingColorSpace(.sRGB)?.cgColor.components, c.count >= 3 else { return "#4A9EFF" }
        return String(format: "#%02X%02X%02X", Int(c[0]*255), Int(c[1]*255), Int(c[2]*255))
    }
}
