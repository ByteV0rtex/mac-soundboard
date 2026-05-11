//
//  mac_soundboardApp.swift
//  mac-soundboard
//
//  Created by Doruk Arpali on 9.05.2026.
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var localMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Local monitor catches key events when THIS app is focused
        // Returning nil from the handler swallows the event — no bonk
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Return the event so SwiftUI controls still work (text fields etc.)
            // Only swallow if nothing handled it — but we can't know that here,
            // so we return it and let QuietApplication.keyDown be the last resort
            return event
        }

        // Verify QuietApplication is active
        if NSApp is QuietApplication {
            print("✅ QuietApplication active")
        } else {
            print("⚠️ QuietApplication NOT active — NSPrincipalClass may not be set")
        }
    }
}

@main
struct MacSoundboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 520)
                .background(BonkSuppressor())
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

// NSViewRepresentable that overrides keyDown at the window level
struct BonkSuppressor: NSViewRepresentable {
    func makeNSView(context: Context) -> SilentView {
        let view = SilentView()
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }
    func updateNSView(_ nsView: SilentView, context: Context) {}
}

class SilentView: NSView {
    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        // Swallow unhandled key events — no bonk
        // SwiftUI controls handle their own key events before this is reached
    }
}
