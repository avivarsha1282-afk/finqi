import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../services/user_data_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../language/providers/language_provider.dart';
import '../../../l10n/t.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic> _profile = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await UserDataService.getUserProfile();
    if (mounted) setState(() { _profile = profile; _loaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(t(ref, 'profile'), style: AppTextStyles.subheading),
        actions: [
          TextButton(
            onPressed: () => context.push('/profile/edit'),
            child: const Text('Edit', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── User Header ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [AppColors.primaryTeal.withOpacity(0.08), AppColors.cardColor],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryTeal.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryTeal,
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    child: user?.photoURL == null
                        ? Text((user?.displayName ?? _profile['name'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.black))
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(user?.displayName ?? _profile['name'] ?? 'User',
                      style: AppTextStyles.heading2),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '',
                      style: AppTextStyles.bodySmall),
                  if (_loaded) ...[
                    const SizedBox(height: 8),
                    Text('${_profile['city'] ?? ''} · ${_profile['occupation'] ?? ''}',
                        style: AppTextStyles.caption),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 20),

            // ── Financial Summary ────────────────────────────
            if (_loaded) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('FINANCIAL SUMMARY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1.5)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  children: [
                    _summaryRow('Annual Income', CurrencyFormatter.compact((_profile['annual_income'] ?? 0).toDouble()), Icons.account_balance_wallet_rounded),
                    _summaryRow('Monthly Expenses', CurrencyFormatter.compact((_profile['monthly_expense'] ?? 0).toDouble()), Icons.shopping_cart_rounded),
                    _summaryRow('Current Savings', CurrencyFormatter.compact((_profile['current_savings'] ?? 0).toDouble()), Icons.savings_rounded),
                    _summaryRow('Risk Appetite', _profile['risk_appetite'] ?? 'Moderate', Icons.speed_rounded),
                    _summaryRow('Goal', _profile['goal_type'] ?? 'Build Wealth', Icons.flag_rounded),
                  ],
                ),
              ).animate(delay: 100.ms).fadeIn(),
            ],

            const SizedBox(height: 20),

            // ── Preferences ──────────────────────────────────
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('PREFERENCES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                children: [
                  _menuItem(
                    Icons.language_rounded,
                    lang == 'hi' ? 'भाषा' : 'Language',
                    trailing: lang == 'hi' ? 'हिंदी' : 'English',
                    onTap: () => _showLanguageSheet(context, ref),
                  ),
                  const Divider(color: AppColors.borderColor, height: 1),
                  _menuItem(
                    Icons.info_outline_rounded,
                    lang == 'hi' ? 'FinIQ के बारे में' : 'About FinIQ',
                    onTap: () => _showAbout(context),
                  ),
                ],
              ),
            ).animate(delay: 200.ms).fadeIn(),

            const SizedBox(height: 20),

            // ── Account ──────────────────────────────────────
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('ACCOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: _menuItem(
                Icons.logout_rounded,
                lang == 'hi' ? 'लॉग आउट' : 'Sign Out',
                iconColor: AppColors.dangerRed,
                textColor: AppColors.dangerRed,
                onTap: () => _confirmLogout(context, ref),
              ),
            ).animate(delay: 300.ms).fadeIn(),

            const SizedBox(height: 24),

            // ── Footer ───────────────────────────────────────
            const Text('FinIQ v1.0.0', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            const SizedBox(height: 4),
            const Text('RBI · SEBI · IRDAI aligned',
                style: TextStyle(fontSize: 10, color: Color(0xFF333333))),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryTeal, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14))),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, {String? trailing, Color? iconColor, Color? textColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(color: textColor ?? Colors.white, fontSize: 15))),
            if (trailing != null)
              Text(trailing, style: const TextStyle(color: AppColors.primaryTeal, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final currentLang = ref.read(languageProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Language', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _langOption('English', 'en', currentLang == 'en', () {
              ref.read(languageProvider.notifier).setLanguage('en');
              Navigator.pop(context);
            }),
            const SizedBox(height: 12),
            _langOption('हिंदी', 'hi', currentLang == 'hi', () {
              ref.read(languageProvider.notifier).setLanguage('hi');
              Navigator.pop(context);
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _langOption(String label, String code, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTeal.withOpacity(0.1) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primaryTeal : AppColors.borderColor),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: selected ? AppColors.primaryTeal : Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primaryTeal, size: 20),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        title: RichText(text: const TextSpan(children: [
          TextSpan(text: 'Fin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
          TextSpan(text: 'IQ', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.w700, fontSize: 20)),
        ])),
        content: const Text(
          'FinIQ is your AI-powered financial mentor, designed for the Indian financial landscape.\n\n'
          'v1.0.0 · Built with 💚\n\n'
          'This app provides financial education only. '
          'It is not registered with SEBI, RBI, or IRDAI as an investment advisor.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.6),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        title: const Text('Sign Out?', style: TextStyle(color: Colors.white)),
        content: const Text('You can sign back in anytime with Google.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed),
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog first
              await ref.read(authControllerProvider.notifier).signOut();
              if (mounted) context.go('/login');
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
