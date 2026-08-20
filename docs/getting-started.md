# Getting started

English · [繁體中文](zh-TW/getting-started.md)

Berth requires an Apple Silicon Mac running macOS 13 Ventura or later. In System Settings, open Desktop & Dock, then make sure "Displays have separate Spaces" is enabled under Mission Control.

## Download the App

Download [Berth for Apple Silicon](https://github.com/shihyuho/berth/releases/latest/download/Berth-arm64.zip), unzip it, and move `Berth.app` to Applications.

Berth currently uses an ad-hoc signature. The first time you open it, macOS may block the App because it cannot verify the developer. Open System Settings, go to Privacy & Security, find the Berth message, and choose Open Anyway.

## Install with Homebrew

```sh
brew tap shihyuho/tap
brew install --cask shihyuho/tap/berth
```

If you previously copied Berth to Applications by hand, quit and remove that copy before installing with Homebrew.

## Choose a display

1. Open Berth and select the anchor in the menu bar.
2. Choose the display where the Dock should stay.
3. When macOS asks, open Privacy & Security, then Accessibility, and enable Berth.
4. Return to Berth. It will keep the Dock on the selected display.

You can also enable Launch at Login from the Berth menu.

## Update

```sh
brew update
brew upgrade --cask shihyuho/tap/berth
```

Because the App is ad-hoc signed, an update may require you to disable and re-enable Berth under Privacy & Security, then Accessibility.
