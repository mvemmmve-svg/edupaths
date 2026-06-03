// lib/core/utils/responsive.dart
import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext ctx) => MediaQuery.of(ctx).size.width < 650;
  static bool isTablet(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    return w >= 650 && w < 1100;
  }
  static bool isDesktop(BuildContext ctx) => MediaQuery.of(ctx).size.width >= 1100;
  static double maxWidth(BuildContext ctx) {
    if (isDesktop(ctx)) return 1100;
    if (isTablet(ctx)) return 750;
    return double.infinity;
  }
  static EdgeInsets pagePadding(BuildContext ctx) {
    if (isDesktop(ctx)) return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    if (isTablet(ctx)) return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  const ResponsiveContainer({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final mw = Responsive.maxWidth(context);
    if (mw == double.infinity) return child;
    return Center(child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: mw), child: child));
  }
}
