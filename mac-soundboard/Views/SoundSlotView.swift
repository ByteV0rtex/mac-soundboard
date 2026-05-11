
//  Created by Doruk Arpali on 9.05.2026.
//
//  SoundSlotView.swift
//  mac-soundboard
//

import SwiftUI

struct SoundSlotView: View {
    @Binding var slot: SoundSlot
    var isPlaying: Bool = false
    var onTap: () -> Void
    var onEdit: () -> Void

    @State private var isPressed = false
    @State private var isHovered = false

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    slot.audioFileURL == nil
                    ? Color.white.opacity(0.04)
                    : slot.color.opacity(isPlaying ? 0.35 : isHovered ? 0.18 : 0.12)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            slot.audioFileURL == nil
                            ? Color.white.opacity(0.08)
                            : slot.color.opacity(isPlaying ? 0.9 : isHovered ? 0.5 : 0.3),
                            lineWidth: isPlaying ? 1.5 : 1
                        )
                }

            // Glow when playing
            if isPlaying {
                RoundedRectangle(cornerRadius: 14)
                    .fill(slot.color.opacity(0.15))
                    .blur(radius: 8)
            }

            // Centered content
            VStack(spacing: 6) {
                Text(slot.emoji)
                    .font(.system(size: 28))

                Text(slot.name)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(
                        slot.audioFileURL == nil
                        ? Color.white.opacity(0.25)
                        : Color.white.opacity(0.85)
                    )
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                if let key = slot.keyBinding {
                    Text(key)
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(slot.color.opacity(0.7))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(slot.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                }
            }
            .padding(10)

            // Edit button — top trailing, independent of content
            if isHovered {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(5)
                                .background(.white.opacity(0.12), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(6)
                .transition(.opacity)
            }
        }
        .scaleEffect(isPressed ? 0.93 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .animation(.easeInOut(duration: 0.12), value: isHovered)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in
                    isPressed = false
                    onTap()
                }
        )
    }
}
