# Changelog

All notable changes to Cadence. Versions follow [Semantic Versioning](https://semver.org); while we're on 0.x, anything can change.

## [0.3.1] - 2026-10-12

- Fixed: Quit in the menu bar left Cadence running in the background.
- Fixed: Update and Relaunch could reopen the old version, and the old copy stayed in the menu bar. Cadence now refreshes Homebrew first and checks that the new version is installed before relaunching.

## [0.3.0] - 2026-10-12

- Check for updates: Cadence looks for new versions once a day, and you can check from the Cadence menu or the menu bar.
- When an update is out, you'll see a notice in the sidebar and the menu bar. Homebrew installs update and relaunch in one click.
- What's New: release notes for every version, inside the app. It opens once after each update.
- Release notes on GitHub now match this changelog.

## [0.2.0] - 2026-10-12

- New window design: a script library in the sidebar, a serif editor, and a playback bar shaped like the notch island. Hovering a control shows what it does.
- Formatting: `**stress**`, `==highlight==`, and `[notes]` that show in red and are never read aloud.
- Voice mode understands numbers, ignores ad-libs, tolerates skipped words, and explains what to do if access is denied.
- Open on hover: the panel stays in the notch until you point at it or start reading.
- 3-2-1 countdown before playback, mirror mode for teleprompter glass.
- Settings window: display, panel width, visible lines, text size, countdown, mirror, hover, menu bar.
- Menu bar icon with quick controls. You can hide it.
- Works on external displays without a notch.
- New app icon.
- The line you're reading stays sharp while the lines below fade.

## [0.1.0] - 2026-10-12

First public release.

- Teleprompter panel that grows out of the MacBook notch with a spring animation and collapses back into it.
- Control window: paste a script, adjust speed and text size, play, pause, restart.
- Voice mode: on-device speech recognition follows your reading pace. Works in the script's language.
- Hidden from screen sharing and screenshots.
- Script and settings are saved between launches.
