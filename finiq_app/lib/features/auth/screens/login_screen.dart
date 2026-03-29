import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (_, next) {
      if (next.error != null && next.error!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Logo
              Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryTeal.withOpacity(0.25),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: CustomPaint(painter: _MiniLogoPainter()),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                      children: [
                        TextSpan(text: 'Fin', style: TextStyle(color: Colors.white)),
                        TextSpan(text: 'IQ', style: TextStyle(color: AppColors.primaryTeal)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'YOUR FINANCIAL MENTOR',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2.5,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 600.ms),

              const Spacer(flex: 4),

              // Google Sign-In — ONLY auth method
              Column(
                children: [
                  _buildGoogleButton(context, ref, authState),
                  const SizedBox(height: 32),
                  const Text(
                    'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textTertiary, height: 1.5),
                  ),
                ],
              ).animate(delay: 400.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 20),

              // Footer
              const Text(
                'RBI · SEBI · IRDAI aligned',
                style: TextStyle(fontSize: 10, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(BuildContext context, WidgetRef ref, AuthState authState) {
    return GestureDetector(
      onTap: authState.isLoading ? null : () async {
        await ref.read(authControllerProvider.notifier).signInWithGoogle();
        // Router redirect handles navigation automatically
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: authState.isLoading
            ? const Center(child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: AppColors.primaryTeal, strokeWidth: 2)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleIcon(),
                  const SizedBox(width: 12),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text('G', style: TextStyle(
        color: Color(0xFF4285F4),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      )),
    );
  }
}

class _MiniLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.28;
    canvas.drawCircle(center, radius, paint);
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
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
