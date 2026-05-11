//
//  main.swift
//  mac-soundboard
//
//  Created by Doruk Arpali on 9.05.2026.
//


import AppKit
import SwiftUI

// QuietApplication swallows unhandled keyDown → no bonk sound
class QuietApplication: NSApplication {
    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown {
            // Attempt normal dispatch; if unhandled, swallow silently
            if let window = keyWindow, let responder = window.firstResponder {
                let handled = responder.tryToPerform(#selector(NSResponder.keyDown(with:)), with: event)
                if handled { return }
            }
            // Unhandled — swallow instead of bonk
            return
        }
        super.sendEvent(event)
    }
}

// Entry point — must remove @main from MacSoundboardApp.swift
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
