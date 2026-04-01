import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/api_service.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/chat_message_model.dart';
import '../../../services/user_data_service.dart';
import '../../language/providers/language_provider.dart';

class ArthaChatScreen extends ConsumerStatefulWidget {
  const ArthaChatScreen({super.key});
  @override ConsumerState<ArthaChatScreen> createState() => _ArthaChatScreenState();
}

class _ArthaChatScreenState extends ConsumerState<ArthaChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  static const _suggestionsEn = [
    'What should I invest in first?',
    'How to save ₹1 lakh tax this year?',
    'Explain mutual funds for beginners',
    'Should I buy term insurance?',
    'NPS vs PPF — which is better?',
    'How much emergency fund do I need?',
  ];

  static const _suggestionsHi = [
    'पहले क्या निवेश करूं?',
    'इस साल ₹1 लाख टैक्स कैसे बचाएं?',
    'म्यूचुअल फंड क्या है?',
    'क्या टर्म इंश्योरेंस लेना चाहिए?',
    'NPS vs PPF — कौन बेहतर?',
    'इमरजेंसी फंड कितना होना चाहिए?',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    
    // Welcome message if no history
    setState(() {
      _messages.add(ChatMessage.artha(
        'Hi! I\'m Artha, your AI financial mentor 🧠\n\n'
        'I can help you with investments, tax planning, insurance, and FIRE goals. '
        'Ask me anything about your finances!\n\n'
        '⚠️ I provide financial education, not SEBI-registered investment advice.',
      ));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();

    final userMsg = ChatMessage.user(text);
    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _scrollToBottom();
    
    // Chat is persisted server-side in MongoDB via /chat/message

    try {
      final userProfile = await UserDataService.getUserProfile();
      final lang = ref.read(languageProvider);

      final replyMsg = await ApiService.instance.sendMessage(
        message: text,
        history: _messages, 
        language: lang,
        userContext: userProfile,
      );

      setState(() {
        _isTyping = false;
        _messages.add(replyMsg);
      });
      
      // Reply persisted server-side in MongoDB
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage.artha(
          'Whoops! Something went wrong:\n$e\n\nPlease try again.',
        ));
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final suggestions = lang == 'hi' ? _suggestionsHi : _suggestionsEn;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryTeal,
              child: const Text('A', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Artha', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                Text(lang == 'hi' ? 'AI वित्तीय सलाहकार' : 'AI Financial Mentor',
                    style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
              ],
            ),
          ],
        ),
        actions: [
          // Language toggle
          GestureDetector(
            onTap: () {
              ref.read(languageProvider.notifier).setLanguage(lang == 'en' ? 'hi' : 'en');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                lang == 'en' ? 'हिंदी' : 'ENG',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryTeal),
              ),
            ),
          ),
          // Clear chat
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(ChatMessage.artha(
                  lang == 'hi'
                      ? 'नमस्ते! मैं अर्थ हूं, आपका AI वित्तीय सलाहकार 🧠\n\nमुझसे अपने वित्त के बारे में कुछ भी पूछें!'
                      : 'Hi! I\'m Artha, your AI financial mentor 🧠\n\nAsk me anything about your finances!',
                ));
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages ────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0) + (_messages.length <= 1 ? 1 : 0),
              itemBuilder: (_, idx) {
                // Show suggestions after welcome message
                if (_messages.length <= 1 && idx == _messages.length) {
                  return _buildSuggestions(suggestions);
                }
                if (idx >= _messages.length) {
                  // Typing indicator
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[idx]);
              },
            ),
          ),

          // ── Input ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: lang == 'hi' ? 'अर्थ से पूछें...' : 'Ask Artha anything...',
                      hintStyle: const TextStyle(color: AppColors.textTertiary),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isTyping ? null : () => _sendMessage(_controller.text),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isTyping ? const Color(0xFF1F2937) : AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: _isTyping ? AppColors.textTertiary : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryTeal.withOpacity(0.15) : AppColors.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser ? AppColors.primaryTeal.withOpacity(0.3) : AppColors.borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.primaryTeal,
                      child: const Text('A', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 8)),
                    ),
                    const SizedBox(width: 6),
                    const Text('Artha', style: TextStyle(fontSize: 11, color: AppColors.primaryTeal, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            Text(msg.content, style: AppTextStyles.chatText),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildSuggestions(List<String> suggestions) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((s) {
          return GestureDetector(
            onTap: () => _sendMessage(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1F2937)),
              ),
              child: Text(s, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ),
          );
        }).toList(),
      ),
    ).animate(delay: 200.ms).fadeIn();
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomRight: Radius.circular(16), bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 10, backgroundColor: AppColors.primaryTeal,
              child: const Text('A', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 8))),
            const SizedBox(width: 10),
            ...[0, 1, 2].map((i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: const Text('●', style: TextStyle(color: AppColors.primaryTeal, fontSize: 10)),
            ).animate(onPlay: (c) => c.repeat())
              .fadeIn(delay: Duration(milliseconds: i * 200), duration: 400.ms)
              .then()
              .fadeOut(duration: 400.ms)),
          ],
        ),
      ),
    );
  }
}
