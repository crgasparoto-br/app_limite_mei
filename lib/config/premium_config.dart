import '../domain/entities/premium_offer.dart';

class PremiumConfig {
  const PremiumConfig._();

  static const String androidPackageName = 'br.com.limitemei';
  static const String monthlyProductId = 'br.com.limitemei.premium.mensal';
  static const String annualProductId = 'br.com.limitemei.premium.anual';
  static const String lifetimeProductId = 'br.com.limitemei.premium.vitalicio';

  static const List<PremiumOffer> offers = [
    PremiumOffer(
      id: monthlyProductId,
      title: 'Mensal',
      totalPriceLabel: 'R\$ 9,99',
      subtitle: 'Ideal para comecar hoje com baixo custo e mais flexibilidade.',
      type: PremiumPlanType.monthly,
      chargeLabel: 'cobrado por mes',
    ),
    PremiumOffer(
      id: annualProductId,
      title: 'Anual',
      totalPriceLabel: 'R\$ 83,88',
      subtitle:
          'A melhor escolha para acompanhar o ano inteiro com menor custo total.',
      badge: 'Melhor oferta',
      type: PremiumPlanType.annual,
      breakdownPriceLabel: '12x de R\$ 6,99',
      chargeLabel: 'cobrado ao longo de 12 parcelas',
    ),
    PremiumOffer(
      id: lifetimeProductId,
      title: 'Vitalicio de lancamento',
      totalPriceLabel: 'R\$ 99,99',
      subtitle:
          'Garanta o menor custo total com pagamento unico e acesso permanente.',
      badge: 'Lancamento',
      type: PremiumPlanType.lifetime,
      chargeLabel: 'pagamento unico',
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
