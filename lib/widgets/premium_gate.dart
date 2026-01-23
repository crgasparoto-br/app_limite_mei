// contents of file
import 'package:flutter/material.dart';
import '../models/entitlements.dart';
import '../services/entitlements_service.dart';
import '../pages/paywall_page.dart';

class PremiumGate extends StatelessWidget {
  final Widget child;
  final String featureKey; // ex: "projection", "export"
  final String title;
  final String subtitle;

  const PremiumGate({
    super.key,
    required this.child,
    required this.featureKey,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Entitlements>(
      valueListenable: EntitlementsService.instance.notifier,
      builder: (context, ent, _) {
        if (ent.effectivePremium) return child;

        return _LockedFeature(
          title: title,
          subtitle: subtitle,
          onUnlock: () => Navigator.pushNamed(
            context,
            '/paywall',
            arguments: PaywallArgs(source: 'feature_lock', featureKey: featureKey),
          ),
        );
      },
    );
  }
}

class _LockedFeature extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onUnlock;

  const _LockedFeature({
    required this.title,
    required this.subtitle,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 48),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onUnlock,
              child: const Text('Ativar Premium grátis (7 dias)'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Agora não'),
            )
          ],
        ),
      ),
    );
  }
}