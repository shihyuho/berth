# How Berth works

English · [繁體中文](zh-TW/how-it-works.md)

When macOS uses separate Spaces for each display, pushing the pointer against a Dock edge can summon the Dock to another screen. Berth prevents that gesture from completing on displays you did not select.

Berth listens for global mouse-move and drag events through `CGEventTap`. Near an outer Dock edge on another display, it keeps the pointer at least 2 px away from the trigger zone. Shared edges between displays remain open, so the pointer can move between screens normally.

If the Dock still moves, Berth checks its location and recreates the normal summon gesture on the selected display. It supports a Dock positioned at the bottom, left, or right.

## Display changes

Berth stores the selected display identifier. If that display disappears, Berth stops intercepting events safely. Reconnect it or choose another display from the menu.

## Privacy and permission

Accessibility access is required because Berth reads mouse movement and generates mouse movement used to summon the Dock. Berth does not monitor the keyboard, save input, or send data over the network.

Revoking Accessibility access stops interception automatically.
