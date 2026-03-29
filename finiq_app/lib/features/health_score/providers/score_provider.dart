import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/health_score_model.dart';
import '../../../services/api_service.dart';

final scoreProvider = FutureProvider.autoDispose<HealthScoreModel>((ref) async {
  return await ApiService.instance.calculateScore();
});
