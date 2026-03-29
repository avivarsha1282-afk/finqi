import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileNotifier extends StateNotifier<User?> {
  ProfileNotifier() : super(FirebaseAuth.instance.currentUser);

  void refresh() => state = FirebaseAuth.instance.currentUser;
}

final profileProvider = StateNotifierProvider<ProfileNotifier, User?>((ref) {
  return ProfileNotifier();
});
