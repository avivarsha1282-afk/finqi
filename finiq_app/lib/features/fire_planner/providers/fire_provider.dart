import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/fire_plan_model.dart';
import '../../../services/api_service.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class FireGoalInput {
  final double targetAmount;
  final int targetYears;
  final double currentSavings;

  const FireGoalInput({
    required this.targetAmount,
    required this.targetYears,
    required this.currentSavings,
  });
}

class FireInputNotifier extends StateNotifier<FireGoalInput> {
  FireInputNotifier(FireGoalInput initial) : super(initial);

  void update({double? targetAmount, int? targetYears, double? currentSavings}) {
    state = FireGoalInput(
      targetAmount: targetAmount ?? state.targetAmount,
      targetYears: targetYears ?? state.targetYears,
      currentSavings: currentSavings ?? state.currentSavings,
    );
  }
}

final fireInputProvider =
    StateNotifierProvider<FireInputNotifier, FireGoalInput>((ref) {
  final dashAsync = ref.watch(dashboardProvider);
  final firePlan = dashAsync.valueOrNull?.firePlan;
  final profile = dashAsync.valueOrNull?.profile;

  // PRIMARY: profile.current_savings (always fresh after profile update)
  // FALLBACK: firePlan.currentSavings (from onboarding calculation)
  // LAST RESORT: 200000
  final currentSavings = (profile != null && (profile['current_savings'] ?? 0) > 0)
      ? (profile['current_savings'] as num).toDouble()
      : firePlan?.currentSavings ?? 200000;

  // TIMELINE: profile is authoritative (Edit Profile sets this)
  // FALLBACK: firePlan value from last calculation
  // LAST RESORT: 7 years
  final profileTimeline = profile?['target_timeline'];
  final targetYears = (profileTimeline != null && (profileTimeline as num).toInt() > 0)
      ? profileTimeline.toInt()
      : firePlan?.targetYears ?? 7;

  return FireInputNotifier(FireGoalInput(
    targetAmount:  firePlan?.targetCorpus  ?? 15200000,
    targetYears:   targetYears,
    currentSavings: currentSavings,
  ));
});

/// Calculate FIRE plan via backend
final firePlanProvider =
    FutureProvider.family<FirePlanModel, FireGoalInput>((ref, input) async {
  return await ApiService.instance.getFirePlan(
    targetAmount: input.targetAmount,
    targetYears: input.targetYears,
    currentSavings: input.currentSavings,
  );
});
