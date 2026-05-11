//
//  mac_soundboardApp.swift
//  mac-soundboard
//
//  Created by Doruk Arpali on 9.05.2026.
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Swap every window for a QuietWindow to kill the bonk sound
        for window in NSApp.windows {
            swapToQuietWindow(window)
        }
    }

    private func swapToQuietWindow(_ original: NSWindow) {
        guard !(original is QuietWindow) else { return }
        let quiet = QuietWindow(
            contentRect: original.frame,
            styleMask:   original.styleMask,
            backing:     .buffered,
            defer:       false
        )
        quiet.contentView        = original.contentView
        quiet.title              = original.title
        quiet.isReleasedWhenClosed = false
        quiet.makeKeyAndOrderFront(nil)
        original.close()
    }
}

@main
struct MacSoundboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

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
