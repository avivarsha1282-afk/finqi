import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/firebase_service.dart';
import '../../../services/api_service.dart';
import '../../../services/secure_storage_service.dart';
import '../../../core/constants/api_constants.dart';

// Stream of Firebase auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseService.instance.authStateStream;
});

// Auth controller state
class AuthState {
  final bool isLoading;
  final String? error;
  AuthState({this.isLoading = false, this.error});
  AuthState copyWith({bool? isLoading, String? error}) =>
      AuthState(isLoading: isLoading ?? this.isLoading, error: error ?? this.error);
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(AuthState());

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final credential = await FirebaseService.instance.signInWithGoogle();

      // Verify with backend and store onboarding state
      try {
        final result = await ApiService.instance.verifyAuth();
        final onboardingComplete = result['onboarding_complete'] as bool? ?? false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(ApiConstants.keyOnboardingComplete, onboardingComplete);
      } catch (_) {
        // Backend down — let router handle via Firebase isNewUser flag
      }

      state = state.copyWith(isLoading: false);
      return FirebaseService.instance.isNewUser(credential);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: FirebaseService.friendlyError(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().contains('aborted') ? null : 'Sign-in failed. Try again.',
      );
      return false;
    }
  }

  Future<void> signInDemo() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await FirebaseService.instance.signInWithEmail(
        ApiConstants.demoEmail,
        ApiConstants.demoPassword,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(ApiConstants.keyOnboardingComplete, true);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Demo login failed. Check Firebase console.',
      );
    }
  }

  Future<void> signOut() async {
    await FirebaseService.instance.signOut();
    await SecureStorageService.instance.clearAll();
    // Clear onboarding flag so next user starts fresh
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.keyOnboardingComplete);
    await prefs.remove(ApiConstants.keyLanguage);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});
