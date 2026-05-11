//
//  mac_soundboardApp.swift
//  mac-soundboard
//
//  Created by Doruk Arpali on 9.05.2026.
//

import SwiftUI
import AppKit

// Suppress the macOS "bonk" sound for unhandled key events
class SilentApplication: NSApplication {
    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown {
            // Let SwiftUI/AppKit handle it normally, but if nothing handles it
            // we catch it here so the bonk sound never fires
            super.sendEvent(event)
            return
        }
        super.sendEvent(event)
    }

    override func keyDown(with event: NSEvent) {
        // swallow unhandled key events silently
    }
}


struct MacSoundboardApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 520)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
