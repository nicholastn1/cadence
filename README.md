<p align="center">
  <img src="assets/icon.png" width="160" alt="Cadence icon">
</p>

<h1 align="center">Cadence</h1>

<p align="center">
  A teleprompter in your MacBook's notch that scrolls at the pace you speak.
</p>

<p align="center">
  <img alt="Status: work in progress" src="https://img.shields.io/badge/status-work%20in%20progress-orange">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-black">
  <a href="https://github.com/nicholastn1/cadence/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/nicholastn1/cadence/actions/workflows/ci.yml/badge.svg"></a>
  <a href="LICENSE"><img alt="MIT license" src="https://img.shields.io/badge/license-MIT-blue"></a>
</p>

---

Cadence puts your script just under the camera, so on a call or a recording you look at the lens while you read. The text sits in a black panel that grows out of the notch, and it can follow your voice: it scrolls while you talk and waits when you stop.

> **Work in progress.** Cadence is young and changing quickly. It works on a daily-driver Mac, but expect rough edges. Bug reports and ideas are very welcome.

## Features

- **Lives in the notch.** The panel springs out of the hardware notch and tucks back in, shaped like the notch itself.
- **Follows your voice.** Speech recognition runs on your Mac. Cadence finds where you are in the script and scrolls to keep that line under the camera. If you pause, it waits; if you go back, it follows.
- **Hidden from screen sharing.** People on Zoom, Meet, or Teams don't see it, and it doesn't show up in screenshots.
- **Simple controls.** Paste a script, set speed and text size, then play or pause. Click the panel to pause, or scroll on it to move by hand.
- **Works with more than English.** Voice mode detects the script's language, so a Portuguese script works on a Mac set to English.

## Install

### Homebrew (recommended)

```sh
brew install --cask nicholastn1/tap/cadence
```

### Manual

Download `Cadence-x.y.z.zip` from [Releases](https://github.com/nicholastn1/cadence/releases), unzip it, and move `Cadence.app` to Applications.

Cadence isn't notarized yet, so the first time you open it macOS may block it. To allow it, go to **System Settings → Privacy & Security → Open Anyway**, or run:

```sh
xattr -dr com.apple.quarantine /Applications/Cadence.app
```

Homebrew does this step for you.

### Build from source

```sh
git clone https://github.com/nicholastn1/cadence && cd cadence
./build.sh && open Cadence.app
```

You need macOS 14 or later and the Command Line Tools. Xcode isn't needed.

## Usage

| Action | How |
|---|---|
| Play / pause | ⌘↩ in the window, or click the notch panel |
| Restart from the top | ⌘R |
| Follow my voice | Turn on **🎙 Follow my voice** |
| Scroll by hand | Use the trackpad over the notch panel |
| Hide the panel | Turn off **Open on notch** |

The first time you use voice mode, macOS asks for Microphone and Speech Recognition access.

## Requirements

- An Apple Silicon Mac with macOS 14 (Sonoma) or later.
- A notch is recommended. Without one, Cadence still shows as a panel at the top center of the screen.

## Privacy

Speech recognition runs on your Mac whenever macOS supports it for the script's language. Cadence has no servers, accounts, or analytics. Your script is stored only in the app's preferences on your Mac.

## Roadmap

Things planned, roughly in order. Want one sooner? Open an issue or upvote one.

- [ ] Global hotkeys, so you can pause and restart while another app has focus
- [ ] Open on hover and close when idle
- [ ] Signed and notarized builds
- [ ] Settings for panel width, height, and position
- [ ] Fuzzier voice matching for numbers, ad-libs, and skipped lines
- [ ] A countdown before starting, and a mirrored mode for teleprompter glass
- [ ] A library of saved scripts
- [ ] Rich text: bold, colors, and cue marks
- [ ] Support for external displays without a notch

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The whole app is one Swift file, so it's easy to find your way around.

## License

[MIT](LICENSE) © Nicholas Nogueira
