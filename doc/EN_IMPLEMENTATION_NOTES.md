# Keyboard Done Button iOS Plugin - Implementation Notes

## Overview

A Flutter iOS plugin that displays a "Done" button toolbar above the iPhone keyboard.
Allows dismissing keyboards that lack a Done button, such as the numeric keypad.

---

## Architecture

### Tech Stack
- **iOS**: Swift, UIKit
- **Flutter**: Dart, Platform Channels (MethodChannel)

### Core Structure

```
Flutter (Dart)                    iOS (Swift)
─────────────────────────────────────────────────────
KeyboardToolbar            →     KeyboardDoneButtonIosPlugin
  └─ show()               →       └─ pendingToolbarRequest = true
                                   └─ keyboardWillShow (Observer)
                                   └─ showToolbar() / hideToolbar()
```

### Why UIWindow?

Flutter cannot directly access the native `inputAccessoryView`.
Therefore, we create a separate `UIWindow` to display as an overlay above the keyboard.

```swift
// Set windowLevel higher than keyboard
window.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.alert.rawValue - 1)
```

---

## Implemented Features

### 1. One-shot Pattern
- `showDoneButton()` only sets a flag
- On next `keyboardWillShow`, check flag and show toolbar
- Auto-reset after use → toolbar only shows for explicitly called TextField

```dart
// Usage example
TextField(
  keyboardType: TextInputType.number,
  onTap: () => KeyboardToolbar.show(),
)
```

### 2. iPad Auto-Skip
- iPad has built-in Done button even for numeric keypad
- Check `UIDevice.current.userInterfaceIdiom == .pad` to skip completely
- Observer registration itself is skipped to prevent unnecessary code execution

### 3. Multi-language Localization
- Uses system button (`.done`) for automatic iOS localization
- Auto-switches based on system language (English: "Done", Korean: "완료", Japanese: "完了", etc.)
- Requires `CFBundleAllowMixedLocalizations = YES` in `Info.plist`

### 4. Fade In/Out Animation
- Native inputAccessoryView slide animation cannot be implemented
- Fade approach minimizes visual discrepancy
- Synchronized with keyboard animation duration

### 5. Toolbar Persistence on Rotation
- Toolbar persists when device rotates even though keyboard hides/shows
- Rotation detection via Screen Bounds comparison (no additional Observer needed)
- State tracking with `isToolbarActive` + `lastScreenBounds` flags

```swift
// Rotation detection logic
let currentScreenBounds = UIScreen.main.bounds
let didRotate = isToolbarActive &&
                lastScreenBounds != .zero &&
                lastScreenBounds != currentScreenBounds

let shouldShowToolbar = pendingToolbarRequest || didRotate
```

**How it works**:
- Portrait mode: bounds = (393, 852)
- Landscape mode: bounds = (852, 393)
- Rotation changes width/height, so bounds change is detectable

---

## Solved Problems

### 1. Race Condition - Observer Registration Timing

**Problem**: If Observer is registered after `showDoneButton()` call, `keyboardWillShow` is missed

**Solution**: Pre-register Observer at app start (in `register()` method)

```swift
public static func register(with registrar: FlutterPluginRegistrar) {
  let instance = KeyboardDoneButtonIosPlugin()
  instance.registerKeyboardObservers()  // Register at app start
  // ...
}
```

### 2. Toolbar Disappears on Fast TextField Switch

**Problem**: Tap Done button → quickly tap another TextField → toolbar not visible

**Cause**: `hideToolbar()` completion block executes after `showToolbar()`, setting `isHidden = true`

**Solution**:
1. Call `layer.removeAllAnimations()` in `showToolbar()` to cancel ongoing hide animation
2. Check `finished` in `hideToolbar()` completion

```swift
// showToolbar()
toolbarWindow?.layer.removeAllAnimations()

// hideToolbar()
UIView.animate(...) { finished in
  guard finished else { return }  // Skip if cancelled
  toolbarWindow.isHidden = true
}
```

### 3. Toolbar Flicker (Re-display When Already Visible)

**Problem**: Flicker when switching to another TextField while toolbar is already visible

**Cause**: Reset to `alpha = 0` and fade-in every time

