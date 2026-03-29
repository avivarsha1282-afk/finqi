import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/health_score_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';

/// Health score provider — reads from SharedPreferences via dashboardProvider
final scoreProvider = FutureProvider<HealthScoreModel>((ref) async {
  final dash = await ref.watch(dashboardProvider.future);
  return dash.score;
});
