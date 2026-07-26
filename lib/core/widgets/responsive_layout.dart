import 'package:flutter/material.dart';

// ─── Core Breakpoints ────────────────────────────────────────────────────────

const double kMobileMaxWidth = 600;
const double kTabletMaxWidth = 1000;
const double kMaxContentWidth = 800; // max width for main content

/// Utility widget to render different layouts based on screen size
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= kTabletMaxWidth) {
          return desktop;
        } else if (constraints.maxWidth >= kMobileMaxWidth) {
          return tablet ?? desktop;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// A responsive scaffold that automatically switches between BottomNavigationBar
/// and NavigationRail depending on the screen size, and centers the content
/// inside a constrained box for large screens.
class ResponsiveScaffold extends StatefulWidget {
  final Widget body;
  final int currentIndex;
  final ValueChanged<int>? onNavigation;
  final FloatingActionButton? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.currentIndex = 0,
    this.onNavigation,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart_rounded),
      label: 'Analytics',
    ),
    NavigationDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet_rounded),
      label: 'Accounts',
    ),
    NavigationDestination(
      icon: Icon(Icons.category_outlined),
      selectedIcon: Icon(Icons.category_rounded),
      label: 'Categories',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ResponsiveLayout(
        // ── Mobile Layout ─────────────────────────────────────────────
        mobile: widget.body,

        // ── Tablet/Desktop Layout ────────────────────────────────────
        desktop: Row(
          children: [
            // Side Navigation
            NavigationRail(
              selectedIndex: widget.currentIndex,
              onDestinationSelected: widget.onNavigation,
              labelType: NavigationRailLabelType.all,
              backgroundColor: Theme.of(context).colorScheme.surface,
              destinations: _destinations.map((d) {
                return NavigationRailDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: Text(d.label),
                );
              }).toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            // Centered Main Content
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                  child: widget.body,
                ),
              ),
            ),
          ],
        ),
      ),

      // Only show bottom navigation on mobile
      bottomNavigationBar: MediaQuery.of(context).size.width < kMobileMaxWidth
          ? NavigationBar(
              selectedIndex: widget.currentIndex,
              onDestinationSelected: widget.onNavigation,
              destinations: _destinations,
            )
          : null,

      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
    );
  }
}