**Solution**: If already visible, only update position

```swift
let isAlreadyVisible = !toolbarWindow.isHidden && toolbarWindow.alpha == 1

if isAlreadyVisible {
  toolbarWindow.frame = CGRect(...)  // Only change position
  return
}
```

### 4. rootViewController Issue (iOS 13+)

**Initial Concern**: Adding subview to UIWindow without rootViewController might cause issues on iOS 13+

**Verification Result**: Testing confirmed normal operation without rootViewController

**Conclusion**: Removed unnecessary code, use `window.addSubview(toolbar)` directly

### 5. Toolbar Disappears on Rotation

**Problem**: Show toolbar in portrait → rotate to landscape → toolbar disappears

**Root Cause Analysis**:
```
1. Toolbar is showing (pendingToolbarRequest = false, already reset)
2. Rotation → keyboardWillHide fires
3. keyboardWillShow fires → pendingToolbarRequest = false → toolbar hidden
```

**Solution**: Rotation detection via Screen Bounds comparison
```swift
private var isToolbarActive = false
private var lastScreenBounds: CGRect = .zero

// In keyboardWillShow
let didRotate = isToolbarActive &&
                lastScreenBounds != .zero &&
                lastScreenBounds != currentScreenBounds

let shouldShowToolbar = pendingToolbarRequest || didRotate
```

**Why Screen Bounds?**
| Method | Additional Setup | Performance Impact |
|--------|-----------------|-------------------|
| `beginGeneratingDeviceOrientationNotifications` | Required | Uses accelerometer |
| `statusBarOrientationNotification` | Not required | iOS 13 deprecated |
| **Screen Bounds comparison** | Not required | None ✅ |

---

## Code Structure

```
ios/Classes/
└── KeyboardDoneButtonIosPlugin.swift
    ├── Properties
    │   ├── toolbarWindow: UIWindow?
    │   ├── toolbar: UIToolbar?
    │   ├── pendingToolbarRequest: Bool (one-shot flag)
    │   ├── isObserversRegistered: Bool
    │   ├── isToolbarActive: Bool (for rotation detection)
    │   └── lastScreenBounds: CGRect (for rotation detection)
    │
    ├── Plugin Registration
    │   └── register() - Observer registration, MethodChannel setup
    │
    ├── Setup
    │   ├── registerKeyboardObservers() - includes iPad check
    │   └── showDoneButton() - includes iPad check
    │
    ├── Keyboard Handlers
    │   ├── keyboardWillShow() - rotation detection + toolbar display logic
    │   └── keyboardWillHide() - hide toolbar (preserve isToolbarActive)
    │
    ├── Toolbar Management
    │   ├── createToolbar() - UIToolbar + Done button creation
    │   ├── showToolbar() - display with animation
    │   └── hideToolbar() - hide with animation
    │
    └── Button Actions
        └── doneButtonTapped() - dismiss keyboard + reset isToolbarActive
```

---

## Flutter API

```dart
// Current API
class KeyboardToolbar {
  static Future<void> show() async {
    if (Platform.isIOS) {
      await _channel.invokeMethod('showDoneButton');
    }
  }
}

// Usage
TextField(
  keyboardType: TextInputType.number,
  onTap: () => KeyboardToolbar.show(),
)
```

---

## Future Extensible Features

### +/- Button Addition (Reviewed, Not Implemented)

```dart
// Expected API
KeyboardToolbar.show(showPlusMinus: true);

// iOS → Flutter callback
KeyboardToolbar.setOnPlusMinusTapped(() {
  // Sign change logic
});
```

**Implementation Approach**:
- Custom UIButton (blue background, white text, rounded corners)
- `channel.invokeMethod("onPlusMinusTapped")` to send event to Flutter

---

## Notes

### Design Reference
- Referenced Zoho Inventory app's keyboard toolbar

### Animation Limitations
- Slide animation with keyboard like native `inputAccessoryView` cannot be implemented due to technical limitations
- Limitation of UIWindow overlay approach

### iPad Behavior
- iPad has built-in Done button even for numeric keypad
- Plugin is completely disabled on iPad (Observer registration skipped)

---

*Last updated: 2025-12*
