
//  Created by Doruk Arpali on 9.05.2026.
//
//  SettingsView.swift
//  mac-soundboard
//


import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @EnvironmentObject var hotkeyManager: HotkeyManager

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Divider().opacity(0.1)

            ScrollView {
                VStack(spacing: 16) {

                    // Audio Devices
                    SettingsSection(title: "Audio Devices") {
                        VStack(spacing: 12) {

                            // Mic input
                            DevicePickerRow(
                                label: "Microphone",
                                subtitle: "Your voice input",
                                devices: audioEngine.availableInputDevices.map { $0.name },
                                selected: Binding(
                                    get: {
                                        audioEngine.availableInputDevices
                                            .first(where: { $0.id == audioEngine.selectedMicID })?.name
                                            ?? audioEngine.availableInputDevices.first?.name
                                            ?? "Default"
                                    },
                                    set: { name in
                                        if let device = audioEngine.availableInputDevices.first(where: { $0.name == name }) {
                                            audioEngine.selectedMicID = device.id
                                        }
                                    }
                                )
                            )

                            Divider().opacity(0.1)

                            // Output (virtual mic / BlackHole)
                            DevicePickerRow(
                                label: "Output Device",
                                subtitle: "Set this as mic in Discord / OBS",
                                devices: audioEngine.availableOutputDevices.map { $0.name },
                                selected: Binding(
                                    get: {
                                        audioEngine.availableOutputDevices
                                            .first(where: { $0.id == audioEngine.selectedOutputID })?.name
                                            ?? audioEngine.availableOutputDevices.first?.name
                                            ?? "Default"
                                    },
                                    set: { name in
                                        if let device = audioEngine.availableOutputDevices.first(where: { $0.name == name }) {
                                            audioEngine.selectedOutputID = device.id
                                        }
                                    }
                                )
                            )

                            Divider().opacity(0.1)

                            // BlackHole status
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("BlackHole")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.8))
                                    Text("Required for virtual mic in Discord/OBS")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.white.opacity(0.35))
                                }
                                Spacer()
                                let isInstalled = audioEngine.availableOutputDevices.contains(where: { $0.name.contains("BlackHole") })
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(isInstalled ? Color(hex: "#51CF66")! : Color(hex: "#FF6B6B")!)
                                        .frame(width: 7, height: 7)
                                    Text(isInstalled ? "Installed" : "Not found")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                                if !isInstalled {
                                    Button("Install") {
                                        NSWorkspace.shared.open(URL(string: "https://github.com/ExistentialAudio/BlackHole")!)
                                    }
                                    .buttonStyle(PillButtonStyle(color: Color(hex: "#4A9EFF")!))
                                }
                            }
                        }
                    }

                    // Global Hotkeys
                    SettingsSection(title: "Global Hotkeys") {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Accessibility Permission")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.8))
                                Text("Required to capture hotkeys in any app")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.35))
                            }
                            Spacer()
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(hotkeyManager.hasAccessibility ? Color(hex: "#51CF66")! : Color(hex: "#FF6B6B")!)
                                    .frame(width: 7, height: 7)
                                Text(hotkeyManager.hasAccessibility ? "Granted" : "Not granted")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            if !hotkeyManager.hasAccessibility {
                                Button("Grant") { hotkeyManager.requestAccessibility() }
                                    .buttonStyle(PillButtonStyle(color: Color(hex: "#4A9EFF")!))
                            }
                        }
                    }

                    // About
                    SettingsSection(title: "About") {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("mac-soundboard")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.8))
                                Text("Personal tool. MIT License.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.35))
                            }
                            Spacer()
                            Button("GitHub") {
                                NSWorkspace.shared.open(URL(string: "https://github.com/ByteV0rtex/mac-soundboard")!)
                            }
                            .buttonStyle(PillButtonStyle(color: .white.opacity(0.5)))
                        }
                    }
                }
                .padding(20)
            }
        }
        .onAppear {
            audioEngine.fetchDevices()
        }
    }
}

struct DevicePickerRow: View {
    let label: String
    let subtitle: String
    let devices: [String]
    @Binding var selected: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.35))
            }
            Spacer()
            if devices.isEmpty {
                Text("No devices found")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.3))
            } else {
                Picker("", selection: $selected) {
                    ForEach(devices, id: \.self) { device in
                        Text(device).tag(device)
                    }
                }
                .frame(width: 180)
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.3))
                .tracking(1.5)

            content()
                .padding(14)
                .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.white.opacity(0.07), lineWidth: 1)
                }
        }
    }
}
