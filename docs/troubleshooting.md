# Troubleshooting

English · [繁體中文](zh-TW/troubleshooting.md)

## Berth has Accessibility access but does nothing

1. Confirm "Displays have separate Spaces" is enabled in Desktop & Dock settings.
2. Confirm `Berth.app` is in Applications.
3. From the Berth menu, unpin the Dock and select the display again.
4. Quit and reopen Berth.
5. Disable and re-enable Berth under Privacy & Security, then Accessibility.

## Permission stopped working after an update

Berth currently uses an ad-hoc signature, which can change when the App is rebuilt or updated. Disable and re-enable Berth under Privacy & Security, then Accessibility.

## The selected display was disconnected

Berth stops intercepting events when it cannot find the selected display. Reconnect it or choose another display from the menu.

## Still stuck

Open a [GitHub issue](https://github.com/shihyuho/berth/issues) and include your macOS version, display arrangement, Dock position, and what you already tried.
