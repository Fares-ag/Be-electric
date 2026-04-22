import 'package:cmms_core/config/cmms_app_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cmms_core is reachable from technician app', () {
    expect(CmmsAppMode.technician, CmmsAppMode.technician);
  });
}
