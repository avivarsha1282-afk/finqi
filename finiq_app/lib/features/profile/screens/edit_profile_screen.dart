import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/user_prefs_service.dart';
import '../../../services/user_data_service.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../features/onboarding/widgets/onboarding_shared.dart';
import '../../language/providers/language_provider.dart';

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

      double getNum(String key) => (_data[key] is num) ? (_data[key] as num).toDouble() : 0.0;

      // Only format values that are strictly numbers representing money
      _incomeCtrl.text = IndianNumberFormat.formatFull(getNum('monthly_income'));
      _expenseCtrl.text = IndianNumberFormat.formatFull(getNum('monthly_expense'));
      _savingsCtrl.text = IndianNumberFormat.formatFull(getNum('current_savings'));
      _goalAmountCtrl.text = IndianNumberFormat.formatFull(getNum('goal_amount'));
      _goalYearsCtrl.text = (_data['goal_years'] ?? 7).toString();
      
      _riskAppetite = _data['risk_appetite'] ?? 'Moderate';
      _goalType = _data['goal_type'] ?? 'Build Wealth';
    });
  }

  Future<void> _save() async {
    _data['name'] = _nameCtrl.text.trim();
    _data['age'] = int.tryParse(_ageCtrl.text) ?? 25;
    _data['city'] = _cityCtrl.text.trim();
    _data['occupation'] = _occupation;
    _data['monthly_income'] = IndianNumberFormat.parse(_incomeCtrl.text) ?? 0;
    _data['annual_income'] = (IndianNumberFormat.parse(_incomeCtrl.text) ?? 0) * 12;
    _data['monthly_expense'] = IndianNumberFormat.parse(_expenseCtrl.text) ?? 0;
    _data['current_savings'] = IndianNumberFormat.parse(_savingsCtrl.text) ?? 0;
    _data['goal_amount'] = IndianNumberFormat.parse(_goalAmountCtrl.text) ?? 0;
    _data['goal_years'] = int.tryParse(_goalYearsCtrl.text) ?? 7;
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
        title: Text(lang == 'hi' ? 'प्रोफ़ाइल संपादित करें' : 'Edit Profile', style: AppTextStyles.subheading),
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
            Tab(text: lang == 'hi' ? 'व्यक्तिगत' : 'Personal'),
            Tab(text: lang == 'hi' ? 'वित्तीय' : 'Financial'),
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
          onboardingLabel('Monthly Income'),
          TextFormField(controller: _incomeCtrl, keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: onboardingInputDecoration('50000', prefix: '₹ ')),
          const SizedBox(height: 16),
          onboardingLabel('Monthly Expenses'),
          TextFormField(controller: _expenseCtrl, keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: onboardingInputDecoration('25000', prefix: '₹ ')),
          const SizedBox(height: 16),
          onboardingLabel('Current Savings'),
          TextFormField(controller: _savingsCtrl, keyboardType: TextInputType.number,
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
