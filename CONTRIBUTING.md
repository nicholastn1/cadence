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
| `Updates.swift` | Update checks against GitHub Releases, Homebrew updates, and the What's New window |
| `Views.swift` | SwiftUI: the window, editor, playback bar, settings, and menu commands |

The notch panel is hidden from screenshots on purpose. To capture it for a PR, launch with `CADENCE_CAPTURABLE=1 ./Cadence.app/Contents/MacOS/Cadence`.

### Translations

Interface text lives in `Resources/<language>.lproj/Localizable.strings`. The keys are the English text. To add a language, copy `pt-BR.lproj`, translate the values, and add the language code to `CFBundleLocalizations` in `build.sh`. When you add interface text in Swift, add its key to every `Localizable.strings` file. Text in `Text`, `Button`, `Toggle` and similar views is looked up automatically. Text built in code needs `String(localized:)`.

`@State` and `@Observable` are macros that plain `swiftc` can't load, so keep view state in an `ObservableObject`.

## Before opening a PR

- `./build.sh` succeeds.
- `./Cadence.app/Contents/MacOS/Cadence --selftest` passes. If you touch the voice matching, add a case there.
- You tried it on a Mac with a notch. Say in the PR which model, because notch sizes differ.
- Add a line to `CHANGELOG.md` under an `Unreleased` heading. Each version's section becomes its GitHub release notes and shows up in the app's What's New window.

## Releasing (maintainers)

```sh
./release.sh 0.2.0
```

The script builds the app, tags the version, uploads the zip to GitHub Releases, and updates the cask in [nicholastn1/homebrew-tap](https://github.com/nicholastn1/homebrew-tap).
