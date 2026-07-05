// lib/core/utils/update_guard.dart
//
// Two quality-of-life behaviours for a frequently-updated web app:
//
//  1. UPDATE BANNER — every few minutes (and whenever the person returns to
//     the tab) we ask the server, very cheaply, whether the app's main
//     program file has changed since this tab loaded it. If it has, a small
//     banner offers a one-tap refresh. No more visitors stuck on old builds.
//
//  2. REFRESH-ON-RETURN — when the person switches back to this tab after
//     being away, their profile, matches and saved items are re-fetched, so
//     admin/tier changes made in the meantime show up without a manual
//     reload.

import 'dart:async';
import 'dart:html' as html; // Flutter web only — this app ships web-only.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';

class UpdateGuard extends ConsumerStatefulWidget {
  final Widget child;
  const UpdateGuard({super.key, required this.child});

  @override
  ConsumerState<UpdateGuard> createState() => _UpdateGuardState();
}

class _UpdateGuardState extends ConsumerState<UpdateGuard>
    with WidgetsBindingObserver {
  String? _initialTag;
  bool _updateAvailable = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _readTag().then((t) => _initialTag = t);
    _timer = Timer.periodic(const Duration(minutes: 3), (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Person came back to the tab: refresh their data + check for updates
      ref.invalidate(appUserProvider);
      ref.invalidate(matchesProvider);
      ref.invalidate(savedItemsProvider);
      ref.invalidate(isPremiumProvider);
      _check();
    }
  }

  /// Reads the server's fingerprint (ETag) of the app's main program file.
  /// A HEAD request downloads no content — it is only a few bytes.
  Future<String?> _readTag() async {
    try {
      final res = await html.HttpRequest.request(
        '/main.dart.js',
        method: 'HEAD',
        requestHeaders: {'cache-control': 'no-cache'},
      );
      return res.getResponseHeader('etag') ??
          res.getResponseHeader('last-modified');
    } catch (_) {
      return null;
    }
  }

  Future<void> _check() async {
    if (_updateAvailable || _initialTag == null) return;
    final now = await _readTag();
    if (now != null && now != _initialTag && mounted) {
      setState(() => _updateAvailable = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      widget.child,
      if (_updateAvailable)
        Positioned(
          left: 16,
          right: 16,
          bottom: 90, // sits above the bottom navigation bar
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.textDark,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Row(children: [
                const Text('✨', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                const Expanded(
                    child: Text('A new version of EduPaths is ready',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700))),
                TextButton(
                    onPressed: () =>
                        html.window.location.reload(),
                    style: TextButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8)),
                    child: const Text('Refresh',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13))),
              ]),
            ),
          ),
        ),
    ]);
  }
}
