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
    private let engine = AVAudioEngine()
    private let masterMixer = AVAudioMixerNode()
    private let soundMixer  = AVAudioMixerNode()
    private let micMixer    = AVAudioMixerNode()

    // One persistent node per slot for toggle/hold; one-shot gets fresh nodes
    private var toggleNodes: [UUID: AVAudioPlayerNode] = [:]
    // Track toggle state separately
    private var toggleActive: Set<UUID> = []

    @Published var isRunning = false
    @Published var micVolume: Float = 0.8  { didSet { micMixer.outputVolume    = micVolume    } }
    @Published var masterVolume: Float = 1.0 { didSet { masterMixer.outputVolume = masterVolume } }
    @Published var selectedMicID:    AudioDeviceID = kAudioObjectUnknown
    @Published var selectedOutputID: AudioDeviceID = kAudioObjectUnknown
    @Published var availableInputDevices:  [(id: AudioDeviceID, name: String)] = []
    @Published var availableOutputDevices: [(id: AudioDeviceID, name: String)] = []

    init() {
        fetchDevices()
        setupGraph()
        registerInterruptionHandler()
    }

    // MARK: - Graph

    private func setupGraph() {
        engine.attach(masterMixer)
        engine.attach(soundMixer)
        engine.attach(micMixer)
        engine.connect(soundMixer,  to: masterMixer,       format: nil)
        engine.connect(micMixer,    to: masterMixer,       format: nil)
        engine.connect(masterMixer, to: engine.outputNode, format: nil)
        masterMixer.outputVolume = masterVolume
        micMixer.outputVolume    = micVolume
    }

    func start() {
        guard !engine.isRunning else { return }
        // Try with mic first
        do {
            let input  = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            engine.connect(input, to: micMixer, format: format)
            try engine.start()
            isRunning = true
        } catch {
            print("AudioEngine: mic start failed (\(error)), retrying without mic")
            engine.disconnectNodeOutput(engine.inputNode)
            do {
                try engine.start()
                isRunning = true
            } catch {
                print("AudioEngine: failed completely: \(error)")
            }
        }
    }

    func stop() {
        engine.stop()
        isRunning = false
    }

    private func ensureRunning() {
        guard !engine.isRunning else { return }
        try? engine.start()
        isRunning = engine.isRunning
    }

    // MARK: - Interruption handling (keeps engine alive)

    private func registerInterruptionHandler() {
#if os(iOS) || os(tvOS)
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.start()
            }
        }
#endif
        // Also handle config changes (e.g. device plugged in/out)
        NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.isRunning = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.setupGraph()
                self.start()
            }
        }
    }

    // MARK: - Play

    func play(slot: SoundSlot) {
        guard let url = slot.audioFileURL else { return }
        ensureRunning()
        switch slot.playbackMode {
        case .oneShot: playFresh(slot: slot, url: url)
        case .toggle:  playToggle(slot: slot, url: url)
        case .hold:    playFresh(slot: slot, url: url)
        }
    }

    func stopSlot(slotID: UUID) {
        toggleNodes[slotID]?.stop()
        toggleActive.remove(slotID)
    }

    func isTogglePlaying(_ id: UUID) -> Bool {
        toggleActive.contains(id)
    }

    /// One-shot: always spawns a fresh player node so sounds layer
    private func playFresh(slot: SoundSlot, url: URL) {
        guard let file = try? AVAudioFile(forReading: url) else { return }
        let node = AVAudioPlayerNode()
        engine.attach(node)
        engine.connect(node, to: soundMixer, format: nil)
        node.volume = Float(slot.volume)
        node.play()
        node.scheduleFile(file, at: nil) { [weak self] in
            // Clean up after playback finishes
            DispatchQueue.main.async {
                self?.engine.detach(node)
            }
        }
    }

    /// Toggle: persistent node per slot, start/stop
    private func playToggle(slot: SoundSlot, url: URL) {
        if toggleActive.contains(slot.id) {
            // Stop
            toggleNodes[slot.id]?.stop()
            toggleActive.remove(slot.id)
        } else {
            // Start
            let node = getOrCreateToggleNode(for: slot.id)
            guard let file = try? AVAudioFile(forReading: url) else { return }
            node.volume = Float(slot.volume)
            node.scheduleFile(file, at: nil) { [weak self] in
                DispatchQueue.main.async {
                    self?.toggleActive.remove(slot.id)
                }
            }
            node.play()
            toggleActive.insert(slot.id)
        }
    }

    private func getOrCreateToggleNode(for id: UUID) -> AVAudioPlayerNode {
        if let existing = toggleNodes[id] { return existing }
        let node = AVAudioPlayerNode()
        engine.attach(node)
        engine.connect(node, to: soundMixer, format: nil)
        toggleNodes[id] = node
        node.play()
        return node
    }

    // MARK: - Volume

    func setMasterVolume(_ value: Float) { masterVolume = value }
    func setMicVolume(_ value: Float)    { micVolume    = value }
    func setSlotVolume(_ value: Float, for id: UUID) {
        toggleNodes[id]?.volume = value
    }

    // MARK: - Devices

    func fetchDevices() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size)
        let count = Int(size) / MemoryLayout<AudioObjectID>.size
        var ids = [AudioDeviceID](repeating: 0, count: count)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &ids)

        var inputs:  [(id: AudioDeviceID, name: String)] = []
        var outputs: [(id: AudioDeviceID, name: String)] = []
        var seenIDs = Set<AudioDeviceID>()

        for id in ids {
            guard !seenIDs.contains(id), let name = deviceName(id) else { continue }
            seenIDs.insert(id)

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
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        let err = AudioObjectGetPropertyDataSize(id, &addr, 0, nil, &size)
        if err != noErr || size == 0 { return false }
        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(size))
        defer { bufferList.deallocate() }
        AudioObjectGetPropertyData(id, &addr, 0, nil, &size, bufferList)
        return bufferList.pointee.mNumberBuffers > 0
    }

    private func deviceName(_ id: AudioDeviceID) -> String? {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var name: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)
        let err = AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &name)
        return err == noErr ? (name as String) : nil
    }
}

