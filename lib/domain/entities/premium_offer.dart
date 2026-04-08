enum PremiumPlanType {
  monthly,
  annual,
  lifetime,
}

class PremiumOffer {
  const PremiumOffer({
    required this.id,
    required this.title,
    required this.priceLabel,
    required this.type,
    this.subtitle,
    this.badge,
  });

  final String id;
  final String title;
  final String priceLabel;
  final PremiumPlanType type;
  final String? subtitle;
  final String? badge;

  bool get isSubscription => type != PremiumPlanType.lifetime;

  DateTime? expirationFrom(DateTime purchaseDate) {
    switch (type) {
      case PremiumPlanType.monthly:
        return DateTime(
          purchaseDate.year,
          purchaseDate.month + 1,
          purchaseDate.day,
          purchaseDate.hour,
          purchaseDate.minute,
          purchaseDate.second,
          purchaseDate.millisecond,
          purchaseDate.microsecond,
        );
      case PremiumPlanType.annual:
        return DateTime(
          purchaseDate.year + 1,
          purchaseDate.month,
          purchaseDate.day,
          purchaseDate.hour,
          purchaseDate.minute,
          purchaseDate.second,
          purchaseDate.millisecond,
          purchaseDate.microsecond,
        );
      case PremiumPlanType.lifetime:
        return null;
    }
  }

  String get planLabel {
    switch (type) {
      case PremiumPlanType.monthly:
        return 'Mensal';
      case PremiumPlanType.annual:
        return 'Anual';
      case PremiumPlanType.lifetime:
        return 'Vitalício';
    }
  }
}
