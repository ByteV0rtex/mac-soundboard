
//  Created by Doruk Arpali on 9.05.2026.
//
//  SoundboardView.swift
//  mac-soundboard
//


import SwiftUI

struct SoundboardView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @Binding var slots: [SoundSlot]

    @State private var editingSlotIndex: Int? = nil
    @State private var oneShotFlashing: Set<UUID> = []   // brief flash for oneshot/hold
    @State private var columnCount: Int = 4

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Soundboard")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                // Column count picker
                HStack(spacing: 4) {
                    ForEach([3, 4, 5, 6], id: \.self) { count in
                        Button(action: { columnCount = count }) {
                            Text("\(count)")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(columnCount == count ? .white : .white.opacity(0.35))
                                .frame(width: 24, height: 24)
                                .background(
                                    columnCount == count ? Color.white.opacity(0.12) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 6)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Divider().opacity(0.1)

            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columnCount),
                    spacing: 10
                ) {
                    ForEach(slots.indices, id: \.self) { index in
                        SoundSlotView(
                            slot: $slots[index],
                            isPlaying: isPlaying(slots[index]),
                            onTap: { triggerSlot(at: index) },
                            onEdit: { editingSlotIndex = index }
                        )
                        .aspectRatio(1, contentMode: .fit)
                    }
                }
                .padding(16)
            }
        }
        .sheet(item: editingBinding) { index in
            SlotEditView(slot: $slots[index])
        }
        .onAppear {
            setupHotkeys()
        }
    }

    // MARK: - Playing state

    private func isPlaying(_ slot: SoundSlot) -> Bool {
        switch slot.playbackMode {
        case .toggle: return audioEngine.isTogglePlaying(slot.id)
        default:      return oneShotFlashing.contains(slot.id)
        }
    }

    // MARK: - Sheet binding

    var editingBinding: Binding<Int?> {
        Binding(get: { editingSlotIndex }, set: { editingSlotIndex = $0 })
    }

    // MARK: - Trigger

    private func triggerSlot(at index: Int) {
        let slot = slots[index]
        guard slot.audioFileURL != nil else {
            editingSlotIndex = index
            return
        }
        audioEngine.play(slot: slot)
        if slot.playbackMode != .toggle {
            flashPlaying(slot.id)
        }
    }

    private func flashPlaying(_ id: UUID) {
        oneShotFlashing.insert(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            oneShotFlashing.remove(id)
        }
    }

    // MARK: - Hotkeys

    private func setupHotkeys() {
        HotkeyManager.shared.onKeyPress = { key in
            for (index, slot) in slots.enumerated() {
                if slot.keyBinding == key {
                    triggerSlot(at: index)
                }
            }
        }
        HotkeyManager.shared.onKeyRelease = { key in
            for slot in slots where slot.keyBinding == key && slot.playbackMode == .hold {
                audioEngine.stopSlot(slotID: slot.id)
            }
        }
    }
}

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}
