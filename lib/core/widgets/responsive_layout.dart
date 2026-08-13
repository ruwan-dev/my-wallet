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

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = widget.currentIndex == index;
    final activeColor = const Color(0xFF6D28D9); // Deep Purple
    final inactiveColor = Colors.grey.shade500;
    final color = isSelected ? activeColor : inactiveColor;
    
    return InkWell(
      onTap: () => widget.onNavigation?.call(index),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(isSelected ? activeIcon : icon, color: color, size: 24),
            ),
            const SizedBox(height: 2),
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
          ? BottomAppBar(
              shape: const CircularNotchedRectangle(),
              notchMargin: 8.0,
              padding: EdgeInsets.zero,
              child: SizedBox(
                height: 72,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                    _buildNavItem(1, Icons.category_outlined, Icons.category_rounded, 'Categories'),
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
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)], // Deep Purple gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () => context.push('/add-transaction'),
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
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)], // Deep Purple gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.4),
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
    final activeColor = const Color(0xFF6D28D9); // Deep Purple
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
