import 'package:flutter/material.dart';

import '../app/be_electric_app.dart';
import '../config/cmms_app_mode.dart';
import 'cmms_bootstrap.dart';

/// Requestor store build: only [requestor] role is intended after sign-in.
Future<void> runRequestorApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeCmms();
  runApp(
    const BeElectricApp(
      appMode: CmmsAppMode.requestor,
    ),
  );
}

/// Technician / field staff build: technician, manager, and admin roles.
Future<void> runTechnicianApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeCmms();
  runApp(
    const BeElectricApp(
      appMode: CmmsAppMode.technician,
    ),
  );
}
