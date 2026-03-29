import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/tax_report_model.dart';
import '../../../services/api_service.dart';

final taxProvider =
    FutureProvider.autoDispose.family<TaxReportModel, double>((ref, income) async {
  return await ApiService.instance.compareTax(annualIncome: income);
});
