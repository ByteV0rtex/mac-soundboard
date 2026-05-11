//
//  SoundboardProfile.swift
//  mac-soundboard
//
//  Created by Doruk Arpali on 9.05.2026.
//


//
//  SoundboardProfile.swift
//  mac-soundboard
//

import Foundation

struct SoundboardProfile: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var slots: [SoundSlot]

    static func defaultProfile() -> SoundboardProfile {
        SoundboardProfile(
            name: "Default",
            slots: Array(repeating: SoundSlot.empty(), count: 16)
        )
    }
}