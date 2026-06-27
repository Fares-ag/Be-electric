import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../utils/legal_links.dart';

/// Privacy / terms links for login and profile screens (App Store 5.1.1(i)).
class LegalFooter extends StatelessWidget {
  const LegalFooter({
    this.textColor = Colors.white70,
    this.linkColor = Colors.white,
    super.key,
  });

  final Color textColor;
  final Color linkColor;

  @override
  Widget build(BuildContext context) {
    final privacy = AppConfig.privacyPolicyUrl;
    final terms = AppConfig.termsOfServiceUrl;
    final support = AppConfig.supportEmail;

    return Column(
      children: [
        Text(
          'Accounts are created by your organization administrator.',
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          children: [
            if (privacy.isNotEmpty)
              _LinkButton(
                label: 'Privacy Policy',
                color: linkColor,
                onTap: () => launchLegalUrl(context, privacy),
              ),
            if (terms.isNotEmpty)
              _LinkButton(
                label: 'Terms of Service',
                color: linkColor,
                onTap: () => launchLegalUrl(context, terms),
              ),
            if (support.isNotEmpty)
              _LinkButton(
                label: 'Contact support',
                color: linkColor,
                onTap: () => launchSupportEmail(
                  context,
                  subject: 'Be Electric Requestor support',
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
