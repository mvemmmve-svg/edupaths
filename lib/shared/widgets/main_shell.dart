// lib/shared/widgets/main_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _routes = [
    AppConstants.routeHome, AppConstants.routeExplore,
    AppConstants.routeSaved, AppConstants.routeRoadmap,
    AppConstants.routeProfile,
  ];
  static const _labels = ['Home', 'Explore', 'Saved', 'Roadmap', 'Profile'];
  static const _icons = [
    Icons.home_rounded, Icons.search_rounded, Icons.bookmark_rounded,
    Icons.map_rounded, Icons.person_rounded,
  ];

  int _idx(String loc) {
    for (int i = 0; i < _routes.length; i++) {
      if (loc.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  void _go(BuildContext ctx, int i) => ctx.go(_routes[i]);

  /// Floating EduBot launcher — visible on every main screen (item 3).
  Widget? _edubotFab(BuildContext context, String loc) {
    if (loc.startsWith('/edubot')) return null; // not on the chat itself
    return FloatingActionButton(
      onPressed: () => context.push(AppConstants.routeEduBot),
      // Bright green so it stands out from the purple scheme
      backgroundColor: const Color(0xFF00C853),
      tooltip: 'Ask EduBot',
      child: const Text('🤖', style: TextStyle(fontSize: 24)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _idx(loc);

    if (Responsive.isDesktop(context) || Responsive.isTablet(context)) {
      // ── Sidebar navigation for tablet/desktop ──
      return Scaffold(
        floatingActionButton: _edubotFab(context, loc),
        body: Row(children: [
          NavigationRail(
            backgroundColor: AppColors.bgCard,
            selectedIndex: idx,
            onDestinationSelected: (i) => _go(context, i),
            extended: Responsive.isDesktop(context),
            minWidth: 72,
            minExtendedWidth: 200,
            selectedIconTheme: const IconThemeData(color: AppColors.primary),
            selectedLabelTextStyle: const TextStyle(
              fontFamily: 'Nunito', color: AppColors.primary,
              fontWeight: FontWeight.w800, fontSize: 13),
            unselectedIconTheme: const IconThemeData(color: AppColors.textLight),
            unselectedLabelTextStyle: const TextStyle(
              fontFamily: 'Nunito', color: AppColors.textLight, fontSize: 13),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(children: [
                Container(width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight]),
                    borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.school_rounded,
                    color: Colors.white, size: 22)),
                if (Responsive.isDesktop(context)) ...[
                  const SizedBox(height: 6),
                  const Text('EduPaths', style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 14,
                    fontWeight: FontWeight.w900, color: AppColors.primary)),
                ],
              ]),
            ),
            destinations: List.generate(_labels.length, (i) =>
              NavigationRailDestination(
                icon: Icon(_icons[i]),
                label: Text(_labels[i]))),
          ),
          const VerticalDivider(thickness: 1, width: 1, color: AppColors.border),
          Expanded(child: ResponsiveContainer(child: child)),
        ]),
      );
    }

    // ── Bottom navigation for mobile ──
    return Scaffold(
      body: child,
      floatingActionButton: _edubotFab(context, loc),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          boxShadow: [BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(child: SizedBox(
          height: 64,
          child: Row(children: List.generate(_labels.length, (i) =>
            _Tab(icon: _icons[i], label: _labels[i],
              sel: idx == i, onTap: () => _go(context, i)))),
        )),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final IconData icon; final String label; final bool sel; final VoidCallback onTap;
  const _Tab({required this.icon, required this.label, required this.sel, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap, behavior: HitTestBehavior.opaque,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: sel ? AppColors.primaryPale : Colors.transparent,
            borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 22,
            color: sel ? AppColors.primary : AppColors.textLight)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
          color: sel ? AppColors.primary : AppColors.textLight)),
      ]),
    ),
  );
}
