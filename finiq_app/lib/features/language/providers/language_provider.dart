import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/user_prefs_service.dart';

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('en') {
    _load();
  }

  Future<void> _load() async {
    final lang = await UserPrefsService.getString('app_language');
    state = lang ?? 'en';
  }

  Future<void> setLanguage(String lang) async {
    state = lang;
    await UserPrefsService.setString('app_language', lang);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});
