import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';

class FirestoreService {
  FirestoreService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Upsert user profile data
  static Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
    } catch (e) {
      // Graceful local fallback if offline
      print('Firestore save failed: $e');
    }
  }

  /// Load user profile data
  static Future<Map<String, dynamic>?> loadUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  /// Check onboarding completion
  static Future<bool> hasCompletedOnboarding(String uid) async {
    final profile = await loadUserProfile(uid);
    return profile?['onboarding_complete'] == true;
  }

  /// Append chat message to user history
  static Future<void> saveChatMessage(String uid, ChatMessage message) async {
    try {
      await _db.collection('users').doc(uid).collection('chat_history').add({
        'content': message.content,
        'isUser': message.isUser,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Retrieve last 20 messages for session history
  static Future<List<ChatMessage>> loadChatHistory(String uid) async {
    try {
      final snapshot = await _db.collection('users')
          .doc(uid)
          .collection('chat_history')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        final content = data['content'] as String? ?? '';
        final isUser = data['isUser'] as bool? ?? false;
        return isUser ? ChatMessage.user(content) : ChatMessage.artha(content);
      }).toList();
      
      return messages.reversed.toList(); // Oldest first for chat UI
    } catch (_) {
      return [];
    }
  }
}
