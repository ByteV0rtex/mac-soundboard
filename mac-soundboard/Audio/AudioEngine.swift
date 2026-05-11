//
//  AudioEngine.swift
//  mac-soundboard
//
//  Created by Doruk Arpali on 9.05.2026.
//


import AVFoundation
import Foundation
import Combine

class AudioEngine: ObservableObject {

    // We use separate AVAudioPlayer instances — much simpler and more reliable
    // than AVAudioEngine node management for this use case.
    // AVAudioEngine is still used for mic mixing → output routing.

    private var oneShotPlayers: [AVAudioPlayer] = []   // fire and forget, multiple at once
    private var togglePlayers:  [UUID: AVAudioPlayer] = [:]
    private var toggleActive:   Set<UUID> = []

    // Mic pipeline
    private let engine      = AVAudioEngine()
    private let micMixer    = AVAudioMixerNode()
    private let masterMixer = AVAudioMixerNode()

    @Published var isRunning     = false
    @Published var micVolume:    Float = 0.8  { didSet { micMixer.outputVolume    = micVolume    } }
    @Published var masterVolume: Float = 1.0  { didSet { masterMixer.outputVolume = masterVolume } }

    @Published var selectedMicID:    AudioDeviceID = kAudioObjectUnknown
    @Published var selectedOutputID: AudioDeviceID = kAudioObjectUnknown
    @Published var availableInputDevices:  [(id: AudioDeviceID, name: String)] = []
    @Published var availableOutputDevices: [(id: AudioDeviceID, name: String)] = []

    init() {
        fetchDevices()
        setupMicPipeline()
    }

    // MARK: - Mic pipeline (separate from sound playback)

    private func setupMicPipeline() {
        engine.attach(micMixer)
        engine.attach(masterMixer)
        engine.connect(micMixer,    to: masterMixer,       format: nil)
        engine.connect(masterMixer, to: engine.outputNode, format: nil)
        micMixer.outputVolume    = micVolume
        masterMixer.outputVolume = masterVolume

        NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine, queue: .main
        ) { [weak self] _ in
            self?.isRunning = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self?.startMicPipeline() }
        }
    }

    func start() {
        startMicPipeline()
        isRunning = true
    }

    private func startMicPipeline() {
        guard !engine.isRunning else { return }
        do {
            let input  = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            engine.connect(input, to: micMixer, format: format)
            try engine.start()
        } catch {
            // No mic available — run without it
            engine.disconnectNodeOutput(engine.inputNode)
            try? engine.start()
        }
    }

    func stop() {
        engine.stop()
        isRunning = false
    }

    // MARK: - Play sounds (AVAudioPlayer — dead simple, reliable)

    func play(slot: SoundSlot) {
        guard let url = slot.audioFileURL else { return }
        switch slot.playbackMode {
        case .oneShot: playOneShot(url: url, volume: Float(slot.volume))
        case .toggle:  playToggle(slot: slot, url: url)
        case .hold:    playOneShot(url: url, volume: Float(slot.volume))
        }
    }

    func stopSlot(slotID: UUID) {
        togglePlayers[slotID]?.stop()
        toggleActive.remove(slotID)
    }

    func isTogglePlaying(_ id: UUID) -> Bool {
        toggleActive.contains(id)
    }

    /// One-shot: each call creates a new player — sounds layer freely
    private func playOneShot(url: URL, volume: Float) {
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.volume = volume
        player.prepareToPlay()
        player.play()
        oneShotPlayers.append(player)
        // Clean up finished players periodically
        oneShotPlayers = oneShotPlayers.filter { $0.isPlaying }
    }

    /// Toggle: start playing, press again → stop
    private func playToggle(slot: SoundSlot, url: URL) {
        if toggleActive.contains(slot.id) {
            togglePlayers[slot.id]?.stop()
            togglePlayers.removeValue(forKey: slot.id)
            toggleActive.remove(slot.id)
        } else {
            guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
            player.volume = Float(slot.volume)
            player.prepareToPlay()
            player.play()
            togglePlayers[slot.id] = player
            toggleActive.insert(slot.id)
            // Auto-remove from active when sound finishes naturally
            let id = slot.id
            DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.1) { [weak self] in
                if self?.togglePlayers[id]?.isPlaying == false {
                    self?.toggleActive.remove(id)
                    self?.togglePlayers.removeValue(forKey: id)
                }
            }
        }
    }

    // MARK: - Volume

    func setMasterVolume(_ v: Float) { masterVolume = v }
    func setMicVolume(_ v: Float)    { micVolume    = v }
    func setSlotVolume(_ v: Float, for id: UUID) {
        togglePlayers[id]?.volume = v
    }

    // MARK: - Devices

    func fetchDevices() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope:    kAudioObjectPropertyScopeGlobal,
            mElement:  kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size)
        let count = Int(size) / MemoryLayout<AudioObjectID>.size
        var ids = [AudioDeviceID](repeating: 0, count: count)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &ids)

        var inputs:  [(id: AudioDeviceID, name: String)] = []
        var outputs: [(id: AudioDeviceID, name: String)] = []
        var seen = Set<AudioDeviceID>()

        for id in ids {
            guard !seen.contains(id), let name = deviceName(id) else { continue }
            seen.insert(id)
            if hasChannels(id, scope: kAudioDevicePropertyScopeInput)  { inputs.append((id, name))  }
            if hasChannels(id, scope: kAudioDevicePropertyScopeOutput) { outputs.append((id, name)) }
        }

        DispatchQueue.main.async {
            self.availableInputDevices  = inputs
            self.availableOutputDevices = outputs
        }
    }

    private func hasChannels(_ id: AudioDeviceID, scope: AudioObjectPropertyScope) -> Bool {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope:    scope,
            mElement:  kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(id, &addr, 0, nil, &size) == noErr, size > 0 else { return false }
        let buf = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(size))
        defer { buf.deallocate() }
        AudioObjectGetPropertyData(id, &addr, 0, nil, &size, buf)
        return buf.pointee.mNumberBuffers > 0
    }

    private func deviceName(_ id: AudioDeviceID) -> String? {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope:    kAudioObjectPropertyScopeGlobal,
            mElement:  kAudioObjectPropertyElementMain
        )
        var name: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)
        return AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &name) == noErr ? (name as String) : nil
    }
}
