// contents of file
import 'package:flutter/material.dart';
import '../services/entitlements_service.dart';

class PaywallArgs {
  final String source; // "feature_lock" | "risk_event" | "menu"
  final String? featureKey;
  PaywallArgs({required this.source, this.featureKey});
}

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as PaywallArgs?;

    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fique tranquilo com o seu MEI',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Evite surpresas com projeções e alertas inteligentes.'),
            const SizedBox(height: 16),
            const _Bullet('📈 Projeção de estouro do limite'),
            const _Bullet('🔔 Alertas inteligentes'),
            const _Bullet('📊 Relatórios mensais'),
            const _Bullet('📤 Exportação para contador'),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                // inicia trial local e remoto
                await EntitlementsService.instance.startTrial(days: 7);
                // opcional: marcar analytics / origem
                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('Testar Premium grátis por 7 dias (sem cartão)'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Agora não'),
            ),
            if (args != null) ...[
              const SizedBox(height: 8),
              Text('Origem: ${args.source}  |  Feature: ${args.featureKey ?? "-"}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(text),
      );
}