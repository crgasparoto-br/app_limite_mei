import 'package:flutter/material.dart';

import '../../config/premium_config.dart';
import '../../domain/entities/premium_offer.dart';

class PaywallDialog extends StatelessWidget {
  const PaywallDialog({
    super.key,
    this.title = 'Tenha mais controle do seu limite MEI',
    this.subtitle =
        'Libere análises, alertas extras e histórico completo para acompanhar seu faturamento com mais segurança.',
    this.dismissLabel = 'Agora não',
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
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                child: Icon(
                  Icons.star,
                  size: 32,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Text(
                  'Escolha a opção que faz mais sentido para o seu momento.',
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
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                child: Text(dismissLabel ?? 'Agora não'),
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
      'Filtre e consulte por mês com rapidez',
      'Veja relatórios mensais mais detalhados',
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
  const _OfferButton({
    required this.offer,
    required this.onTap,
  });

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
            children: [
              Row(
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
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            offer.priceLabel,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            offer.type == PremiumPlanType.lifetime
                                ? 'pagamento único'
                                : 'por ${offer.type == PremiumPlanType.monthly ? 'mês' : 'ano'}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(92, 40),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Assinar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool?> showPaywall(
  BuildContext context, {
  String title = 'Tenha mais controle do seu limite MEI',
  String subtitle =
      'Libere análises, alertas extras e histórico completo para acompanhar seu faturamento com mais segurança.',
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
