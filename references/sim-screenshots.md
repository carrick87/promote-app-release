# Simulator screenshots (HAR StockApp)

Helper notes for `promote-app-release`. Prefer a booted iPhone (e.g. iPhone 17).

## Build / install / launch

```bash
# Resolve booted UDID
xcrun simctl list devices | rg Booted

SCHEME=StockMaster   # or project scheme name
BUNDLE=com.HAR.StockApp
SIM=<UDID>
DD=/tmp/StockMasterDD

xcodebuild \
  -scheme "$SCHEME" \
  -destination "id=$SIM" \
  -derivedDataPath "$DD" \
  -configuration Debug \
  build

APP=$(find "$DD" -name 'StockMaster.app' -type d | head -1)
xcrun simctl install "$SIM" "$APP"
xcrun simctl launch "$SIM" "$BUNDLE"
```

## Screenshot

```bash
OUT=marketing/screenshots/<VERSION>
mkdir -p "$OUT"
xcrun simctl io "$SIM" screenshot "$OUT/01-search.png"
```

## Login (if needed)

OTP bypass (debug): email `admin@testing.local`, username `csd.exec`.

If already signed in, splash may go straight to Search.

## Tab navigation without idb

AppleScript click on the Simulator window (normalize coords 0–1 within content below ~52pt chrome). Five tabs: Search=0.10, Sales=0.30, Stock Age=0.50, Movement=0.70, More=0.90 — y ≈ 0.94.

Avoid AppleScript variable name `toolbar` (reserved). Use `chromeH` instead.

Example:

```applescript
tell application "Simulator" to activate
tell application "System Events"
  tell process "Simulator"
    set frontmost to true
    set win to window 1
    set {wx, wy} to position of win
    set {ww, wh} to size of win
    set chromeH to 52
    set contentH to wh - chromeH
    set contentY to wy + chromeH
    set cx to wx + (ww * 0.30)
    set cy to contentY + (contentH * 0.94)
    click at {cx, cy}
  end tell
end tell
```

From More, tap Reports (~0.50 x, ~0.30 y). From Stock Age, tap Filters “Show” (~0.85 x, ~0.22 y) to expand if needed.

## Fallback

If clicks miss, document the screen and proceed with GenerateImage using whatever screenshots + the app icon were captured.
