# keyboard_done_button_ios

A Flutter plugin that displays a **Done** button toolbar above the iOS keyboard.

## Overview

On iOS, number keyboards (`TextInputType.number`) don't have a built-in key to dismiss the keyboard. This plugin solves that problem by showing a toolbar with a "Done" button above the keyboard.

**Features**
- Displays a native-style toolbar with Done button
- Localized: shows "Done" or "완료" based on system language
- Smooth fade animation synchronized with keyboard
- Rotation support: toolbar persists when device rotates
- Zero configuration required

**Platform Support**

| Platform | Support |
|----------|---------|
| iOS (iPhone) | ✅ |
| iOS (iPad) | ⏭️ Skipped (has built-in Done button) |
| Android | ➖ No-op (safe to call) |

## Usage

### Installation

```yaml
dependencies:
  keyboard_done_button_ios: ^0.0.1
```

### Basic Usage

Call `KeyboardToolbar.show()` in the `onTap` callback of your TextField:

```dart
import 'package:keyboard_done_button_ios/keyboard_done_button_ios.dart';

TextField(
  keyboardType: TextInputType.number,
  onTap: () => KeyboardToolbar.show(),
)
```

### With TextFormField

```dart
TextFormField(
  keyboardType: TextInputType.number,
  onTap: () => KeyboardToolbar.show(),
  decoration: InputDecoration(labelText: 'Amount'),
)
```

## Localization

The Done button automatically displays in the system language (e.g., "Done", "완료", "完了").

To enable this, add the following to your `ios/Runner/Info.plist`:

```xml
<key>CFBundleAllowMixedLocalizations</key>
<true/>
```

## Notes

- **One-shot behavior**: The toolbar only appears for the immediately following keyboard. Call `show()` each time the TextField is tapped.
- **Rotation**: Toolbar automatically persists when device rotates while keyboard is visible.
- **iPad**: Automatically skipped. iPad number keyboards have a built-in Done button.
- **Android**: Safe to call on Android - the method does nothing (no-op).
- **Timing**: Call `show()` in `onTap`, not in `onFocusChange`. The method must be called before the keyboard appears.
