//
//  HotkeyManager.swift
//  mac-soundboard
//
//  Created by Doruk Arpali on 9.05.2026.
//


//
//  HotkeyManager.swift
//  mac-soundboard
//

import Cocoa
import Carbon
import Combine

class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()
    private var eventTap: CFMachPort?
    var onKeyPress: ((String) -> Void)?
    var onKeyRelease: ((String) -> Void)?

    @Published var isListening = false
    @Published var hasAccessibility = false

    init() {
        checkAccessibility()
    }

    func checkAccessibility() {
        hasAccessibility = AXIsProcessTrusted()
    }

    func requestAccessibility() {
        let options: [String: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    func start() {
        guard AXIsProcessTrusted() else {
            requestAccessibility()
            return
        }

        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { proxy, type, event, refcon in
                guard let refcon else { return Unmanaged.passRetained(event) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                let keyString = HotkeyManager.keyCodeToString(Int(keyCode))

                if type == .keyDown {
                    DispatchQueue.main.async { manager.onKeyPress?(keyString) }
                } else if type == .keyUp {
                    DispatchQueue.main.async { manager.onKeyRelease?(keyString) }
                }
                return Unmanaged.passRetained(event)
            },
            userInfo: Unmanaged.passRetained(self).toOpaque()
        )

        if let tap = eventTap {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            isListening = true
        }
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        isListening = false
    }

    static func keyCodeToString(_ keyCode: Int) -> String {
        let map: [Int: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P",
            37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\",
            43: ",", 44: "/", 45: "N", 46: "M", 47: ".", 50: "`",
            36: "Return", 48: "Tab", 49: "Space", 51: "Delete",
            53: "Escape", 96: "F5", 97: "F6", 98: "F7", 99: "F3",
            100: "F8", 101: "F9", 103: "F11", 109: "F10", 111: "F12",
            122: "F1", 120: "F2", 118: "F4"
        ]
        return map[keyCode] ?? "Key\(keyCode)"
    }
}
