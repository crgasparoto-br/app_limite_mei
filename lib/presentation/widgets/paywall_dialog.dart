import 'package:flutter/material.dart';

/// Widget de Paywall - Oferece upgrade para Premium
class PaywallDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? dismissLabel;
  final VoidCallback onUpgrade;
  final VoidCallback? onRestore;

  const PaywallDialog({
    super.key,
    this.title = 'Evite estourar o limite com mais segurança',
    this.subtitle = 'Upgrade para Premium e desbloqueie recursos avançados',
    this.dismissLabel = 'Agora não',
    required this.onUpgrade,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
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

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // Features
            _FeatureList(),
            const SizedBox(height: 32),

            // Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onUpgrade,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  'Assinar Premium',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Dismiss button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(dismissLabel ?? 'Agora não'),
              ),
            ),

            // Restore purchase link
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
    );
  }
}

/// Lista de features do Premium
class _FeatureList extends StatelessWidget {
  const _FeatureList();

  @override
  Widget build(BuildContext context) {
    const features = [
      'Lançamentos ilimitados',
      'Filtro de receitas por mês',
      'Relatório mensal detalhado',
      'Comparativos entre meses e anos',
      'Análise de ritmo de faturamento',
      'Alertas 70%, 80%, 90%, 95%, 100%',
      'Exportar para contador (CSV/PDF)',
      'Histórico de anos anteriores',
    ];

    return Column(
      children: features
          .map((feature) => Padding(
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
              ))
          .toList(),
    );
  }
}

/// Mostrar PaywallDialog
Future<bool?> showPaywall(
  BuildContext context, {
  String title = 'Evite estourar o limite com mais segurança',
  String subtitle = 'Upgrade para Premium e desbloqueie recursos avançados',
  required VoidCallback onUpgrade,
  VoidCallback? onRestore,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PaywallDialog(
      title: title,
      subtitle: subtitle,
      onUpgrade: onUpgrade,
      onRestore: onRestore,
    ),
  );
}
