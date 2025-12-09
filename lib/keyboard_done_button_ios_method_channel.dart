import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'keyboard_done_button_ios_platform_interface.dart';

/// An implementation of [KeyboardDoneButtonIosPlatform] that uses method channels.
class MethodChannelKeyboardDoneButtonIos extends KeyboardDoneButtonIosPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('keyboard_done_button_ios');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<void> showDoneButton() async {
    await methodChannel.invokeMethod<void>('showDoneButton');
  }
}
