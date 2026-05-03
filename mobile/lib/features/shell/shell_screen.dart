import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    ('/home', Icons.home_rounded, 'Home'),
    ('/destinations', Icons.place_rounded, 'Explore'),
    ('/map', Icons.map_rounded, 'Map'),
    ('/passport', Icons.auto_stories_rounded, 'Passport'),
    ('/profile', Icons.person_rounded, 'Profile'),
  ];

  int _indexOf(BuildContext ctx) {
    final loc = GoRouterState.of(ctx).uri.path;
    for (var i = 0; i < _tabs.length; i++) {
      if (loc.startsWith(_tabs[i].$1)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: TrailColors.surface,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
        ),
        child: NavigationBar(
          backgroundColor: TrailColors.surface,
          indicatorColor: TrailColors.primary.withOpacity(0.18),
          selectedIndex: _indexOf(context),
          onDestinationSelected: (i) => context.go(_tabs[i].$1),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: _tabs
              .map((t) => NavigationDestination(
                    icon: Icon(t.$2, color: TrailColors.onSurfaceMuted),
                    selectedIcon: Icon(t.$2, color: TrailColors.primary),
                    label: t.$3,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
