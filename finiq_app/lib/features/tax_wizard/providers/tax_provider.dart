import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/tax_report_model.dart';
import '../../../services/mock_data_service.dart';

/// Tax provider — calculates locally using Indian FY 2025-26 slabs
final taxProvider =
    Provider.family<TaxReportModel, double>((ref, income) {
  return MockDataService.getTaxReport(annualIncome: income);
});
