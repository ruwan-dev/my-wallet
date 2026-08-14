import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/expenses/presentation/pages/transactions_page.dart';
import '../../features/expenses/presentation/pages/account_transactions_page.dart';

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
    final width = MediaQuery.of(context).size.width;
    if (width >= kTabletMaxWidth) {
      return desktop;
    } else if (width >= kMobileMaxWidth) {
      return tablet ?? desktop;
    } else {
      return mobile;
    }
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
      icon: Icon(Icons.category_outlined),
      selectedIcon: Icon(Icons.category_rounded),
      label: 'Categories',
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

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon) {
    final isSelected = widget.currentIndex == index;
    final color = isSelected ? Colors.white : Colors.white.withOpacity(0.5);
    
    return InkWell(
      onTap: () => widget.onNavigation?.call(index),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Icon(isSelected ? activeIcon : icon, color: color, size: 26),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Fixes black hole behind BottomAppBar notch
      backgroundColor: const Color(0xFFF2F8F7), // Match the dashboard light background
      body: ResponsiveLayout(
        // ── Mobile Layout ─────────────────────────────────────────────
        mobile: widget.body,

        // ── Tablet/Desktop Layout ────────────────────────────────────
        desktop: Row(
          children: [
            // Side Navigation
            _buildDesktopSidebar(context),
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
          ? Container(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
              height: 72 + MediaQuery.of(context).padding.bottom,
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF5AD8D8),
                      Color(0xFF40C4B5),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF40C4B5).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, Icons.home_outlined, Icons.home_rounded),
                    _buildNavItem(1, Icons.category_outlined, Icons.category_rounded),
                    // Central FAB inside the bar
                    GestureDetector(
                      onTap: () => context.push('/add-transaction'),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF6DE0E0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                    _buildNavItem(2, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded),
                    _buildNavItem(3, Icons.person_outline_rounded, Icons.person_rounded),
                  ],
                ),
              )
          : null,

      floatingActionButton: MediaQuery.of(context).size.width < kMobileMaxWidth
          ? null // Removed since it's embedded in the new pill bar
          : widget.floatingActionButton,
      floatingActionButtonLocation: MediaQuery.of(context).size.width < kMobileMaxWidth
          ? null
          : widget.floatingActionButtonLocation,
    );
  }

  Widget _buildDesktopSidebar(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: 90,
      margin: const EdgeInsets.only(left: 16, top: 16, bottom: 16, right: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Column(
            children: [
              const SizedBox(height: 48),
              
              // Nav Items
              _buildDesktopNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              const SizedBox(height: 24),
              _buildDesktopNavItem(1, Icons.category_outlined, Icons.category_rounded, 'Categories'),
              
              const SizedBox(height: 32),
              
              // Add Button
              GestureDetector(
                onTap: () => context.push('/add-transaction'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF70D2C6), Color(0xFF50C8C8)], // Teal gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF50C8C8).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                ),
              ),
              
              const SizedBox(height: 32),
              
              _buildDesktopNavItem(2, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Accounts'),
              const SizedBox(height: 24),
              _buildDesktopNavItem(3, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = widget.currentIndex == index;
    final activeColor = const Color(0xFF50C8C8); // Teal
    final inactiveColor = Colors.grey.shade500;
    final color = isSelected ? activeColor : inactiveColor;
    
    return InkWell(
      onTap: () => widget.onNavigation?.call(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(isSelected ? activeIcon : icon, color: color, size: 26),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
