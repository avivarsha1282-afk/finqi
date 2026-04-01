import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/firebase_service.dart';
import '../../../services/user_prefs_service.dart';
import '../../../services/api_service.dart';

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
      
      // Fetch user profile from MongoDB backend to fix Bug 1 (Cross-device sync)
      try {
        final authData = await ApiService.instance.verifyAuth();
        if (authData['onboarding_complete'] == true) {
          await UserPrefsService.setOnboardingComplete(true);
        }
      } catch (e) {
        // Safe to ignore if API is briefly down, defaults to local
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

  Future<void> signOut() async {
    // Clear ALL UID-prefixed user data before signing out
    await UserPrefsService.clearCurrentUserData();
    await FirebaseService.instance.signOut();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});
