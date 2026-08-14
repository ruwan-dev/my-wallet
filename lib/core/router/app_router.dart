import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../features/debug/presentation/pages/debug_database_page.dart';
import '../../features/expenses/domain/entities/transaction.dart';
import '../../features/expenses/presentation/pages/dashboard_page.dart';
import '../../features/expenses/presentation/pages/add_transaction_page.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/admin/presentation/pages/admin_console_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../widgets/premium_aurora_vector_background.dart';
import '../di/injection.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/accounts/presentation/pages/add_account_page.dart';
import '../../features/expenses/presentation/pages/manage_categories_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/legal_page.dart';
import '../../features/profile/presentation/pages/change_password_page.dart';
import '../../features/profile/presentation/pages/currency_selection_page.dart';
import '../../features/expenses/presentation/pages/budgets_page.dart';
import '../../features/expenses/presentation/pages/transactions_page.dart';
import '../../features/expenses/presentation/pages/account_transactions_page.dart';
import '../../features/expenses/domain/entities/account.dart';
import '../widgets/responsive_layout.dart';
import '../../features/budgets/presentation/pages/budgets_main_page.dart';
import '../../features/expenses/presentation/pages/recurring_bills_page.dart';
import '../../features/budgets/presentation/pages/bucket_planner_page.dart';
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
      if (authState.user.isAdmin) {
        if (state.matchedLocation != '/admin') return '/admin';
      } else {
        if (isGoingToAuth) return '/';
      }
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const PremiumAuroraVectorBackground(child: LoginPage()),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const PremiumAuroraVectorBackground(child: RegisterPage()),
    ),
    GoRoute(
      path: '/add-transaction',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: PremiumAuroraVectorBackground(
          child: AddTransactionPage(
            existingTransaction: state.extra as TransactionEntity?,
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/legal',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: LegalPage(title: state.extra as String? ?? 'Legal Info'),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/change-password',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: ChangePasswordPage(email: state.extra as String),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/currency-selection',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const CurrencySelectionPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
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
              routes: [
                GoRoute(
                  path: 'budgets-main',
                  pageBuilder: (context, state) => const NoTransitionPage(child: BudgetsMainPage()),
                ),
                GoRoute(
                  path: 'buckets-planner',
                  pageBuilder: (context, state) => const NoTransitionPage(child: BucketPlannerPage()),
                ),
                GoRoute(
                  path: 'analytics',
                  pageBuilder: (context, state) => const NoTransitionPage(child: AnalyticsPage()),
                ),
                GoRoute(
                  path: 'recurring-bills',
                  pageBuilder: (context, state) => const NoTransitionPage(child: RecurringBillsPage()),
                ),
                GoRoute(
                  path: 'all-transactions',
                  pageBuilder: (context, state) => const NoTransitionPage(child: TransactionsPage()),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/manage-categories',
              builder: (context, state) => const ManageCategoriesPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/accounts',
              builder: (context, state) => const AccountsPage(),
              routes: [
                GoRoute(
                  path: 'add-account',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: AddAccountPage(
                      account: state.extra as AccountEntity?,
                    ),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      );
                    },
                  ),
                ),
              ],
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
      path: '/debug',
      builder: (context, state) => const DebugDatabasePage(),
    ),
    GoRoute(
      path: '/budgets',
      builder: (context, state) => const BudgetsPage(),
    ),
    GoRoute(
      path: '/account-transactions',
      builder: (context, state) {
        final account = state.extra as AccountEntity;
        return AccountTransactionsPage(account: account);
      },
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminConsolePage(),
    ),
  ],
);
