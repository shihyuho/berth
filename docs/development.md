# Development

English · [繁體中文](zh-TW/development.md)

## Requirements

- Apple Silicon Mac
- macOS 13 or later
- Swift 5.9
- A complete Xcode installation selected by `xcode-select`

The standalone Xcode Command Line Tools package is not sufficient because the App build uses Xcode's `xcstringstool` to compile the String Catalog.

## Build

```sh
git clone https://github.com/shihyuho/berth.git
cd berth
./Scripts/build.sh
```

The build validates every declared String Catalog locale, compiles all of them into the main App bundle, and produces `dist/Berth.app` with an ad-hoc signature. Move it to Applications before enabling Launch at Login. A rebuilt App may need Accessibility permission again.

## Version files

`version.txt` is the release version source. Release Please updates it together with `CFBundleShortVersionString` and `CFBundleVersion` in `Support/Info.plist`.

## Release packaging

`Scripts/package_release.sh <version>` builds the arm64 App, verifies its signature and architecture, and creates the GitHub Release ZIP. `Scripts/render_cask.sh` produces the matching Homebrew Cask from the release version and SHA-256 checksum.
