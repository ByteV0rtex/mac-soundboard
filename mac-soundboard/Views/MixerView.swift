
//
//  Created by Doruk Arpali on 9.05.2026.
//
//  MixerView.swift
//  mac-soundboard
//


import SwiftUI

struct MixerView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @Binding var slots: [SoundSlot]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Mixer")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Divider().opacity(0.1)

            ScrollView {
                VStack(spacing: 12) {

                    // Master + Mic
                    HStack(spacing: 12) {
                        MixerChannelView(
                            label: "Master",
                            emoji: "🔈",
                            color: .white,
                            volume: Binding(
                                get: { Double(audioEngine.masterVolume) },
                                set: { audioEngine.setMasterVolume(Float($0)) }
                            )
                        )
                        MixerChannelView(
                            label: "Mic",
                            emoji: "🎙️",
                            color: Color(hex: "#51CF66")!,
                            volume: Binding(
                                get: { Double(audioEngine.micVolume) },
                                set: { audioEngine.setMicVolume(Float($0)) }
                            )
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    Divider()
                        .padding(.horizontal, 20)
                        .opacity(0.1)

                    Text("SOUNDS")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.3))
                        .tracking(1.5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)

                    let assignedSlots = slots.indices.filter { slots[$0].audioFileURL != nil }

                    if assignedSlots.isEmpty {
                        Text("No sounds assigned yet")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.2))
                            .padding(.top, 20)
                    } else {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                            spacing: 12
                        ) {
                            ForEach(assignedSlots, id: \.self) { index in
                                MixerChannelView(
                                    label: slots[index].name,
                                    emoji: slots[index].emoji,
                                    color: slots[index].color,
                                    volume: Binding(
                                        get: { slots[index].volume },
                                        set: { newVal in
                                            slots[index].volume = newVal
                                            audioEngine.setSlotVolume(Float(newVal), for: slots[index].id)
                                        }
                                    )
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
}

struct MixerChannelView: View {
    let label: String
    let emoji: String
    let color: Color
    @Binding var volume: Double

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(emoji)
                    .font(.system(size: 22))
            }

            VStack(spacing: 6) {
                Text("\(Int(volume * 100))")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(color.opacity(0.8))

                GeometryReader { geo in
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(0.06))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [color.opacity(0.4), color],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(height: geo.size.height * volume)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let clamped = min(1, max(0, 1.0 - (value.location.y / geo.size.height)))
                                volume = clamped
                            }
                    )
                }
                .frame(height: 100)
            }

            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(12)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(0.07), lineWidth: 1)
        }
    }
}
