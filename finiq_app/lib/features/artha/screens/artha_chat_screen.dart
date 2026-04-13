import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../services/api_service.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/chat_message_model.dart';
import '../../../services/user_data_service.dart';
import '../../language/providers/language_provider.dart';
import '../../../l10n/t.dart';

class ArthaChatScreen extends ConsumerStatefulWidget {
  const ArthaChatScreen({super.key});
  @override ConsumerState<ArthaChatScreen> createState() => _ArthaChatScreenState();
}

class _ArthaChatScreenState extends ConsumerState<ArthaChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  List<Map<String, dynamic>> _conversations = [];
  String? _conversationId;
  bool _isTyping = false;
  bool _isLoading = true;

  static const _suggestionsEn = [
    'How do I save ₹50K this month? 💰',
    'Best tax saving options for me 📋',
    'Review my FIRE plan 🔥',
    'Am I spending too much? 📊',
    'How to build emergency fund?',
    'Which stocks should I look at? 📈',
  ];

  static const _suggestionsHi = [
    'इस महीने ₹50K कैसे बचाएं? 💰',
    'मेरे लिए सबसे अच्छा टैक्स बचत विकल्प 📋',
    'मेरा FIRE प्लान कैसा है? 🔥',
    'क्या मैं ज़्यादा खर्च कर रहा हूं? 📊',
    'इमर्जेंसी फंड कैसे बनाएं?',
    'कौनसे शेयर अच्छे हैं? 📈',
  ];

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    setState(() => _isLoading = true);
    try {
      await _fetchConversations();
      if (_conversations.isEmpty) {
        await _createNewChat(refreshList: false);
      } else {
        await _loadChat(_conversations.first['id'] as String);
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _fetchConversations() async {
    try {
      final convs = await ApiService.instance.getConversations();
      setState(() => _conversations = convs);
    } catch (_) {}
  }

  Future<void> _createNewChat({bool refreshList = true}) async {
    setState(() => _isLoading = true);
    try {
      final conv = await ApiService.instance.createConversation();
      setState(() {
        _conversationId = conv['conversationId'] as String;
        _messages = [];
      });
      _addWelcomeMessage();
      if (refreshList) {
        await _fetchConversations();
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context); // Close drawer if open
        }
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _loadChat(String id) async {
    setState(() => _isLoading = true);
    try {
      final msgs = await ApiService.instance.getMessages(id);
      setState(() {
        _conversationId = id;
        _messages = msgs;
      });
      if (_messages.isEmpty) {
        _addWelcomeMessage();
      }
      _scrollToBottom();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _deleteChat(String id) async {
    try {
      await ApiService.instance.deleteConversation(id);
      await _fetchConversations();
      if (_conversations.isEmpty) {
        await _createNewChat(refreshList: false);
      } else if (_conversationId == id) {
        await _loadChat(_conversations.first['id'] as String);
      }
    } catch (_) {}
  }

  void _addWelcomeMessage() {
    final lang = ref.read(languageProvider);
    _messages.add(ChatMessage.artha(
      lang == 'hi'
          ? 'नमस्ते! मैं अर्थ हूं, आपका AI वित्तीय सलाहकार 🧠\n\nमैं निवेश, टैक्स प्लानिंग, बीमा और FIRE लक्ष्यों में आपकी मदद कर सकता हूं।\n\n⚠️ मैं वित्तीय शिक्षा प्रदान करता हूं, सेबी पंजीकृत निवेश सलाह नहीं।'
          : 'Hi! I\'m Artha, your AI financial mentor 🧠\n\nI can help you with investments, tax planning, insurance, and FIRE goals. Ask me anything!\n\n⚠️ I provide financial education, not SEBI-registered investment advice.',
    ));
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
    if (text.trim().isEmpty || _conversationId == null) return;
    _controller.clear();

    final userMsg = ChatMessage.user(text);
    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final userProfile = await UserDataService.getUserProfile();
      final lang = ref.read(languageProvider);

      final replyMsg = await ApiService.instance.sendArthaMessage(
        conversationId: _conversationId!,
        message: text,
        language: lang,
        userContext: userProfile,
      );

      setState(() {
        _isTyping = false;
        _messages.add(replyMsg);
      });

      // If it’s the first real message, refresh the sidebar so auto-title appears
      if (_messages.length <= 3) {
        _fetchConversations();
      }
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage.artha('Whoops! Something went wrong:\n$e\n\nPlease try again.'));
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
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryTeal,
              child: Text('A', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Artha', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                Text(t(ref, 'ai_financial_mentor'),
                    style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_rounded, size: 20),
            tooltip: 'New Chat',
            onPressed: () => _createNewChat(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : Column(
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
                          maxLength: 2000,
                          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                          decoration: InputDecoration(
                            hintText: t(ref, 'ask_artha'),
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

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.backgroundColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            color: const Color(0xFF1A1A1A),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chat History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _createNewChat(),
                  icon: const Icon(Icons.add, size: 18, color: Colors.black),
                  label: const Text('New Chat', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _conversations.isEmpty
                ? const Center(child: Text('No previous chats', style: TextStyle(color: AppColors.textTertiary)))
                : ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, idx) {
                      final c = _conversations[idx];
                      final id = c['id'] as String;
                      final title = c['title'] as String? ?? 'New Chat';
                      final isSelected = _conversationId == id;
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: AppColors.primaryTeal.withValues(alpha: 0.1),
                        leading: Icon(Icons.chat_bubble_outline, size: 18, color: isSelected ? AppColors.primaryTeal : Colors.white38),
                        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, color: isSelected ? AppColors.primaryTeal : Colors.white)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white38),
                          onPressed: () => _deleteChat(id),
                        ),
                        onTap: () {
                          if (Navigator.canPop(context)) Navigator.pop(context); // Close drawer
                          _loadChat(id);
                        },
                      );
                    },
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
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryTeal.withValues(alpha: 0.15) : AppColors.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser ? AppColors.primaryTeal.withValues(alpha: 0.3) : AppColors.borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.primaryTeal,
                      child: Text('A', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 8)),
                    ),
                    const SizedBox(width: 6),
                    const Text('Artha', style: TextStyle(fontSize: 11, color: AppColors.primaryTeal, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            isUser
                ? Text(msg.content, style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4))
                : MarkdownBody(
                    data: msg.content,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 15, color: Colors.white, height: 1.5),
                      h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                      h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                      h3: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                      listBullet: const TextStyle(color: AppColors.primaryTeal),
                      code: TextStyle(backgroundColor: Colors.black26, color: Colors.amber.shade200, fontFamily: 'monospace'),
                      codeblockDecoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                      strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildSuggestions(List<String> suggestions) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((s) {
          return GestureDetector(
            onTap: () {
              _controller.text = s;
              _controller.selection = TextSelection.collapsed(offset: s.length);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
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
            const CircleAvatar(radius: 10, backgroundColor: AppColors.primaryTeal,
              child: Text('A', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 8))),
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
