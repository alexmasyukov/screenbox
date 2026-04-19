# Screenbox

A thin, always-on-top rectangular frame for macOS. Drag it, resize it, click the camera button — the screen region inside the frame is saved as a PNG to `~/Pictures/ScreenshotFrame/shot-YYYYMMDD-HHmmss.png`. That is all it does.

- Floats above fullscreen apps (window level `.statusWindow`)
- Click-through transparent center — apps underneath remain interactive
- 6 px red border with 14×14 corner handles for per-corner resize
- Shutter button in the top-right corner of the frame
- Menu-bar item with a single **Quit** action
- Position and size persist across launches

## Requirements

- macOS 14.0 or later
- Xcode 15 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project

## Build

```sh
brew install xcodegen   # if not installed
cd screenbox
xcodegen generate
open screenbox.xcodeproj
```

Press Run in Xcode. On first launch macOS will ask for **Screen Recording** permission; grant it and relaunch.

Alternatively, build from the command line:

```sh
xcodegen generate
xcodebuild -project screenbox.xcodeproj -scheme screenbox -configuration Release -derivedDataPath build
```

The resulting app bundle lives at `build/Build/Products/Release/screenbox.app`.

## Screen Recording permission

Screenbox needs **Screen Recording** permission to capture pixels inside the frame. If the permission is missing, the app shows an alert with a button that opens the relevant System Settings pane directly:

> System Settings → Privacy & Security → Screen Recording → enable Screenbox

After granting permission, quit and relaunch Screenbox.

## Release build with ad-hoc signing

For distribution outside the Mac App Store, an ad-hoc signature is sufficient:

```sh
xcodebuild -project screenbox.xcodeproj -scheme screenbox -configuration Release \
  -derivedDataPath build CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
codesign --deep --force --sign - build/Build/Products/Release/screenbox.app
```

## Reset saved position

If the frame ever ends up off-screen or in an odd state:

```sh
defaults delete com.alexmasyukov.screenbox
```

## Project layout

```
screenbox/
├── project.yml                 # XcodeGen manifest
├── screenbox/
│   ├── ScreenboxApp.swift      # @main + AppDelegate + menu-bar item
│   ├── FramePanel.swift        # NSPanel subclass + hit-test hole
│   ├── FrameView.swift         # SwiftUI border, corner handles, shutter button
│   ├── FrameController.swift   # drag/resize math, persistence
│   ├── Screenshotter.swift     # ScreenCaptureKit + CGWindowList fallback
│   ├── Permissions.swift       # Screen Recording permission flow
│   └── Info.plist              # LSUIElement, NSScreenCaptureUsageDescription
```

## License

No license specified — personal tool.
