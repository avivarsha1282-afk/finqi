import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/onboarding/screens/onboarding_step1_screen.dart';
import '../../features/onboarding/screens/onboarding_step2_screen.dart';
import '../../features/onboarding/screens/onboarding_step3_screen.dart';
import '../../features/onboarding/screens/onboarding_step4_screen.dart';
import '../../features/onboarding/screens/onboarding_step5_screen.dart';
import '../../features/onboarding/screens/onboarding_processing_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/health_score/screens/health_score_screen.dart';
import '../../features/health_score/screens/dimension_detail_screen.dart';
import '../../features/fire_planner/screens/fire_planner_screen.dart';
import '../../features/tax_wizard/screens/tax_wizard_screen.dart';
import '../../features/artha/screens/artha_chat_screen.dart';
import '../../features/markets/screens/markets_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/expenses/screens/expense_tracker_screen.dart';
import '../../features/smart_buy/screens/smart_buy_mode_screen.dart';
import '../../features/smart_buy/screens/smart_buy_input_screen.dart';
import '../../features/smart_buy/screens/smart_buy_single_result_screen.dart';
import '../../features/smart_buy/screens/smart_buy_compare_result_screen.dart';
import '../../services/user_prefs_service.dart';
import 'dart:typed_data';


final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    redirect: (context, state) async {
      final user = FirebaseAuth.instance.currentUser;
      final currentPath = state.uri.path;

      // Allow splash to handle its own logic
      if (currentPath == '/splash') return null;

      if (user == null) {
        if (currentPath == '/login') return null;
        return '/login';
      }

      // User is logged in — check UID-prefixed onboarding status
      final onboardingDone = await UserPrefsService.isOnboardingComplete();

      if (!onboardingDone) {
        if (currentPath.startsWith('/onboarding')) return null;
        return '/onboarding/step1';
      }

      if (currentPath == '/login' || currentPath.startsWith('/onboarding')) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

      // Onboarding steps
      GoRoute(path: '/onboarding/step1', builder: (_, __) => const OnboardingStep1Screen()),
      GoRoute(path: '/onboarding/step2', builder: (_, __) => const OnboardingStep2Screen()),
      GoRoute(path: '/onboarding/step3', builder: (_, __) => const OnboardingStep3Screen()),
      GoRoute(path: '/onboarding/step4', builder: (_, __) => const OnboardingStep4Screen()),
      GoRoute(path: '/onboarding/step5', builder: (_, __) => const OnboardingStep5Screen()),
      GoRoute(path: '/onboarding/processing', builder: (_, __) => const OnboardingProcessingScreen()),

      // Profile (push route, NOT in shell)
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const EditProfileScreen(),
      ),

      // Smart Buy Lens — 4 screen flow (pushed on top, not inside shell)
      GoRoute(
        path: '/smart-buy',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const SmartBuyModeScreen(),
      ),
      GoRoute(
        path: '/smart-buy/input',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => SmartBuyInputScreen(mode: state.extra as String? ?? 'single'),
      ),
      GoRoute(
        path: '/smart-buy/result/single',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => SmartBuySingleResultScreen(images: state.extra as List<Uint8List>),
      ),
      GoRoute(
        path: '/smart-buy/result/compare',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => SmartBuyCompareResultScreen(images: state.extra as List<Uint8List>),
      ),

      // Shell with bottom nav: Home | Health | FIRE | Artha | Tax
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithBottomNav(child: child, currentPath: state.uri.path);
        },
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/health', builder: (_, __) => const HealthScoreScreen()),
          GoRoute(
            path: '/health/detail/:dimension',
            builder: (_, state) => DimensionDetailScreen(
              dimensionName: state.pathParameters['dimension'] ?? '',
            ),
          ),
          GoRoute(path: '/fire', builder: (_, __) => const FirePlannerScreen()),
          GoRoute(path: '/markets', builder: (_, __) => const MarketsScreen()),
          GoRoute(path: '/artha', builder: (_, __) => const ArthaChatScreen()),
          GoRoute(path: '/tax', builder: (_, __) => const TaxWizardScreen()),
          GoRoute(path: '/expenses', builder: (_, __) => const ExpenseTrackerScreen()),
        ],
      ),
    ],
  );
});

// Shell widget with bottom navigation
class ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const ScaffoldWithBottomNav({
    super.key,
    required this.child,
    required this.currentPath,
  });

  int _selectedIndex(String path) {
    if (path.startsWith('/health')) return 1;
    if (path.startsWith('/fire')) return 2;
    if (path.startsWith('/markets')) return 3;
    if (path.startsWith('/artha')) return 4;
    if (path.startsWith('/tax')) return 5;
    return 0; // home
  }

  @override
  Widget build(BuildContext context) {
    final idx = _selectedIndex(currentPath);
    return Scaffold(
      body: child,
      floatingActionButton: currentPath != '/expenses' && currentPath != '/artha' && currentPath != '/markets'
          ? FloatingActionButton.extended(
              heroTag: 'fab_add_expense',
              onPressed: () => context.go('/expenses'),
              backgroundColor: const Color(0xFF00C896),
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              elevation: 4,
            )
          : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF1F2937), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: idx,
          onTap: (i) {
            switch (i) {
              case 0: context.go('/home'); break;
              case 1: context.go('/health'); break;
              case 2: context.go('/fire'); break;
              case 3: context.go('/markets'); break;
              case 4: context.go('/artha'); break;
              case 5: context.go('/tax'); break;
            }
          },
          selectedFontSize: 10,
          unselectedFontSize: 10,
          iconSize: 22,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: 'Health'),
            BottomNavigationBarItem(icon: Icon(Icons.local_fire_department_rounded), label: 'FIRE'),
            BottomNavigationBarItem(icon: Icon(Icons.candlestick_chart_outlined), activeIcon: Icon(Icons.candlestick_chart), label: 'Markets'),
            BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_rounded), label: 'Artha'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Tax'),
          ],
        ),
      ),
    );
  }
}

// Listenable for GoRouter refresh on auth changes
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
