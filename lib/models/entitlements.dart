// contents of file
class Entitlements {
  final bool isPremium;
  final DateTime? trialEndsAt;
  final DateTime? premiumEndsAt;

  Entitlements({
    required this.isPremium,
    this.trialEndsAt,
    this.premiumEndsAt,
  });

  bool get hasTrialActive =>
      trialEndsAt != null && DateTime.now().isBefore(trialEndsAt!);

  bool get hasPremiumActive =>
      premiumEndsAt != null && DateTime.now().isBefore(premiumEndsAt!);

  bool get effectivePremium => isPremium || hasTrialActive || hasPremiumActive;

  Entitlements copyWith({
    bool? isPremium,
    DateTime? trialEndsAt,
    DateTime? premiumEndsAt,
  }) {
    return Entitlements(
      isPremium: isPremium ?? this.isPremium,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      premiumEndsAt: premiumEndsAt ?? this.premiumEndsAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'is_premium': isPremium,
        'trial_ends_at': trialEndsAt?.toUtc().toIso8601String(),
        'premium_ends_at': premiumEndsAt?.toUtc().toIso8601String(),
      };

  static Entitlements fromMap(Map? m) {
    if (m == null) return Entitlements(isPremium: false);
    DateTime? parse(String? s) => s == null ? null : DateTime.parse(s).toLocal();
    return Entitlements(
      isPremium: (m['is_premium'] as bool?) ?? false,
      trialEndsAt: parse(m['trial_ends_at'] as String? ?? m['trial_ends_at']),
      premiumEndsAt: parse(m['premium_ends_at'] as String? ?? m['premium_ends_at']),
    );
  }
}