import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'keyboard_done_button_ios_method_channel.dart';

abstract class KeyboardDoneButtonIosPlatform extends PlatformInterface {
  /// Constructs a KeyboardDoneButtonIosPlatform.
  KeyboardDoneButtonIosPlatform() : super(token: _token);

  static final Object _token = Object();

  static KeyboardDoneButtonIosPlatform _instance =
      MethodChannelKeyboardDoneButtonIos();

  /// The default instance of [KeyboardDoneButtonIosPlatform] to use.
  ///
  /// Defaults to [MethodChannelKeyboardDoneButtonIos].
  static KeyboardDoneButtonIosPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [KeyboardDoneButtonIosPlatform] when
  /// they register themselves.
  static set instance(KeyboardDoneButtonIosPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> showDoneButton() {
    throw UnimplementedError('showDoneButton() has not been implemented.');
  }

  Future<void> hideDoneButton() {
    throw UnimplementedError('hideDoneButton() has not been implemented.');
  }
}
