import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/api_service.dart';
import 'services/cache_service.dart';
import 'services/user_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D0D0D),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Firebase
  await Firebase.initializeApp();

  // Hive offline cache
  await CacheService.init();

  // Initialize API service
  ApiService.instance.init();

  // One-time migration: fix corrupted financial data from formatting bug
  UserDataService.migrateCorruptedData().then((wasCorrupted) {
    if (wasCorrupted) {
      debugPrint('FinIQ: Data migration detected and fixed corrupted financial values');
    }
  });

  runApp(
    const ProviderScope(
      child: FinIQApp(),
    ),
  );
}
