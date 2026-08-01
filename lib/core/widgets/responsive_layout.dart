import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = widget.currentIndex == index;
    final color = isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade500;
    
    return InkWell(
      onTap: () => widget.onNavigation?.call(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          ? BottomAppBar(
              shape: const CircularNotchedRectangle(),
              notchMargin: 8.0,
              child: SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                    _buildNavItem(1, Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Analytics'),
                    const SizedBox(width: 48), // Space for FAB
                    _buildNavItem(2, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Accounts'),
                    _buildNavItem(3, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
                  ],
                ),
              ),
            )
          : null,

      floatingActionButton: MediaQuery.of(context).size.width < kMobileMaxWidth
          ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () => context.push('/add-expense'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              ),
            )
          : widget.floatingActionButton,
      floatingActionButtonLocation: MediaQuery.of(context).size.width < kMobileMaxWidth
          ? FloatingActionButtonLocation.centerDocked
          : widget.floatingActionButtonLocation,
    );
  }
}
