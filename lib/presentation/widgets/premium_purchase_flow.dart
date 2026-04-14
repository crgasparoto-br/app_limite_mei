import 'package:flutter/material.dart';

import '../../config/premium_config.dart';
import '../../domain/entities/premium_offer.dart';
import '../../domain/repositories/entitlements_repository.dart';
import '../../service_locator.dart';
import 'paywall_dialog.dart';

Future<void> showPremiumPaywallFlow(
  BuildContext context, {
  required Future<void> Function() onSuccess,
  String title = 'Evite estourar o limite com mais seguranca',
  String subtitle = 'Escolha um plano para liberar todos os recursos',
}) async {
  final repo = getIt<EntitlementsRepository>();
  List<PremiumOffer> offers = PremiumConfig.offers;

  try {
    offers = await repo.getAvailableOffers();
  } catch (_) {
    offers = PremiumConfig.offers;
  }

  if (!context.mounted) return;

  void handlePurchase(PremiumOffer offer) async {
    Navigator.of(context).pop();

    try {
      final purchased = await repo.purchasePremium(offer.id);
      if (!context.mounted) return;

      if (purchased) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plano ${offer.planLabel} ativado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        await onSuccess();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Compra cancelada.')));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao ativar plano: $e')));
    }
  }

  void handleRestore() async {
    Navigator.of(context).pop();

    try {
      final restored = await repo.restorePurchase();
      if (!context.mounted) return;

      if (restored) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compra restaurada com sucesso!')),
        );
        await onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma compra encontrada')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao restaurar compra: $e')));
    }
  }

  await showPaywall(
    context,
    title: title,
    subtitle: subtitle,
    offers: offers,
    onUpgrade: handlePurchase,
    onRestore: handleRestore,
  );
}
