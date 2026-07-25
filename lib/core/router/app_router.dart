import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../features/debug/presentation/pages/debug_database_page.dart';
import '../../features/expenses/domain/entities/transaction.dart';
import '../../features/expenses/presentation/pages/dashboard_page.dart';
import '../../features/expenses/presentation/pages/add_transaction_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../di/injection.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../widgets/responsive_layout.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(sl<AuthCubit>().stream),
  redirect: (context, state) {
    final authState = sl<AuthCubit>().state;
    final isGoingToAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    if (authState is AuthInitial) return null; // Still checking

    if (authState is AuthUnauthenticated) {
      if (!isGoingToAuth) return '/login';
    } else if (authState is AuthAuthenticated) {
      if (isGoingToAuth) return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ResponsiveScaffold(
          body: navigationShell,
          currentIndex: navigationShell.currentIndex,
          onNavigation: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/accounts',
              builder: (context, state) => const AccountsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/add-expense',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AddTransactionPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/edit-expense/:id',
      pageBuilder: (context, state) {
        final transaction = state.extra as TransactionEntity?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: AddTransactionPage(existingTransaction: transaction),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/debug',
      builder: (context, state) => const DebugDatabasePage(),
    ),
  ],
);
