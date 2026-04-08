import '../domain/entities/premium_offer.dart';

class PremiumConfig {
  const PremiumConfig._();

  static const String monthlyProductId = 'br.com.limitemei.premium.mensal';
  static const String annualProductId = 'br.com.limitemei.premium.anual';
  static const String lifetimeProductId = 'br.com.limitemei.premium.vitalicio';

  static const List<PremiumOffer> offers = [
    PremiumOffer(
      id: monthlyProductId,
      title: 'Mensal',
      priceLabel: 'R\$ 9,90',
      subtitle: 'Ideal para começar hoje com baixo custo e mais flexibilidade.',
      type: PremiumPlanType.monthly,
    ),
    PremiumOffer(
      id: annualProductId,
      title: 'Anual',
      priceLabel: 'R\$ 59,90',
      subtitle: 'A melhor escolha para economizar e acompanhar o ano inteiro.',
      badge: 'Melhor oferta',
      type: PremiumPlanType.annual,
    ),
    PremiumOffer(
      id: lifetimeProductId,
      title: 'Vitalício de lançamento',
      priceLabel: 'R\$ 99,90',
      subtitle: 'Garanta o menor custo total com pagamento único e acesso permanente.',
      badge: 'Lançamento',
      type: PremiumPlanType.lifetime,
    ),
  ];

  static Set<String> get productIds => offers.map((offer) => offer.id).toSet();

  static PremiumOffer? findOffer(String productId) {
    for (final offer in offers) {
      if (offer.id == productId) {
        return offer;
      }
    }
    return null;
  }
}
