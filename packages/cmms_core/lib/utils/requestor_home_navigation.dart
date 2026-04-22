import 'package:flutter/material.dart';

import '../screens/requestor/requestor_main_screen.dart';

/// Pops all routes in the current navigator and shows [RequestorMainScreen].
void navigateToRequestorMain(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (context) => const RequestorMainScreen(),
    ),
    (route) => false,
  );
}
