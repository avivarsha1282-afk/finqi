class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? city;
  final DateTime? memberSince;
  final bool onboardingComplete;
  final String language;
  final Map<String, dynamic>? financialProfile;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.city,
    this.memberSince,
    this.onboardingComplete = false,
    this.language = 'en',
    this.financialProfile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? json['user_id'] ?? '',
      name: json['name'] ?? json['display_name'] ?? 'User',
      email: json['email'] ?? '',
      photoUrl: json['photo_url'] ?? json['photoURL'],
      city: json['city'],
      memberSince: json['member_since'] != null
          ? DateTime.tryParse(json['member_since'])
          : null,
      onboardingComplete: json['onboarding_complete'] ?? false,
      language: json['language'] ?? 'en',
      financialProfile: json['financial_profile'],
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'photo_url': photoUrl,
        'city': city,
        'member_since': memberSince?.toIso8601String(),
        'onboarding_complete': onboardingComplete,
        'language': language,
        'financial_profile': financialProfile,
      };

  UserModel copyWith({
    String? name,
    String? photoUrl,
    String? city,
    bool? onboardingComplete,
    String? language,
    Map<String, dynamic>? financialProfile,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      city: city ?? this.city,
      memberSince: memberSince,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      language: language ?? this.language,
      financialProfile: financialProfile ?? this.financialProfile,
    );
  }
}
