import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_strings.dart';
import '../../language/providers/language_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/chat_bubble_widget.dart';
import '../widgets/quick_reply_chips.dart';

class OnboardingChatScreen extends ConsumerStatefulWidget {
  const OnboardingChatScreen({super.key});

  @override
  ConsumerState<OnboardingChatScreen> createState() => _OnboardingChatScreenState();
}

class _OnboardingChatScreenState extends ConsumerState<OnboardingChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _selectedChip;

  // Quick replies per question
  static const Map<int, List<String>> _quickReplies = {
    1: ['Have salary slip', 'Freelancer income', 'Business income'],
    5: ['Yes, Home Loan', 'Yes, Car Loan', 'Personal Loan', 'No EMIs'],
    6: ['Yes, I have health insurance', 'No health insurance'],
    7: ['Yes, I have term life', 'No life insurance'],
    10: ['Contribute to NPS', 'Don\'t contribute to NPS'],
    11: ['Home purchase', 'Retire early (FIRE)', 'Children\'s education', 'Wealth creation'],
  };

  static const Map<int, List<String>> _quickRepliesHi = {
    1: ['सैलरी स्लिप है', 'फ्रीलांसर हूं', 'बिजनेस है'],
    5: ['हां, होम लोन', 'हां, कार लोन', 'पर्सनल लोन', 'कोई EMI नहीं'],
    6: ['हां, हेल्थ इंश्योरेंस है', 'नहीं है'],
    7: ['हां, टर्म लाइफ है', 'कोई बीमा नहीं'],
    10: ['NPS में योगदान देता हूं', 'NPS नहीं है'],
    11: ['घर खरीदना', 'जल्दी रिटायर होना', 'बच्चों की पढ़ाई', 'संपत्ति बनाना'],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingProvider.notifier).startOnboarding();
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    final state = ref.read(onboardingProvider);
    if (state.isLoading) return;
    _textCtrl.clear();
    setState(() => _selectedChip = null);
    ref.read(onboardingProvider.notifier).sendAnswer(text.trim());
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final lang = ref.watch(languageProvider);
    final isHindi = lang == 'hi';

    // Navigate when complete
    ref.listen(onboardingProvider, (prev, next) {
      if (next.isComplete && !(prev?.isComplete ?? false)) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) context.go('/dashboard');
        });
      }
      _scrollToBottom();
    });

    final q = state.currentQuestion;
    final chips = isHindi
        ? (_quickRepliesHi[q] ?? [])
        : (_quickReplies[q] ?? []);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final confirm = await showDialog<bool>(context: context, builder: (_) => _ExitDialog());
          if (confirm == true && context.mounted) context.go('/login');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: _buildAppBar(isHindi, state.currentQuestion),
        body: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: state.currentQuestion / 12,
              backgroundColor: AppColors.dividerColor,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryTeal),
              minHeight: 2,
            ),
            // Question counter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (state.isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        'ARTHA THINKING...',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.primaryTeal, letterSpacing: 1),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    isHindi
                        ? 'प्रश्न $q/12'
                        : 'QUESTION $q OF 12',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryTeal, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: state.messages.length,
                itemBuilder: (_, i) {
                  return ChatBubbleWidget(message: state.messages[i])
                      .animate()
                      .slideX(
                        begin: state.messages[i].isArtha ? -0.2 : 0.2,
                        end: 0,
                        duration: 200.ms,
                      )
                      .fadeIn(duration: 200.ms);
                },
              ),
            ),

            // Quick reply chips
            if (chips.isNotEmpty && !state.isComplete) ...[
              const SizedBox(height: 8),
              QuickReplyChips(
                chips: chips,
                selectedChip: _selectedChip,
                onSelected: (chip) {
                  setState(() => _selectedChip = chip);
                  _textCtrl.text = chip;
                },
              ),
              const SizedBox(height: 8),
            ],

            // Input bar
            if (!state.isComplete)
              _buildInputBar(isHindi, state.isLoading),

            if (state.isComplete)
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: AppColors.primaryTeal, strokeWidth: 2),
                    const SizedBox(height: 12),
                    Text(
                      isHindi ? 'अर्था आपकी योजना बना रही है...' : 'Artha is building your plan...',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isHindi, bool isLoading) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: const BoxDecoration(
        color: AppColors.backgroundColor,
        border: Border(top: BorderSide(color: AppColors.borderColor)),
      ),
      child: Row(
        children: [
          // Mic
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cardElevated,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic_rounded, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 8),
          // Text field
          Expanded(
            child: TextField(
              controller: _textCtrl,
              enabled: !isLoading,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: isHindi ? 'अपनी प्रतिक्रिया टाइप करें...' : 'Type your response...',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.cardElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                suffixIcon: const Icon(Icons.attach_file_rounded, color: AppColors.textTertiary, size: 18),
              ),
              onSubmitted: _send,
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap: () => _send(_textCtrl.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isLoading ? AppColors.textTertiary : AppColors.primaryTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(bool isHindi, int question) {
    return AppBar(
      backgroundColor: AppColors.backgroundColor,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryTeal),
        child: const Center(child: Text('A', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black))),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Artha', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(
            isHindi ? 'आपका वित्तीय सलाहकार' : 'YOUR FINANCIAL ARCHITECT',
            style: const TextStyle(fontSize: 10, color: AppColors.textTertiary, letterSpacing: 0.5),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.language_rounded, color: AppColors.textSecondary),
          onPressed: () {
            final lang = ref.read(languageProvider);
            final next = lang == 'en' ? 'hi' : 'en';
            ref.read(languageProvider.notifier).setLanguage(next);
          },
        ),
      ],
    );
  }
}

class _ExitDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Quit onboarding?', style: TextStyle(color: AppColors.textPrimary)),
      content: const Text('Your progress will be lost. Are you sure?', style: TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Stay', style: TextStyle(color: AppColors.primaryTeal)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Exit', style: TextStyle(color: AppColors.dangerRed)),
        ),
      ],
    );
  }
}
