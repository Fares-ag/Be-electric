import 'package:flutter/material.dart';

import '../config/cmms_app_mode.dart';

/// Injects the current requestor vs technician [CmmsAppMode] for the running binary.
class CmmsAppModeScope extends InheritedWidget {
  const CmmsAppModeScope({
    super.key,
    required this.appMode,
    required super.child,
  });

  final CmmsAppMode appMode;

  static CmmsAppMode? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CmmsAppModeScope>()
        ?.appMode;
  }

  static CmmsAppMode of(BuildContext context) {
    final m = maybeOf(context);
    assert(
      m != null,
      'CmmsAppModeScope not found — wrap the app with CmmsAppModeScope in BeElectricApp',
    );
    return m!;
  }

  @override
  bool updateShouldNotify(covariant CmmsAppModeScope oldWidget) =>
      oldWidget.appMode != appMode;
}
