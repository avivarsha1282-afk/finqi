import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/user_prefs_service.dart';
import '../../../services/user_data_service.dart';
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
    final raw = (await UserPrefsService.getString('onboarding_data')) ?? '{}';
    final data = json.decode(raw) as Map<String, dynamic>;
    setState(() {
      _data = data;
      _loaded = true;
      _nameCtrl.text = data['name'] ?? '';
      _ageCtrl.text = (data['age'] ?? '').toString();
      _cityCtrl.text = data['city'] ?? '';
      _occupation = data['occupation'] ?? 'Salaried Employee';
      _incomeCtrl.text = (data['monthly_income'] ?? '').toString();
      _expenseCtrl.text = (data['monthly_expense'] ?? '').toString();
      _savingsCtrl.text = (data['current_savings'] ?? '').toString();
      _goalAmountCtrl.text = (data['goal_amount'] ?? '').toString();
      _goalYearsCtrl.text = (data['goal_years'] ?? '').toString();
      _riskAppetite = data['risk_appetite'] ?? 'Moderate';
      _goalType = data['goal_type'] ?? 'Build Wealth';
    });
  }

  Future<void> _save() async {
    _data['name'] = _nameCtrl.text.trim();
    _data['age'] = int.tryParse(_ageCtrl.text) ?? 25;
    _data['city'] = _cityCtrl.text.trim();
    _data['occupation'] = _occupation;
    _data['monthly_income'] = double.tryParse(_incomeCtrl.text) ?? 0;
    _data['annual_income'] = (double.tryParse(_incomeCtrl.text) ?? 0) * 12;
    _data['monthly_expense'] = double.tryParse(_expenseCtrl.text) ?? 0;
    _data['current_savings'] = double.tryParse(_savingsCtrl.text) ?? 0;
    _data['goal_amount'] = double.tryParse(_goalAmountCtrl.text) ?? 0;
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
    );
  }

  Widget _financialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
    );
  }
}
