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

/// Time-based greeting in the user's language.
/// Returns "Good morning" / "शुभ प्रभात" etc. based on IST time.
String getGreeting(WidgetRef ref) {
  final hour = DateTime.now().toLocal().hour;
  if (hour < 12) return t(ref, 'good_morning');
  if (hour < 17) return t(ref, 'good_afternoon');
  return t(ref, 'good_evening');
}
