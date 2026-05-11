//
//  SlotEditView.swift
//  mac-soundboard
//
//  Created by Doruk Arpali on 9.05.2026.
//


import SwiftUI
import UniformTypeIdentifiers

struct SlotEditView: View {
    @Binding var slot: SoundSlot
    @Environment(\.dismiss) var dismiss

    @State private var isListeningForKey = false
    @State private var tempName: String = ""
    @State private var tempEmoji: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Sound")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(6)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider().opacity(0.15)

            ScrollView {
                VStack(spacing: 20) {

                    // Preview
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(slot.color.opacity(0.2))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(slot.color.opacity(0.4), lineWidth: 1)
                                }
                            Text(slot.emoji)
                                .font(.system(size: 32))
                        }
                        .frame(width: 70, height: 70)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(slot.name.isEmpty ? "Unnamed" : slot.name)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                            Text(slot.playbackMode.rawValue)
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.4))
                            if let key = slot.keyBinding {
                                Text("⌨ \(key)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(slot.color)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Fields
                    VStack(spacing: 12) {

                        // Name
                        EditRow(label: "Name") {
                            TextField("Sound name", text: $slot.name)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13))
                                .foregroundStyle(.white)
                        }

                        // Emoji
                        EditRow(label: "Emoji / Icon") {
                            HStack {
                                TextField("🔊", text: $slot.emoji)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 20))
                                    .frame(width: 40)
                                Text("Type any emoji or short text")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                        }

                        // Color
                        EditRow(label: "Color") {
                            HStack(spacing: 8) {
                                ForEach(SoundSlot.presetColors, id: \.self) { hex in
                                    Circle()
                                        .fill(Color(hex: hex) ?? .blue)
                                        .frame(width: 20, height: 20)
                                        .overlay {
                                            if slot.colorHex == hex {
                                                Circle().strokeBorder(.white, lineWidth: 2)
                                            }
                                        }
                                        .onTapGesture { slot.colorHex = hex }
                                }
                            }
                        }

                        // Audio File
                        EditRow(label: "Audio File") {
                            HStack {
                                if let url = slot.audioFileURL {
                                    Text(url.lastPathComponent)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.7))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                } else {
                                    Text("No file selected")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                                Spacer()
                                Button("Browse") {
                                    pickAudioFile()
                                }
                                .buttonStyle(PillButtonStyle(color: slot.color))
                            }
                        }

                        // Volume
                        EditRow(label: "Volume") {
                            HStack(spacing: 10) {
                                Image(systemName: "speaker.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.4))
                                Slider(value: $slot.volume, in: 0...1)
                                    .tint(slot.color)
                                Image(systemName: "speaker.wave.3.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.4))
                                Text("\(Int(slot.volume * 100))%")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .frame(width: 32, alignment: .trailing)
                            }
                        }

                        // Playback Mode
                        EditRow(label: "Playback") {
                            HStack(spacing: 8) {
                                ForEach(PlaybackMode.allCases, id: \.self) { mode in
                                    Button(action: { slot.playbackMode = mode }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: mode.icon)
                                                .font(.system(size: 10))
                                            Text(mode.rawValue)
                                                .font(.system(size: 11, weight: .medium))
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            slot.playbackMode == mode
                                            ? slot.color.opacity(0.3)
                                            : Color.white.opacity(0.06),
                                            in: RoundedRectangle(cornerRadius: 8)
                                        )
                                        .foregroundStyle(
                                            slot.playbackMode == mode
                                            ? slot.color
                                            : Color.white.opacity(0.4)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Key Binding
                        EditRow(label: "Hotkey") {
                            HStack {
                                if isListeningForKey {
                                    Text("Press any key...")
                                        .font(.system(size: 12))
                                        .foregroundStyle(slot.color)
                                } else if let key = slot.keyBinding {
                                    Text(key)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.8))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                                } else {
                                    Text("None")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                                Spacer()
                                if slot.keyBinding != nil {
                                    Button("Clear") { slot.keyBinding = nil }
                                        .buttonStyle(PillButtonStyle(color: .red))
                                }
                                Button(isListeningForKey ? "Cancel" : "Assign") {
                                    isListeningForKey.toggle()
                                }
                                .buttonStyle(PillButtonStyle(color: slot.color))
                            }
                        }
                        .background(
                            KeyCaptureView(isListening: $isListeningForKey) { key in
                                slot.keyBinding = key
                                isListeningForKey = false
                            }
                            .frame(width: 0, height: 0)
                        )
                    }
                    .padding(.horizontal, 20)

                    // Done button
                    Button("Done") { dismiss() }
                        .buttonStyle(PillButtonStyle(color: slot.color, large: true))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
        }
        .frame(width: 400)
        .background(Color(hex: "#141418")!)
    }

    private func pickAudioFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio, .mp3, .wav, .aiff]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            slot.audioFileURL = panel.url
        }
    }
}

// MARK: - Helper Views

struct EditRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.3))
                .tracking(1)
            content()
                .padding(10)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct PillButtonStyle: ButtonStyle {
    var color: Color
    var large: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: large ? 14 : 11, weight: .semibold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, large ? 24 : 12)
            .padding(.vertical, large ? 10 : 5)
            .frame(maxWidth: large ? .infinity : nil)
            .background(color.opacity(configuration.isPressed ? 0.3 : 0.15), in: RoundedRectangle(cornerRadius: large ? 12 : 8))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

// MARK: - Key capture NSView bridge
struct KeyCaptureView: NSViewRepresentable {
    @Binding var isListening: Bool
    var onKey: (String) -> Void

    func makeNSView(context: Context) -> KeyCaptureNSView {
        let view = KeyCaptureNSView()
        view.onKey = onKey
        return view
    }

    func updateNSView(_ nsView: KeyCaptureNSView, context: Context) {
        nsView.isListening = isListening
        nsView.onKey = onKey
        if isListening { nsView.window?.makeFirstResponder(nsView) }
    }
}

class KeyCaptureNSView: NSView {
    var isListening = false
    var onKey: ((String) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard isListening else { return }
        let key = HotkeyManager.keyCodeToString(Int(event.keyCode))
        onKey?(key)
    }
}
