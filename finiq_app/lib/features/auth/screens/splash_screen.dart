import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/user_prefs_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _determineRoute();
  }

  Future<void> _determineRoute() async {
    // Let the splash animation play for at least 2.2 seconds
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    // Not logged in → login screen
    if (user == null) {
      context.go('/login');
      return;
    }

    // --- Check onboarding status (Firestore primary, SharedPrefs fallback) ---
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (doc.exists && doc.data()?['onboarding_complete'] == true) {
        // Sync to SharedPrefs so offline works next time
        await UserPrefsService.setOnboardingComplete(true);
        if (mounted) context.go('/home');
      } else {
        // Firestore says not complete → check if SharedPrefs has it (edge case)
        final localDone = await UserPrefsService.isOnboardingComplete();
        if (mounted) context.go(localDone ? '/home' : '/onboarding/step1');
      }
    } catch (e) {
      // Firestore timeout or offline → fall back to SharedPreferences
      final localDone = await UserPrefsService.isOnboardingComplete();
      if (mounted) context.go(localDone ? '/home' : '/onboarding/step1');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo mark
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: CustomPaint(painter: _LogoPainter()),
            )
                .animate()
                .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                .scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1), duration: 800.ms),

            const SizedBox(height: 20),

            // FinIQ wordmark
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1),
                children: [
                  TextSpan(text: 'Fin', style: TextStyle(color: Colors.white)),
                  TextSpan(text: 'IQ', style: TextStyle(color: AppColors.primaryTeal)),
                ],
              ),
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 500.ms),

            const SizedBox(height: 12),

            // Tagline
            const Text(
              'YOUR FINANCIAL MENTOR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
                letterSpacing: 3,
              ),
            )
                .animate(delay: 500.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.3, end: 0, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;

    canvas.drawCircle(center, radius, paint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.primaryTeal
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(center.dx - radius * 1.4, center.dy + radius * 0.6);
    path.cubicTo(
      center.dx - radius * 0.4, center.dy - radius * 1.2,
      center.dx + radius * 0.4, center.dy + radius * 1.2,
      center.dx + radius * 1.4, center.dy - radius * 0.6,
    );
    canvas.drawPath(path, arcPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}
