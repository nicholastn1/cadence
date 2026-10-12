# Contributing

Cadence is early and moving fast. Issues, ideas, and pull requests are welcome.

## Setup

You need a Mac on macOS 14 or later and the Xcode Command Line Tools (`xcode-select --install`). Xcode itself isn't needed.

```sh
git clone https://github.com/nicholastn1/cadence
cd cadence
./build.sh && open Cadence.app
```

## How the code is laid out

On purpose, the whole app is a single file, `main.swift`, built with `swiftc`. Its sections, top to bottom:

1. **Voice matching**: `tokenize` and `locate`. These are pure functions, covered by `--selftest`.
2. **Prompter panel**: the borderless window over the notch, its notch-shaped mask, and the spring animation.
3. **Shared state**: `Prompter`, an `ObservableObject` saved to `UserDefaults`.
4. **Listener**: microphone input and on-device speech recognition.
5. **Control window**: a SwiftUI view inside an AppKit window.
6. **Ticker**: a display link that scrolls the text every frame.

If a change makes the file hard to follow, splitting it into several files and a Swift package is fine. Do that in its own PR.

## Before opening a PR

- `./build.sh` succeeds.
- `./Cadence.app/Contents/MacOS/Cadence --selftest` passes. If you touch the voice matching, add a case there.
- You tried it on a Mac with a notch. Say in the PR which model, because notch sizes differ.
- Add a line to `CHANGELOG.md` under an `Unreleased` heading.

## Releasing (maintainers)

```sh
./release.sh 0.2.0
```

The script builds the app, tags the version, uploads the zip to GitHub Releases, and updates the cask in [nicholastn1/homebrew-tap](https://github.com/nicholastn1/homebrew-tap).
