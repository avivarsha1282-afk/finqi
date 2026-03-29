import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/fire_plan_model.dart';
import '../../../services/mock_data_service.dart';
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

/// Calculate FIRE plan locally
final firePlanProvider =
    Provider.family<FirePlanModel, FireGoalInput>((ref, input) {
  final sip = MockDataService.calculateSIP(
    targetAmount: input.targetAmount,
    currentSavings: input.currentSavings,
    years: input.targetYears,
  );
  final timeline = MockDataService.generateTimeline(
    currentSavings: input.currentSavings,
    monthlySip: sip,
    years: input.targetYears,
  );

  final aggressiveSip = MockDataService.calculateSIP(
    targetAmount: input.targetAmount,
    currentSavings: input.currentSavings,
    years: (input.targetYears / 2).ceil(),
  );

  return FirePlanModel(
    targetCorpus: input.targetAmount,
    targetYears: input.targetYears,
    currentSavings: input.currentSavings,
    requiredMonthlySip: sip,
    projectedCorpus: input.targetAmount,
    estimatedReturn: 12.0,
    scenarios: [
      FireScenario(
        years: (input.targetYears / 2).ceil(),
        label: 'Hyper-Aggressive',
        monthlySip: aggressiveSip,
        risk: 'HIGH RISK',
      ),
      FireScenario(
        years: input.targetYears,
        label: 'Sustainable Growth',
        monthlySip: sip,
        risk: 'RECOMMENDED',
        isRecommended: true,
      ),
    ],
    assetAllocation: const [
      AssetAllocation(name: 'Equity', percentage: 40, colorHex: '#00C896'),
      AssetAllocation(name: 'Index Funds', percentage: 30, colorHex: '#3B82F6'),
      AssetAllocation(name: 'Gold / Debt', percentage: 20, colorHex: '#F59E0B'),
      AssetAllocation(name: 'Intl. Funds', percentage: 10, colorHex: '#8B5CF6'),
    ],
    arthaMessage: 'Your ${input.targetYears}-year FIRE plan requires ₹${(sip / 1000).toInt()}K/mo SIP at 12% estimated returns.',
    growthData: timeline,
    achievability: sip <= 100000 ? 'ACHIEVABLE' : (sip <= 300000 ? 'STRETCH' : 'VERY_AGGRESSIVE'),
  );
});
