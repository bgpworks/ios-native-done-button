import 'dart:io';
import 'keyboard_done_button_ios_platform_interface.dart';

class KeyboardToolbar {
  Future<String?> getPlatformVersion() {
    return KeyboardDoneButtonIosPlatform.instance.getPlatformVersion();
  }

  /// Setup the Done button on iOS keyboard
  /// Call this when a TextField gains focus
  static Future<void> show() async {
    if (Platform.isIOS) {
      await KeyboardDoneButtonIosPlatform.instance.showDoneButton();
    }
  }
}
