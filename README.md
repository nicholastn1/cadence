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

- **Lives in the notch.** The panel springs out of the hardware notch and tucks back in, shaped like the notch itself. With **Open on hover**, it stays hidden until you point at it or start reading.
- **Follows your voice.** Speech recognition runs on your Mac. Cadence finds where you are in the script and keeps that line under the camera. It handles numbers ("42" or "forty-two"), words you add or skip, and small mishearings. If you pause, it waits; if you go back, it follows.
- **Hidden from screen sharing.** People on Zoom, Meet, or Teams don't see it, and it doesn't show up in screenshots.
- **Highlights the word you're on.** In voice mode, words you've read dim and the current word is marked, so you never lose your place.
- **Pace stats after each take.** Total time, words per minute, and the sentence where you slowed down.
- **A script library.** Keep as many scripts as you like, and import `.txt`, `.md`, `.docx`, and `.rtf` files with ⌘O or by dropping them on the sidebar. Bold in Word files becomes stress. Everything saves as you type.
- **In English, Portuguese, and Spanish.** The interface follows your Mac's language.
- **Formatting for reading aloud.** Stress words with `**bold**`, highlight with `==amber==`, and leave yourself `[notes]` that show in red and are never read.
- **Countdown and mirror mode.** A 3-2-1 before scrolling starts, and mirrored text for teleprompter glass.
- **In the menu bar.** Play, switch scripts, or turn on your voice without opening the window. You can hide the icon.
- **Tells you about updates.** A daily check, release notes inside the app, and one-click updates for Homebrew installs.
- **Adjustable.** Panel width, visible lines, text size, speed, and which display to use.
- **Holds still when you go off script.** Answer a question or chat for a moment and Cadence waits; it picks up again when you're back on the script.
- **Works in 34 languages.** Voice mode detects each script's language, or you can pick one. A Portuguese script works on a Mac set to English.

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

### Updating

Cadence checks for new versions once a day and tells you in the sidebar and the menu bar. Open **Cadence > Check for Updates…** to check now. If you installed with Homebrew, **Update and Relaunch** does the rest. You can also run:

```sh
brew upgrade --cask cadence
```

**Cadence > What's New** shows the release notes for every version.

### Build from source

```sh
git clone https://github.com/nicholastn1/cadence && cd cadence
./build.sh && open Cadence.app
```

You need macOS 14 or later and the Command Line Tools. Xcode isn't needed.

## Usage

| Action | How |
|---|---|
| Play or pause | ⌘↩, the play button, or click the notch panel |
| Back to the top | ⌘R |
| Follow my voice | ⌘L, or the microphone button |
| Faster or slower | ⌘] and ⌘[, or the speed slider |
| Scroll by hand | Trackpad over the notch panel |
| New script | ⌘N |
| Import a script | ⌘O, or drop a file on the sidebar |
| Stress, highlight, note | ⌘B, ⇧⌘H, ⌘K (or the toolbar) |
| Settings | ⌘, |

Formatting in a script:

```text
We grew **42 percent** this year. [pause]
==Thank the team== before the numbers. [smile]
```

The first time you use voice mode, macOS asks for Microphone and Speech Recognition access.

## How voice mode works

Cadence doesn't listen for *when* you speak, only for *what* you say. Apple's speech recognizer turns your voice into words several times a second. Cadence takes your last few words and looks for them in the script near the line you're on. It moves the panel only when they line up:

- One word is enough for the next couple of words, but only if it's a real word. "The" or "and" alone can't move it.
- Moving further takes two or three words in a row, so a phrase that repeats later in the script doesn't make it jump.
- After about six words that don't match, Cadence assumes you're talking to someone and holds still until three words in a row match again.

Numbers match either way ("42" or "forty-two"), accents are ignored, and words you add or skip are tolerated.

**Languages.** Voice mode works in the 34 languages macOS speech recognition supports. The globe button in the toolbar picks the language per script, and Automatic is the default. Languages marked *online* send audio to Apple. To use one offline, add it in **System Settings > Keyboard > Dictation**. In languages Apple doesn't support, steady scrolling still works.

## Requirements

- An Apple Silicon Mac with macOS 14 (Sonoma) or later.
- A notch is recommended. Without one, Cadence still shows as a panel at the top center of the screen.

## Privacy

Speech recognition runs on your Mac whenever macOS supports it for the script's language; otherwise Apple's servers handle it, and the app tells you when that's the case. Cadence has no servers, accounts, or analytics. Your script is stored only in the app's preferences on your Mac.

## Roadmap

Cadence is a work in progress. Next up, roughly in order. Want one sooner? Open an issue or upvote one.

- [ ] Signed and notarized builds
- [ ] Use your iPhone as a remote
- [ ] Save takes and compare your pace over time
- [ ] Import from Google Docs and Notion
- [ ] More interface languages (translations welcome, see [CONTRIBUTING.md](CONTRIBUTING.md))

Done recently: word highlighting, pace stats, file import, Portuguese and Spanish interface, off-script hold, per-script voice language, update checks.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The app is a handful of small Swift files with no Xcode project, so it's easy to find your way around.

## License

[MIT](LICENSE) © Nicholas Nogueira
