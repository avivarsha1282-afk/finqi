import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/user_data_service.dart';
import '../../../services/user_prefs_service.dart';

class OnboardingProcessingScreen extends StatefulWidget {
  const OnboardingProcessingScreen({super.key});
  @override State<OnboardingProcessingScreen> createState() => _OnboardingProcessingScreenState();
}

class _OnboardingProcessingScreenState extends State<OnboardingProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringCtrl;
  int _messageIndex = 0;
  Timer? _messageTimer;
  bool _hasSubmitted = false; // Guard against double API call

  static const _messages = [
    'Saving your financial profile...',
    'Analysing your income patterns...',
    'Calculating tax optimisation...',
    'Building your FIRE roadmap...',
    'Preparing your health score...',
    'Your plan is ready! ✨',
  ];

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

    // Cycle messages
    _messageTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_messageIndex < _messages.length - 1) {
        setState(() => _messageIndex++);
      } else {
        timer.cancel();
      }
    });

    // Process data and navigate
    _processAndNavigate();
  }

  Future<void> _processAndNavigate() async {
    if (_hasSubmitted) return; // Prevent double submission
    _hasSubmitted = true;

    try {
      final raw = await UserPrefsService.getString('onboarding_data');
      if (raw != null) {
        final data = json.decode(raw) as Map<String, dynamic>;

        // 1. Cache raw responses to SharedPreferences
        await UserDataService.persistOnboardingData(data);

        // 2. Local fallback calculation (optimistic UI)
        await UserDataService.calculateAndSaveLocally(data);

        // 3. Post to backend ONCE — generates health score, FIRE plan, tax report
        try {
          final result = await ApiService.instance.saveOnboarding(data);

          if (result['success'] == true) {
            // Write backend analysis to local prefs for offline access
            if (result['health_score'] != null) {
              final hs = result['health_score'];
              await UserPrefsService.setInt('health_score', hs['total_score']);
              await UserPrefsService.setString('grade', hs['grade']);

              if (hs['priority_actions'] != null && (hs['priority_actions'] as List).isNotEmpty) {
                final pa = hs['priority_actions'];
                if (pa.length > 0) await UserPrefsService.setString('priority_action_1', pa[0]['dimension']);
                if (pa.length > 1) await UserPrefsService.setString('priority_action_2', pa[1]['dimension']);
                if (pa.length > 2) await UserPrefsService.setString('priority_action_3', pa[2]['dimension']);
              }
              if (hs['dimensions'] != null) {
                final dims = hs['dimensions'];
                await UserPrefsService.setInt('dim_emergency', dims['emergency_fund'] ?? 0);
                await UserPrefsService.setInt('dim_insurance', dims['insurance'] ?? 0);
                await UserPrefsService.setInt('dim_investment', dims['diversification'] ?? 0);
                await UserPrefsService.setInt('dim_debt', dims['debt_health'] ?? 0);
                await UserPrefsService.setInt('dim_tax', dims['tax_efficiency'] ?? 0);
                await UserPrefsService.setInt('dim_fire', dims['retirement'] ?? 0);
              }
            }
          }
        } catch (e) {
          print("Backend analysis failed: $e");
          // Still proceed — we have local fallback already calculated
        }

        // 4. Save onboarding_complete flag to BOTH Firestore AND SharedPreferences
        //    Firestore = primary (survives uninstall/sign-out)
        //    SharedPreferences = offline fallback
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          // Firestore: ONLY the onboarding flag (MongoDB is source of truth for all other data)
          FirebaseFirestore.instance.collection('users').doc(uid).set({
            'onboarding_complete': true,
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      await UserPrefsService.setOnboardingComplete(true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.go('/home');
    } catch (e) {
      // Even on error, mark onboarding complete to prevent infinite loop
      await UserPrefsService.setOnboardingComplete(true);
      if (mounted) context.go('/home');
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Artha avatar with ring
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _ringCtrl,
                      builder: (_, __) {
                        return Container(
                          width: 80 + (_ringCtrl.value * 40),
                          height: 80 + (_ringCtrl.value * 40),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryTeal.withOpacity(1 - _ringCtrl.value),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryTeal,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('A', style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        )),
                      ),
                    ),
                  ],
                ),
              ).animate().scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 40),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _messages[_messageIndex],
                  key: ValueKey(_messageIndex),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: _messageIndex == _messages.length - 1 ? FontWeight.w700 : FontWeight.w400,
                    color: _messageIndex == _messages.length - 1 ? AppColors.primaryTeal : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
