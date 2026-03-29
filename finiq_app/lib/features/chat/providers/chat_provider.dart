import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/chat_message_model.dart';
import '../../../services/api_service.dart';
import '../../language/providers/language_provider.dart';

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref _ref;

  ChatNotifier(this._ref) : super([]);

  String get _lang => _ref.read(languageProvider);

  Future<void> sendMessage(String text, {Map<String, dynamic>? userContext}) async {
    // Add user message
    final userMsg = ChatMessage.user(text);
    state = [...state, userMsg];

    // Add loading bubble
    final loadingMsg = ChatMessage.loading();
    state = [...state, loadingMsg];

    try {
      final response = await ApiService.instance.sendMessage(
        message: text,
        history: state.where((m) => !m.isLoading).toList(),
        language: _lang,
        userContext: userContext,
      );
      // Remove loading and add real response
      state = [...state.where((m) => !m.isLoading), response];
    } catch (e) {
      String errorText;
      if (e is ApiException) {
        final msg = e.message.toLowerCase();
        if (msg.contains('429') || msg.contains('quota') || msg.contains('rate')) {
          errorText = "I'm getting too many requests right now. Please wait a moment and try again 🙏";
        } else if (msg.contains('404')) {
          errorText = "AI model unavailable. Please try again.";
        } else {
          errorText = 'Error: ${e.message}';
        }
      } else {
        errorText = 'Sorry, I had trouble connecting. Please check your internet and try again.';
      }
      final errorMsg = ChatMessage.artha(errorText);
      state = [...state.where((m) => !m.isLoading), errorMsg];
    }
  }

  void clearChat() => state = [];

  void addArthaMessage(String content) {
    state = [...state, ChatMessage.artha(content)];
  }

  List<Map<String, dynamic>> get historyForApi =>
      state.where((m) => !m.isLoading).map((m) => m.toJson()).toList();
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(ref);
});
