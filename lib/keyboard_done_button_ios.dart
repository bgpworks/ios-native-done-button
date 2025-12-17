import 'dart:io';
import 'package:flutter/widgets.dart';
import 'keyboard_done_button_ios_platform_interface.dart';

/// Utility class for controlling the keyboard Done button toolbar
class KeyboardToolbar {
  /// Show the Done button toolbar above the keyboard
  /// Call this when a TextField with number keyboard gains focus
  static Future<void> show() async {
    if (Platform.isIOS) {
      await KeyboardDoneButtonIosPlatform.instance.showDoneButton();
    }
  }

  /// Hide the Done button toolbar
  /// Call this when a TextField without toolbar gains focus
  static Future<void> hide() async {
    if (Platform.isIOS) {
      await KeyboardDoneButtonIosPlatform.instance.hideDoneButton();
    }
  }
}

/// A widget that automatically shows/hides the keyboard Done button toolbar
/// based on focus state.
///
/// Wrap your TextField or TextFormField with this widget to automatically
/// manage the toolbar visibility.
///
/// Example:
/// ```dart
/// KeyboardToolbarField(
///   child: TextField(
///     keyboardType: TextInputType.number,
///   ),
/// )
/// ```
class KeyboardToolbarField extends StatefulWidget {
  /// The child widget (typically a TextField or TextFormField)
  final Widget child;

  /// Whether to show the toolbar when this field is focused.
  /// Defaults to true.
  final bool showToolbar;

  /// Optional FocusNode. If not provided, one will be created internally.
  final FocusNode? focusNode;

  const KeyboardToolbarField({
    super.key,
    required this.child,
    this.showToolbar = true,
    this.focusNode,
  });

  @override
  State<KeyboardToolbarField> createState() => _KeyboardToolbarFieldState();
}

class _KeyboardToolbarFieldState extends State<KeyboardToolbarField> {
  late FocusNode _focusNode;
  bool _ownsNode = false;

  @override
  void initState() {
    super.initState();
    _initFocusNode();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _initFocusNode() {
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
      _ownsNode = false;
    } else {
      _focusNode = FocusNode();
      _ownsNode = true;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(KeyboardToolbarField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      if (_ownsNode) {
        _focusNode.dispose();
      }
      _initFocusNode();
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      if (widget.showToolbar) {
        KeyboardToolbar.show();
      } else {
        KeyboardToolbar.hide();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(focusNode: _focusNode, child: widget.child);
  }
}
