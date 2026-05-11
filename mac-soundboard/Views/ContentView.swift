
//  Created by Doruk Arpali on 9.05.2026.
//
//  ContentView.swift
//  mac-soundboard
//

import SwiftUI

struct ContentView: View {
    @StateObject var audioEngine = AudioEngine()
    @StateObject var hotkeyManager = HotkeyManager.shared

    @State private var selection: SidebarItem = .soundboard
    @State private var slots: [SoundSlot] = Array(repeating: SoundSlot.empty(), count: 16)

    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(spacing: 0) {
                // App title
                HStack(spacing: 8) {
                    Text("🎛️")
                        .font(.system(size: 20))
                    Text("Soundboard")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 14)

                Divider().opacity(0.1)

                // Nav items
                VStack(spacing: 2) {
                    ForEach(SidebarItem.allCases) { item in
                        SidebarRowView(item: item, isSelected: selection == item)
                            .onTapGesture { selection = item }
                    }
                }
                .padding(8)

                Spacer()

                // Status indicator
                Divider().opacity(0.1)
                HStack(spacing: 6) {
                    Circle()
                        .fill(audioEngine.isRunning ? Color(hex: "#51CF66")! : Color(hex: "#FF6B6B")!)
                        .frame(width: 6, height: 6)
                    Text(audioEngine.isRunning ? "Engine running" : "Engine stopped")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.35))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(hex: "#0F0F12")!)
            .navigationSplitViewColumnWidth(180)
        } detail: {
            ZStack {
                Color(hex: "#141418")!.ignoresSafeArea()

                switch selection {
                case .soundboard:
                    SoundboardView(slots: $slots)
                        .environmentObject(audioEngine)
                case .mixer:
                    MixerView(slots: $slots)
                        .environmentObject(audioEngine)
                case .settings:
                    SettingsView()
                        .environmentObject(audioEngine)
                        .environmentObject(hotkeyManager)
                }
            }
        }
        .onAppear {
            audioEngine.start()
            hotkeyManager.start()
        }
    }
}

// MARK: - Sidebar Item
enum SidebarItem: String, CaseIterable, Identifiable {
    case soundboard, mixer, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .soundboard: "Soundboard"
        case .mixer:      "Mixer"
        case .settings:   "Settings"
        }
    }

    var icon: String {
        switch self {
        case .soundboard: "square.grid.3x3.fill"
        case .mixer:      "slider.horizontal.3"
        case .settings:   "gearshape.fill"
        }
    }
}

struct SidebarRowView: View {
    let item: SidebarItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.4))
                .frame(width: 18)
            Text(item.title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular, design: .rounded))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            isSelected
            ? Color.white.opacity(0.1)
            : Color.clear,
            in: RoundedRectangle(cornerRadius: 8)
        )
        .contentShape(Rectangle())
    }
}
