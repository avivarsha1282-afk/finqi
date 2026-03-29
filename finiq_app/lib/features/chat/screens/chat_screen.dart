import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/chat_provider.dart';
import '../widgets/artha_message_bubble.dart';
import '../widgets/user_message_bubble.dart';
import '../widgets/embedded_table_card.dart';
import '../widgets/action_result_card.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

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
    final state = ref.read(chatProvider);
    if (state.any((m) => m.isLoading)) return;
    
    _textCtrl.clear();
    ref.read(chatProvider.notifier).sendMessage(text.trim());
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);

    // Auto scroll when new messages arrive
    ref.listen(chatProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Artha', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: state.any((m) => m.isLoading) ? AppColors.warningAmber : AppColors.successGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  state.any((m) => m.isLoading) ? 'Thinking...' : 'Online',
                  style: const TextStyle(fontSize: 10, color: AppColors.textTertiary, letterSpacing: 0.5),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Expanded chat list
          Expanded(
            child: state.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: state.length,
                  itemBuilder: (context, i) {
                    final msg = state[i];
                    final isLatest = i == state.length - 1;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (msg.isArtha)
                          ArthaMessageBubble(text: msg.content, isLatest: isLatest)
                              .animate().slideX(begin: -0.1, end: 0, duration: 200.ms).fadeIn()
                        else
                          UserMessageBubble(text: msg.content)
                              .animate().slideX(begin: 0.1, end: 0, duration: 200.ms).fadeIn(),

                        if (msg.embeddedData != null && msg.embeddedData!.type == 'TABLE')
                          EmbeddedTableCard(
                            title: msg.embeddedData!.title ?? 'Data Table',
                            data: msg.embeddedData!.tableRows == null
                                ? []
                                : msg.embeddedData!.tableRows!
                                    .map((row) => row.values.toList())
                                    .toList(),
                          ).animate().slideY(begin: 0.1, end: 0).fadeIn(),

                        if (msg.actionCard != null)
                          ActionResultCard(action: msg.actionCard!)
                              .animate().slideY(begin: 0.1, end: 0).fadeIn(),
                      ],
                    );
                  },
                ),
          ),

          // Input field
          _buildInputBar(state.any((m) => m.isLoading)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_rounded, color: AppColors.primaryTeal, size: 64),
          ),
          const SizedBox(height: 24),
          const Text('How can I help you today?', style: AppTextStyles.subheading2),
          const SizedBox(height: 8),
          const Text('Ask about your portfolio, FIRE status,\nor tax optimization strategies.', 
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 32),
          // Suggestion chips
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestionChip('Review my FIRE plan'),
              _buildSuggestionChip('Analyze health score'),
              _buildSuggestionChip('How to save more tax?'),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _textCtrl.text = text;
        _send(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardElevated,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
      ),
    );
  }

  Widget _buildInputBar(bool isLoading) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      decoration: const BoxDecoration(
        color: AppColors.backgroundColor,
        border: Border(top: BorderSide(color: AppColors.borderColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(bottom: 2),
            decoration: const BoxDecoration(color: AppColors.cardElevated, shape: BoxShape.circle),
            child: const Icon(Icons.add_rounded, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _textCtrl,
              enabled: !isLoading,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Message Artha...',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.cardElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _send(_textCtrl.text),
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(bottom: 2),
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
}
