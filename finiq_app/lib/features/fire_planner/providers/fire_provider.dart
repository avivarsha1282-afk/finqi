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
  return FireInputNotifier(FireGoalInput(
    targetAmount:  firePlan?.targetCorpus  ?? 15200000,
    targetYears:   firePlan?.targetYears   ?? 7,
    currentSavings: firePlan?.currentSavings ?? 200000,
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
