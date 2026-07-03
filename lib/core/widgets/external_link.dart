// lib/core/widgets/external_link.dart
//
// MISSING FROM THE PREVIOUS UPDATE — Flutter translation of spec F4 + R4.
//
// The React failure mode ("www.ox.ac.uk" rendered as a relative link →
// edupathmve.netlify.app/www.ox.ac.uk → 404) has an exact Flutter twin:
// Uri.parse('www.ox.ac.uk') has no scheme, and depending on how it's launched
// it either throws, silently fails, or resolves relative to the app origin.
// Every external URL must pass through toExternalHref before launch.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// F4 — a data mistake can never produce a schemeless/relative external link.
String toExternalHref(String url) {
  final trimmed = url.trim();
  if (RegExp(r'^https?://', caseSensitive: false).hasMatch(trimmed)) {
    return trimmed;
  }
  return 'https://$trimmed';
}

Future<void> launchExternal(String url) async {
  final uri = Uri.parse(toExternalHref(url));
  // On web this opens a new tab; webOnlyWindowName '_blank' + the platform's
  // noopener behavior covers the target/rel requirement from F4.3.
  await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
    webOnlyWindowName: '_blank',
  );
}

/// R4 — the single component every external anchor goes through:
/// normalizer + new-tab launch + outbound icon + screen-reader label
/// ("Opens official site in new tab", spec A7).
class ExternalLink extends StatelessWidget {
  const ExternalLink({
    super.key,
    required this.url,
    required this.label,
    this.style,
  });

  final String url;
  final String label;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label — opens official site in new tab',
      link: true,
      child: TextButton.icon(
        style: style,
        onPressed: () => launchExternal(url),
        icon: const Icon(Icons.open_in_new, size: 16),
        label: Text(label),
      ),
    );
  }
}
