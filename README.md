# keyboard_done_button_ios

A Flutter plugin that adds a **Done** button toolbar above iOS keyboards.

iOS number keyboards don't have a dismiss key. This plugin solves that.

## Demo

![Demo](https://raw.githubusercontent.com/bgpworks/ios-native-done-button/main/doc/prototype.gif)

## Installation

```yaml
dependencies:
  keyboard_done_button_ios: ^0.0.2
```

## Usage

Wrap your TextField with `KeyboardToolbarField`:

```dart
import 'package:keyboard_done_button_ios/keyboard_done_button_ios.dart';

// Shows Done button
KeyboardToolbarField(
  child: TextField(
    keyboardType: TextInputType.number,
  ),
)

// Hides Done button (for text fields)
KeyboardToolbarField(
  showToolbar: false,
  child: TextField(
    keyboardType: TextInputType.text,
  ),
)
```

### Manual Control

```dart
// Show toolbar
TextField(
  keyboardType: TextInputType.number,
  onTap: () => KeyboardToolbar.show(),
)

// Hide toolbar
TextField(
  onTap: () => KeyboardToolbar.hide(),
)
```

## Platform Support

| Platform | Support |
|----------|---------|
| iOS (iPhone) | ✅ Full support |
| iOS (iPad) | ⏭️ Skipped (has built-in Done) |
| Android | ➖ No-op (safe to call) |

## Localization

The Done button uses system language automatically.

Add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleAllowMixedLocalizations</key>
<true/>
```
