import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import 'app_theme.dart';

/// Opens a legal/support URL in the system browser.
Future<bool> launchLegalUrl(
  BuildContext context,
  String url, {
  String? missingMessage,
}) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            missingMessage ?? 'This link is not configured for this build.',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
    return false;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid link configuration.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
    return false;
  }

  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open link.'),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }
  return launched;
}

/// Opens a mailto link for support or account requests.
Future<bool> launchSupportEmail(
  BuildContext context, {
  required String subject,
  String? body,
}) async {
  final email = AppConfig.supportEmail.trim();
  if (email.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Support email is not configured for this build.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
    return false;
  }

  final uri = Uri(
    scheme: 'mailto',
    path: email,
    queryParameters: {
      if (subject.isNotEmpty) 'subject': subject,
      if (body != null && body.isNotEmpty) 'body': body,
    },
  );

  final launched = await launchUrl(uri);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not open email. Contact us at $email'),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 6),
      ),
    );
  }
  return launched;
}

Future<void> showAccountDeletionRequestDialog(
  BuildContext context, {
  required String userEmail,
  required String userName,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Request account deletion'),
      content: const Text(
        'Accounts for this app are created by your organization. '
        'To delete your account and associated personal data, contact support. '
        'Your employer may also remove your account through their administrator.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.of(ctx).pop();
            await launchSupportEmail(
              context,
              subject: 'Account deletion request — Be Electric Requestor',
              body:
                  'Please delete my Be Electric Requestor account and associated data.\n\n'
                  'Name: $userName\n'
                  'Email: $userEmail\n',
            );
          },
          child: const Text('Email support'),
        ),
      ],
    ),
  );
}
