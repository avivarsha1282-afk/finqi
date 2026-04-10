import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/language/providers/language_provider.dart';
import 'strings_en.dart';
import 'strings_hi.dart';

final Map<String, Map<String, String>> _allStrings = {
  'en': stringsEn,
  'hi': stringsHi,
};

/// Global translation function for use in ConsumerWidget / ConsumerState.
/// Usage: t(ref, 'save') → 'Save' or 'सहेजें'
String t(WidgetRef ref, String key) {
  final lang = ref.watch(languageProvider);
  return _allStrings[lang]?[key] ?? stringsEn[key] ?? key;
}

/// For use in non-widget contexts (pass lang string directly).
/// Usage: tLang('hi', 'save') → 'सहेजें'
String tLang(String lang, String key) {
  return _allStrings[lang]?[key] ?? stringsEn[key] ?? key;
}
