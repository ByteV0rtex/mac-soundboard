<h1>
  <img src="./assets/icon.png" width="45"> mac-soundboard
</h1>

A personal macOS soundboard — plays sound effects alongside your mic into a virtual audio device. Works with Discord, OBS, or anything that takes mic input. Free, open source and un-bloated alternative to Caster and Voicemod.

Built in Swift / SwiftUI with a clean, dark UI that actually looks good.

![App Preview](./assets/app-preview.png)

-----

## Features

### 🎛️ Soundboard

- Grid of assignable sound buttons — 3, 4, 5, or 6 columns
- Click a button or press its hotkey to trigger a sound
- Empty slots open the editor when clicked so setup is frictionless
- **Stop All** button kills every playing sound instantly

### ✏️ Sound Slot Editor

Each slot is fully customizable:

- **Name** — label shown on the button
- **Emoji or icon** — any emoji or short text as the button face
- **Color** — 12 preset accent colors to color-code your sounds
- **Audio file** — import any `.mp3`, `.wav`, or `.aiff` file
- **Volume** — per-slot volume slider, independent of everything else
- **Playback mode**
  - *One Shot* — every press spawns a new instance, sounds layer freely
  - *Toggle* — first press starts, second press stops
- **Hotkey** — assign any key, captured directly from your keyboard

### 🎚️ Mixer

- Vertical fader channels for master output, mic, and every assigned sound slot
- Drag faders to adjust levels in real time
- Visual volume readout per channel

### 🎙️ Virtual Mic

- Mixes your real mic input with sound effects into a single output
- Route to **BlackHole 2ch** and set that as your mic in Discord, OBS, or any app
- Mic and sound volumes controlled independently

### ⌨️ Global Hotkeys

- Hotkeys fire from any app — Discord, games, browser, anywhere
- Uses `CGEventTap` with Accessibility permission
- Key repeat ignored — one press, one trigger

### ⚙️ Settings

- Microphone input selector
- Output device selector — pick BlackHole or any other output
- BlackHole install status indicator with direct install link
- Accessibility permission status and one-click grant

-----

<p align="center">
  <img src="./assets/edit-sound.png" width="420"/>
</p>

-----

## Requirements

- macOS 13+
- [BlackHole 2ch](https://github.com/ExistentialAudio/BlackHole) — free virtual audio driver
- Accessibility permission (for global hotkeys)

-----

## Setup

1. Install [BlackHole 2ch](https://github.com/ExistentialAudio/BlackHole)
1. Open the project in Xcode and build
1. Grant Accessibility permission when prompted — System Settings → Privacy & Security → Accessibility
1. In Discord, OBS, etc. set the mic input to **BlackHole 2ch**

-----

## How it works

```
Mic input (AVAudioEngine)
        ↓
    Mic mixer node
        ↓
  Master mixer  ←── Sound slots (AVAudioPlayer × N, one per trigger)
        ↓
  BlackHole 2ch  ←── Discord / OBS sees this as a microphone
```

Each sound slot uses its own `AVAudioPlayer` instance so sounds play simultaneously without interfering. Toggle mode keeps a persistent player per slot. One-shot mode spawns a fresh player on every press and cleans up automatically when done.

Global hotkeys are captured via `CGEventTap` at the session level — keys fire regardless of which app is focused.

-----

## Stack

- Swift / SwiftUI
- AVFoundation — `AVAudioPlayer` per slot, `AVAudioEngine` for mic pipeline
- CGEventTap — global hotkey capture
- BlackHole — virtual audio HAL driver (third party, free)

-----

## License

MIT — do whatever you want with it.

-----

> [!NOTE]  
> Personal tool, not a polished product. No App Store release planned.