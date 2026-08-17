# Development

English · [繁體中文](zh-TW/development.md)

## Requirements

- Apple Silicon Mac
- macOS 13 or later
- Swift 5.9
- Xcode Command Line Tools

## Build

```sh
git clone https://github.com/shihyuho/berth.git
cd berth
./Scripts/build.sh
```

The build produces `dist/Berth.app` with an ad-hoc signature. Move it to Applications before enabling Launch at Login. A rebuilt App may need Accessibility permission again.

## Version files

`version.txt` is the release version source. Release Please updates it together with `CFBundleShortVersionString` and `CFBundleVersion` in `Support/Info.plist`.

## Release packaging

`Scripts/package_release.sh <version>` builds the arm64 App, verifies its signature and architecture, and creates the GitHub Release ZIP. `Scripts/render_cask.sh` produces the matching Homebrew Cask from the release version and SHA-256 checksum.
