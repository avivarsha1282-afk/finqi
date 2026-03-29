import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/language/screens/language_selection_screen.dart';
import '../../features/onboarding/screens/onboarding_welcome_screen.dart';
import '../../features/onboarding/screens/onboarding_chat_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/health_score/screens/health_score_screen.dart';
import '../../features/health_score/screens/dimension_detail_screen.dart';
import '../../features/fire_planner/screens/fire_planner_screen.dart';
import '../../features/tax_wizard/screens/tax_wizard_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../constants/api_constants.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

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

      // User is logged in — check onboarding
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString(ApiConstants.keyLanguage);
      final onboardingDone = prefs.getBool(ApiConstants.keyOnboardingComplete) ?? false;

      if (lang == null) {
        if (currentPath == '/language') return null;
        return '/language';
      }

      if (!onboardingDone) {
        if (currentPath.startsWith('/onboarding')) return null;
        return '/onboarding/welcome';
      }

      if (currentPath == '/login' || currentPath == '/language' ||
          currentPath.startsWith('/onboarding')) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/language', builder: (_, __) => const LanguageSelectionScreen()),
      GoRoute(path: '/onboarding/welcome', builder: (_, __) => const OnboardingWelcomeScreen()),
      GoRoute(path: '/onboarding/chat', builder: (_, __) => const OnboardingChatScreen()),

      // Shell with bottom nav
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithBottomNav(child: child, currentPath: state.uri.path);
        },
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/health', builder: (_, __) => const HealthScoreScreen()),
          GoRoute(
            path: '/health/detail/:dimension',
            builder: (_, state) => DimensionDetailScreen(
              dimensionName: state.pathParameters['dimension'] ?? '',
            ),
          ),
          GoRoute(path: '/fire', builder: (_, __) => const FirePlannerScreen()),
          GoRoute(path: '/tax', builder: (_, __) => const TaxWizardScreen()),
          GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
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
    if (path.startsWith('/tax')) return 3;
    if (path.startsWith('/profile')) return 4;
    if (path.startsWith('/chat')) return 4; // Chat is under Profile umbrella
    return 0; // dashboard
  }

  @override
  Widget build(BuildContext context) {
    final idx = _selectedIndex(currentPath);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF1F2937), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: idx,
          onTap: (i) {
            switch (i) {
              case 0: context.go('/dashboard'); break;
              case 1: context.go('/health'); break;
              case 2: context.go('/fire'); break;
              case 3: context.go('/tax'); break;
              case 4: context.go('/profile'); break;
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: 'Health'),
            BottomNavigationBarItem(icon: Icon(Icons.local_fire_department_rounded), label: 'FIRE'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Tax'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// Listenable for GoRouter refresh on auth changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.listen((_) => notifyListeners());
  }
  late final dynamic _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
