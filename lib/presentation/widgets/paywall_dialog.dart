import 'package:flutter/material.dart';

import '../../config/premium_config.dart';
import '../../domain/entities/premium_offer.dart';

class PaywallDialog extends StatelessWidget {
  const PaywallDialog({
    super.key,
    this.title = 'Tenha mais controle do seu limite MEI',
    this.subtitle =
        'Libere analises, alertas extras e historico completo para acompanhar seu faturamento com mais seguranca.',
    this.dismissLabel = 'Continuar na versao gratuita',
    this.offers = PremiumConfig.offers,
    required this.onUpgrade,
    this.onRestore,
  });

  final String title;
  final String subtitle;
  final String? dismissLabel;
  final List<PremiumOffer> offers;
  final ValueChanged<PremiumOffer> onUpgrade;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.star, size: 32, color: Colors.blue.shade700),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Text(
                  'Assinatura opcional. Voce pode continuar usando a versao gratuita e liberar os recursos extras somente se quiser.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const _FeatureList(),
              const SizedBox(height: 24),
              ...offers.map(
                (offer) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OfferButton(
                    offer: offer,
                    onTap: () => onUpgrade(offer),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              _TermsNotice(offers: offers),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(dismissLabel ?? 'Continuar na versao gratuita'),
                ),
              ),
              if (onRestore != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: onRestore,
                    child: const Text(
                      'Restaurar compra',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList();

  @override
  Widget build(BuildContext context) {
    const features = [
      'Lance receitas sem limite',
      'Filtre e consulte por mes com rapidez',
      'Veja relatorios mensais mais detalhados',
      'Compare meses e anos em segundos',
      'Acompanhe seu ritmo antes de estourar o teto',
      'Receba alertas extras ao longo do ano',
      'Exporte para CSV ou PDF quando precisar',
      'Consulte anos anteriores com facilidade',
    ];

    return Column(
      children: features
          .map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _OfferButton extends StatelessWidget {
  const _OfferButton({required this.offer, required this.onTap});

  final PremiumOffer offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = offer.badge != null;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isHighlighted ? Colors.blue : Colors.grey.shade300,
            width: isHighlighted ? 2 : 1,
          ),
          color: isHighlighted ? Colors.blue.shade50 : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (offer.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            offer.subtitle!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade700),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (offer.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        offer.badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: offer.isSubscription
                      ? Colors.blue.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  offer.purchaseTypeLabel,
                  style: TextStyle(
                    color: offer.isSubscription
                        ? Colors.blue.shade900
                        : Colors.orange.shade900,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                offer.totalPriceLabel,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                offer.effectiveChargeLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (offer.breakdownPriceLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  offer.breakdownPriceLabel!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                offer.isSubscription
                    ? 'Renovacao automatica ate cancelamento.'
                    : 'Pagamento unico. Sem renovacao automatica.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(offer.actionLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsNotice extends StatelessWidget {
  const _TermsNotice({required this.offers});

  final List<PremiumOffer> offers;

  PremiumOffer? _findOffer(PremiumPlanType type) {
    for (final offer in offers) {
      if (offer.type == type) return offer;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final monthlyOffer = _findOffer(PremiumPlanType.monthly);
    final annualOffer = _findOffer(PremiumPlanType.annual);
    final lifetimeOffer = _findOffer(PremiumPlanType.lifetime);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informacoes importantes',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Os recursos premium sao opcionais. O app continua disponivel na versao gratuita.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade800),
          ),
          if (monthlyOffer != null) ...[
            const SizedBox(height: 6),
            Text(
              'Mensal: ${monthlyOffer.termsSummary}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade800),
            ),
          ],
          if (annualOffer != null) ...[
            const SizedBox(height: 6),
            Text(
              'Anual: ${annualOffer.termsSummary}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade800),
            ),
          ],
          if (lifetimeOffer != null) ...[
            const SizedBox(height: 6),
            Text(
              'Vitalicio: ${lifetimeOffer.termsSummary}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade800),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Voce pode gerenciar ou cancelar assinaturas pela Google Play na tela de Configuracoes do app.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }
}

Future<bool?> showPaywall(
  BuildContext context, {
  String title = 'Tenha mais controle do seu limite MEI',
  String subtitle =
      'Libere analises, alertas extras e historico completo para acompanhar seu faturamento com mais seguranca.',
  List<PremiumOffer> offers = PremiumConfig.offers,
  required ValueChanged<PremiumOffer> onUpgrade,
  VoidCallback? onRestore,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PaywallDialog(
      title: title,
      subtitle: subtitle,
      offers: offers,
      onUpgrade: onUpgrade,
      onRestore: onRestore,
    ),
  );
}
