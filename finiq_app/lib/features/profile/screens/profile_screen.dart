import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/api_constants.dart';
import '../../../services/api_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../language/providers/language_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.value;
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: Text(AppStrings.get('profile', lang), style: AppTextStyles.subheading),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // ── Avatar ───────────────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: () => _showPersonalInfoSheet(context, ref, lang),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cardElevated,
                        border: Border.all(color: AppColors.primaryTeal, width: 2),
                        image: user?.photoURL != null
                            ? DecorationImage(image: NetworkImage(user!.photoURL!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: user?.photoURL == null
                          ? const Icon(Icons.person, color: AppColors.textTertiary, size: 48)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0A0A0A), width: 2),
                      ),
                      child: const Icon(Icons.edit_rounded, color: Colors.black, size: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(user?.displayName ?? 'User', style: AppTextStyles.heading2),
            const SizedBox(height: 4),
            Text(user?.email ?? '', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 40),

            // ── Account Controls ──────────────────────────────────────────
            _buildSectionHeader('ACCOUNT CONTROLS'),
            const SizedBox(height: 16),
            _buildActionItem(
              icon: Icons.person_outline_rounded,
              title: AppStrings.get('personal_information', lang),
              subtitle: 'View and update your profile details',
              onTap: () => _showPersonalInfoSheet(context, ref, lang),
            ),
            _buildActionItem(
              icon: Icons.trending_up_rounded,
              title: AppStrings.get('investment_preferences', lang),
              subtitle: 'Set your risk appetite',
              onTap: () => _showInvestmentPrefsSheet(context, ref, lang),
            ),
            _buildActionItem(
              icon: Icons.language_rounded,
              title: AppStrings.get('language', lang),
              subtitle: lang == 'hi' ? 'Hindi (हिंदी)' : lang == 'ta' ? 'Tamil (தமிழ்)' : 'English',
              onTap: () => _showLanguageSheet(context, ref),
            ),
            _buildActionItem(
              icon: Icons.fingerprint_rounded,
              title: AppStrings.get('security', lang),
              subtitle: 'Biometric login (coming soon)',
              onTap: () => _showSecuritySheet(context, lang),
            ),

            const SizedBox(height: 40),

            // ── Logout ────────────────────────────────────────────────────
            GestureDetector(
              onTap: () => ref.read(authControllerProvider.notifier).signOut(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.dangerRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.dangerRed.withOpacity(0.5)),
                ),
                child: Center(
                  child: Text(
                    AppStrings.get('logout', lang),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dangerRed),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text(AppStrings.get('finiq_engine', lang),
                style: const TextStyle(fontSize: 10, color: Color(0xFF1F2937), letterSpacing: 2)),
            const SizedBox(height: 8),
            const Text('FinIQ v1.0 · Hackathon Build',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Personal Information Sheet ─────────────────────────────────────────────
  void _showPersonalInfoSheet(BuildContext context, WidgetRef ref, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PersonalInfoSheet(lang: lang),
    );
  }

  // ── Investment Preferences Sheet ──────────────────────────────────────────
  void _showInvestmentPrefsSheet(BuildContext context, WidgetRef ref, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _InvestmentPrefsSheet(),
    );
  }

  // ── Language Sheet ────────────────────────────────────────────────────────
  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _LanguageSheet(ref: ref),
    );
  }

  // ── Security Sheet ────────────────────────────────────────────────────────
  void _showSecuritySheet(BuildContext context, String lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.fingerprint_rounded, color: AppColors.primaryTeal, size: 52),
            const SizedBox(height: 16),
            const Text('🔒 Biometric Login', style: AppTextStyles.subheading),
            const SizedBox(height: 8),
            const Text(
              'Face ID and fingerprint login is coming in the next update.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Got it'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: AppTextStyles.label.copyWith(letterSpacing: 1.5)),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryTeal, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Personal Info Bottom Sheet ─────────────────────────────────────────────────
class _PersonalInfoSheet extends StatefulWidget {
  final String lang;
  const _PersonalInfoSheet({required this.lang});

  @override
  State<_PersonalInfoSheet> createState() => _PersonalInfoSheetState();
}

class _PersonalInfoSheetState extends State<_PersonalInfoSheet> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _incomeCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _cityCtrl.dispose();
    _incomeCtrl.dispose(); _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiService.instance.put(ApiConstants.updateProfile, {
        'name': _nameCtrl.text.trim(),
        'profile': {
          'city': _cityCtrl.text.trim(),
          'annual_income': double.tryParse(_incomeCtrl.text) ?? 0,
          'financial_goal': _goalCtrl.text.trim(),
        }
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'),
              backgroundColor: AppColors.primaryTeal),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save — check connection'),
              backgroundColor: AppColors.dangerRed),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.get('personal_information', widget.lang),
                style: AppTextStyles.subheading),
            const SizedBox(height: 24),
            _field('Full Name', _nameCtrl, TextInputType.text),
            _field('City', _cityCtrl, TextInputType.text),
            _field('Annual Income (₹)', _incomeCtrl, TextInputType.number),
            _field('Primary Goal (e.g. Home, Retirement)', _goalCtrl, TextInputType.text),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(AppStrings.get('save_changes', widget.lang)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, TextInputType type) {
    final isNumber = type == TextInputType.number;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        inputFormatters: [
          if (isNumber) FilteringTextInputFormatter.digitsOnly,
          if (isNumber) LengthLimitingTextInputFormatter(10), // max ₹9,99,99,99,999
          if (!isNumber) LengthLimitingTextInputFormatter(50),
        ],
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.caption,
          filled: true,
          fillColor: AppColors.cardElevated,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor)),
        ),
        style: const TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}

