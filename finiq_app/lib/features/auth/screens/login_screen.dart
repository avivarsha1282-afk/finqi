import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
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
              // Top spacer — 35% of screen is empty
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

              // Large empty space
              const Spacer(flex: 4),

              // Buttons
              Column(
                children: [
                  // Google button
                  _buildGoogleButton(context, ref, authState),
                  const SizedBox(height: 12),

                  // Email button (placeholder — leads to google)
                  OutlinedButton.icon(
                    onPressed: authState.isLoading ? null : () {
                      // For v1, email points to same Google flow
                      ref.read(authControllerProvider.notifier).signInWithGoogle()
                          .then((isNew) => _handleLoginResult(context, ref, isNew));
                    },
                    icon: const Icon(Icons.email_outlined, size: 20, color: AppColors.textSecondary),
                    label: Text(
                      'Continue with Email',
                      style: AppTextStyles.buttonSecondary.copyWith(color: AppColors.textPrimary),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(color: AppColors.borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Already have account
                  GestureDetector(
                    onTap: authState.isLoading ? null : () {
                      ref.read(authControllerProvider.notifier).signInWithGoogle()
                          .then((isNew) => _handleLoginResult(context, ref, isNew));
                    },
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 13),
                        children: [
                          TextSpan(text: 'Already have an account? ', style: TextStyle(color: AppColors.textTertiary)),
                          TextSpan(text: 'Log in', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Demo button
                  TextButton(
                    onPressed: authState.isLoading ? null : () async {
                      await ref.read(authControllerProvider.notifier).signInDemo();
                      if (context.mounted) context.go('/dashboard');
                    },
                    child: const Text('[ DEMO MODE ]',
                        style: TextStyle(fontSize: 11, color: AppColors.textTertiary, letterSpacing: 1)),
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
        final isNew = await ref.read(authControllerProvider.notifier).signInWithGoogle();
        if (context.mounted) _handleLoginResult(context, ref, isNew);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        height: 52,
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
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                ],
              ),
      ),
    );
  }

  void _handleLoginResult(BuildContext context, WidgetRef ref, bool isNew) {
    if (!context.mounted) return;
    // Router redirect handles navigation automatically
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text('G', style: TextStyle(
        color: Color(0xFF4285F4),
        fontSize: 16,
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
