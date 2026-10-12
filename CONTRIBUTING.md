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

The app is a handful of Swift files in `Sources/`, compiled with `swiftc` by `build.sh`. There's no Xcode project and no package manager.

| File | What's in it |
|---|---|
| `CadenceApp.swift` | App entry, the menu bar menu, and quit behavior |
| `Model.swift` | `Prompter`: scripts, settings, and playback state, saved to `UserDefaults` |
| `Notch.swift` | The panel over the notch: geometry, the spring animation, hover, countdown, scrolling |
| `Listener.swift` | Microphone and on-device speech recognition |
| `Matching.swift` | Pure voice-matching functions, covered by `--selftest` |
| `Markup.swift` | `**stress**`, `==highlight==`, `[notes]`: rendering for the notch and styling in the editor |
| `Views.swift` | SwiftUI: the window, editor, playback bar, settings, and menu commands |

The notch panel is hidden from screenshots on purpose. To capture it for a PR, launch with `CADENCE_CAPTURABLE=1 ./Cadence.app/Contents/MacOS/Cadence`.

`@State` and `@Observable` are macros that plain `swiftc` can't load, so keep view state in an `ObservableObject`.

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