// ── Investment Preferences Bottom Sheet ───────────────────────────────────────
class _InvestmentPrefsSheet extends StatefulWidget {
  const _InvestmentPrefsSheet();

  @override
  State<_InvestmentPrefsSheet> createState() => _InvestmentPrefsSheetState();
}

class _InvestmentPrefsSheetState extends State<_InvestmentPrefsSheet> {
  String _risk = 'moderate';
  double _horizon = 10;
  final Set<String> _instruments = {'Mutual Funds', 'SIP', 'PPF'};
  bool _saving = false;

  static const _allInstruments = [
    'Mutual Funds', 'SIP', 'Direct Stocks', 'Gold ETF', 'PPF', 'NPS', 'FD'
  ];
  static const _riskReturns = {
    'conservative': 8.0,
    'moderate': 12.0,
    'aggressive': 15.0,
  };

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiService.instance.put(ApiConstants.updateProfile, {
        'profile': {
          'risk_appetite': _risk,
          'investment_horizon': _horizon.toInt(),
          'preferred_instruments': _instruments.toList(),
          'expected_return': _riskReturns[_risk],
        }
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved. Your FIRE plan has been updated.'),
            backgroundColor: AppColors.primaryTeal,
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Investment Preferences', style: AppTextStyles.subheading),
            const SizedBox(height: 24),

            const Text('RISK APPETITE', style: AppTextStyles.label),
            const SizedBox(height: 12),
            Row(children: ['conservative', 'moderate', 'aggressive'].map((r) {
              final selected = _risk == r;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _risk = r),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryTeal.withOpacity(0.15) : AppColors.cardElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selected ? AppColors.primaryTeal : AppColors.borderColor),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          r == 'conservative' ? Icons.shield_rounded
                              : r == 'moderate' ? Icons.balance_rounded
                              : Icons.rocket_launch_rounded,
                          color: selected ? AppColors.primaryTeal : AppColors.textTertiary,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          r[0].toUpperCase() + r.substring(1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected ? AppColors.primaryTeal : AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '${_riskReturns[r]?.toInt()}% pa',
                          style: TextStyle(fontSize: 10, color: selected ? AppColors.primaryTeal : AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList()),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('INVESTMENT HORIZON', style: AppTextStyles.label),
                Text('${_horizon.toInt()} years',
                    style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w700)),
              ],
            ),
            Slider(
              value: _horizon,
              min: 1,
              max: 30,
              divisions: 29,
              activeColor: AppColors.primaryTeal,
              inactiveColor: AppColors.borderColor,
              onChanged: (v) => setState(() => _horizon = v),
            ),

            const SizedBox(height: 16),
            const Text('PREFERRED INSTRUMENTS', style: AppTextStyles.label),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allInstruments.map((ins) {
                final selected = _instruments.contains(ins);
                return GestureDetector(
                  onTap: () => setState(() {
                    selected ? _instruments.remove(ins) : _instruments.add(ins);
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryTeal.withOpacity(0.15) : AppColors.cardElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppColors.primaryTeal : AppColors.borderColor),
                    ),
                    child: Text(
                      (selected ? '✓ ' : '') + ins,
                      style: TextStyle(
                        fontSize: 13,
                        color: selected ? AppColors.primaryTeal : AppColors.textSecondary,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Preferences'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Language Sheet ─────────────────────────────────────────────────────────────
class _LanguageSheet extends StatelessWidget {
  final WidgetRef ref;
  const _LanguageSheet({required this.ref});

  @override
  Widget build(BuildContext context) {
    final current = ref.read(languageProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select Language', style: AppTextStyles.subheading),
          const SizedBox(height: 24),
          ...{
            'en': 'English',
            'hi': 'हिंदी (Hindi)',
            'ta': 'தமிழ் (Tamil)',
          }.entries.map((e) {
            final selected = current == e.key;
            return GestureDetector(
              onTap: () {
                ref.read(languageProvider.notifier).setLanguage(e.key);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Language changed to ${e.value}')),
                );
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryTeal.withOpacity(0.15) : AppColors.cardElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: selected ? AppColors.primaryTeal : AppColors.borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(e.value,
                          style: TextStyle(
                            color: selected ? AppColors.primaryTeal : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                    if (selected)
                      const Icon(Icons.check_rounded, color: AppColors.primaryTeal, size: 18),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
