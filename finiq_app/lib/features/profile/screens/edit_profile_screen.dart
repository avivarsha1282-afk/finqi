import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/user_prefs_service.dart';
import '../../../services/user_data_service.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../features/onboarding/widgets/onboarding_shared.dart';
import '../../language/providers/language_provider.dart';
import '../../../l10n/t.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic> _data = {};
  bool _loaded = false;

  // Personal
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String _occupation = 'Salaried Employee';

  // Financial
  final _incomeCtrl = TextEditingController();
  final _expenseCtrl = TextEditingController();
  final _savingsCtrl = TextEditingController();
  final _goalAmountCtrl = TextEditingController();
  final _goalYearsCtrl = TextEditingController();
  String _riskAppetite = 'Moderate';
  String _goalType = 'Build Wealth';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await UserDataService.getUserProfile();
    setState(() {
      _data = profile.cast<String, dynamic>();
      _loaded = true;
      _nameCtrl.text = _data['name'] ?? '';
      _ageCtrl.text = (_data['age'] ?? '').toString();
      _cityCtrl.text = _data['city'] ?? '';
      _occupation = _data['occupation'] ?? 'Salaried Employee';

      double getNum(String key) {
        final v = _data[key];
        if (v is num) return v.toDouble();
        if (v is String) {
          final cleaned = v.replaceAll(RegExp(r'[^0-9.]'), '');
          return double.tryParse(cleaned) ?? 0.0;
        }
        return 0.0;
      }

      // Load RAW digits into controllers — no commas, no ₹
      // The CurrencyInputFormatter handles visual formatting as user types
      _incomeCtrl.text = getNum('monthly_income').toStringAsFixed(0);
      _expenseCtrl.text = getNum('monthly_expense').toStringAsFixed(0);
      _savingsCtrl.text = getNum('current_savings').toStringAsFixed(0);
      _goalAmountCtrl.text = getNum('goal_amount').toStringAsFixed(0);
      _goalYearsCtrl.text = (_data['goal_years'] ?? 7).toString();
      
      _riskAppetite = _data['risk_appetite'] ?? 'Moderate';
      _goalType = _data['goal_type'] ?? 'Build Wealth';
    });
  }

  String? _validationError;
  bool _showHighIncomeHint = false;
  bool _showCorruptionSuggestion = false;
  double _suggestedIncome = 0;

  double _parseRaw(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  String _formatIndian(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(2)} L';
    return '₹${v.toStringAsFixed(0)}';
  }

  void _onIncomeChanged() {
    final income = _parseRaw(_incomeCtrl.text);
    setState(() {
      if (income > 500000000) { // > ₹5 Crore — likely corrupted
        _showHighIncomeHint = false;
        _showCorruptionSuggestion = true;
        _suggestedIncome = income / 100;
        _validationError = 'This looks unusually high. Did you mean ${_formatIndian(income / 100)} instead?';
      } else if (income > 1000000) { // > ₹10 Lakh — high but valid
        _showHighIncomeHint = true;
        _showCorruptionSuggestion = false;
        _validationError = null;
      } else {
        _showHighIncomeHint = false;
        _showCorruptionSuggestion = false;
        _validationError = null;
      }
    });
  }

  void _applySuggestedIncome() {
    _incomeCtrl.text = _suggestedIncome.toStringAsFixed(0);
    setState(() {
      _showCorruptionSuggestion = false;
      _validationError = null;
      _onIncomeChanged();
    });
  }

  Future<void> _save() async {
    final income = _parseRaw(_incomeCtrl.text);
    final expense = _parseRaw(_expenseCtrl.text);
    final savings = _parseRaw(_savingsCtrl.text);
    final goalAmt = _parseRaw(_goalAmountCtrl.text);

    // Tier 3 — block save if corruption suggestion is active (user must resolve)
    if (_showCorruptionSuggestion) {
      return; // user must tap "Use Suggested" or manually fix
    }

    if (expense > income && income > 0) {
      setState(() => _validationError = 'Expenses cannot exceed income');
      return;
    }
    if (savings > 500000000) {
      setState(() => _validationError = 'Savings value seems unrealistic (max ₹50Cr)');
      return;
    }
    setState(() => _validationError = null);

    _data['name'] = _nameCtrl.text.trim();
    _data['age'] = int.tryParse(_ageCtrl.text) ?? 25;
    _data['city'] = _cityCtrl.text.trim();
    _data['occupation'] = _occupation;
    _data['monthly_income'] = income;
    _data['monthly_salary'] = income;
    _data['annual_income'] = income * 12;
    _data['monthly_expense'] = expense;
    _data['current_savings'] = savings;
    _data['goal_amount'] = goalAmt;
    _data['financial_goal_amount'] = goalAmt;
    _data['goal_years'] = int.tryParse(_goalYearsCtrl.text) ?? 7;
    _data['target_timeline'] = int.tryParse(_goalYearsCtrl.text) ?? 7;
    _data['risk_appetite'] = _riskAppetite;
    _data['goal_type'] = _goalType;
    await UserPrefsService.setString('onboarding_data', json.encode(_data));
    // Also persist as individual keys so dashboard reads updated values
    await UserDataService.persistOnboardingData(_data);
    await UserDataService.calculateAndSaveLocally(_data);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated ✓'), backgroundColor: AppColors.primaryTeal),
      );
      context.pop();
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    for (final c in [_nameCtrl, _ageCtrl, _cityCtrl, _incomeCtrl, _expenseCtrl, _savingsCtrl, _goalAmountCtrl, _goalYearsCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        title: Text(t(ref, 'edit_profile'), style: AppTextStyles.subheading),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primaryTeal,
          labelColor: AppColors.primaryTeal,
          unselectedLabelColor: AppColors.textTertiary,
          tabs: [
            Tab(text: t(ref, 'personal')),
            Tab(text: t(ref, 'financial')),
          ],
        ),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _personalTab(),
                _financialTab(),
              ],
            ),
    );
  }

  Widget _personalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          onboardingLabel('Full Name'),
          TextFormField(controller: _nameCtrl, style: const TextStyle(color: Colors.white),
            decoration: onboardingInputDecoration('Your name')),
          const SizedBox(height: 16),
          onboardingLabel('Age'),
          TextFormField(controller: _ageCtrl, keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: onboardingInputDecoration('25')),
          const SizedBox(height: 16),
          onboardingLabel('City'),
          TextFormField(controller: _cityCtrl, style: const TextStyle(color: Colors.white),
            decoration: onboardingInputDecoration('Pune')),
          const SizedBox(height: 16),
          onboardingLabel('Occupation'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonFormField<String>(
              value: _occupation, dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: const InputDecoration(border: InputBorder.none),
              items: ['Salaried Employee', 'Business Owner', 'Freelancer / Self-employed', 'Student', 'Other']
                  .map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
              onChanged: (v) => setState(() => _occupation = v ?? _occupation)),
          ),
          const SizedBox(height: 40),
        ],
        ),
      ),
    );
  }

  Widget _financialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_validationError != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.dangerRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.dangerRed.withValues(alpha: 0.3)),
              ),
              child: Text(_validationError!, style: const TextStyle(color: AppColors.dangerRed, fontSize: 13)),
            ),
          ],
          onboardingLabel('Monthly Income'),
          TextFormField(controller: _incomeCtrl, keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
            style: const TextStyle(color: Colors.white),
            decoration: onboardingInputDecoration('50000', prefix: '₹ '),
            onChanged: (_) => _onIncomeChanged()),
          // Tier 2 — amber info card for high income
          if (_showHighIncomeHint)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withValues(alpha: 0.08),
                border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.25)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: Color(0xFFFFC107), size: 14),
                SizedBox(width: 8),
                Expanded(child: Text('High income entered. Tap Save to confirm.',
                  style: TextStyle(color: Color(0xFFFFC107), fontSize: 12))),
              ]),
            ),
          // Tier 3 — corruption suggestion with auto-fix button
          if (_showCorruptionSuggestion)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerRed.withValues(alpha: 0.08),
                border: Border.all(color: AppColors.dangerRed.withValues(alpha: 0.25)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(_validationError ?? 'Value seems too high',
                  style: const TextStyle(color: AppColors.dangerRed, fontSize: 12)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _applySuggestedIncome,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryTeal,
                        side: const BorderSide(color: AppColors.primaryTeal),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text('Use ${_formatIndian(_suggestedIncome)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => setState(() {
                      _showCorruptionSuggestion = false;
                      _validationError = null;
                    }),
                    child: const Text('My income is correct',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ),
                ]),
              ]),
            ),
          const SizedBox(height: 16),
          onboardingLabel('Monthly Expenses'),
          TextFormField(controller: _expenseCtrl, keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
            style: const TextStyle(color: Colors.white),
            decoration: onboardingInputDecoration('25000', prefix: '₹ ')),
          const SizedBox(height: 16),
          onboardingLabel('Current Savings'),
          TextFormField(controller: _savingsCtrl, keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
            style: const TextStyle(color: Colors.white),
            decoration: onboardingInputDecoration('200000', prefix: '₹ ')),
          const SizedBox(height: 16),
          onboardingLabel('Goal Type'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonFormField<String>(
              value: _goalType, dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: const InputDecoration(border: InputBorder.none),
              items: ['Buy a Home', 'Education', 'Travel', 'Marriage', 'Build Wealth', 'Early Retirement', 'Buy a Vehicle', 'Emergency Fund']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) => setState(() => _goalType = v ?? _goalType)),
          ),
          const SizedBox(height: 16),
          onboardingLabel('Goal Amount'),
          TextFormField(controller: _goalAmountCtrl, keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
            style: const TextStyle(color: Colors.white),
            decoration: onboardingInputDecoration('15200000', prefix: '₹ ')),
          const SizedBox(height: 16),
          onboardingLabel('Goal Timeline (years)'),
          TextFormField(controller: _goalYearsCtrl, keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: onboardingInputDecoration('7')),
          const SizedBox(height: 16),
          onboardingLabel('Risk Appetite'),
          Row(
            children: ['Conservative', 'Moderate', 'Aggressive'].map((r) {
              final sel = _riskAppetite == r;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _riskAppetite = r),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primaryTeal.withOpacity(0.15) : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? AppColors.primaryTeal : const Color(0xFF1F2937)),
                    ),
                    child: Center(
                      child: Text(r, style: TextStyle(fontSize: 12, color: sel ? AppColors.primaryTeal : AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
        ],
        ),
      ),
    );
  }
}
