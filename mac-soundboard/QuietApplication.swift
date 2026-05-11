//
//  QuietApplication.swift
//  mac-soundboard
//
//  Created by Doruk Arpali on 11.05.2026.
//


import AppKit

class QuietApplication: NSApplication {
    override func sendEvent(_ event: NSEvent) {
        // For keyDown: try to dispatch normally first.
        // If nothing handles it, drop it silently (no bonk).
        if event.type == .keyDown {
            // Let the responder chain try first
            super.sendEvent(event)
            return
        }
        super.sendEvent(event)
    }

    // This is the actual method that produces the bonk —
    // override it to do nothing.
    override func keyDown(with event: NSEvent) {
        // silence
    }
}

// NSWindow subclass that also swallows unhandled keys
class QuietWindow: NSWindow {
    override func keyDown(with event: NSEvent) {
        // Don't call super — that's what triggers the bonk
    }
}
