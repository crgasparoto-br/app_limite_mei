import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/premium_config.dart';
import '../../domain/entities/entitlements.dart';
import '../../domain/repositories/entitlements_repository.dart';

class GooglePlayEntitlementsRepository implements EntitlementsRepository {
  GooglePlayEntitlementsRepository({
    required this.prefs,
    InAppPurchase? inAppPurchase,
  }) : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance {
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: _handlePurchaseStreamError,
    );
  }

  static const String _entitlementsKey = 'limite_mei_entitlements';

  final SharedPreferences prefs;
  final InAppPurchase _inAppPurchase;

  // Mantemos a subscription viva enquanto o repositorio existir.
  // ignore: unused_field
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  final Map<String, ProductDetails> _productsById = {};
  bool _initialized = false;
  bool _storeAvailable = false;
  Completer<bool>? _purchaseCompleter;
  Completer<bool>? _restoreCompleter;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    if (kIsWeb) {
      _initialized = true;
      _storeAvailable = false;
      return;
    }

    _storeAvailable = await _inAppPurchase.isAvailable();
    if (_storeAvailable) {
      final response = await _inAppPurchase.queryProductDetails(
        PremiumConfig.productIds,
      );

      if (response.error != null) {
        throw StateError(
          'Falha ao consultar os planos na Google Play: ${response.error!.message}',
        );
      }

      if (response.notFoundIDs.isNotEmpty) {
        throw StateError(
          'Os planos não foram encontrados na Play Console: '
          '${response.notFoundIDs.join(', ')}. '
          'Confira se eles estão criados, ativos e publicados no mesmo track do app.',
        );
      }

      for (final product in response.productDetails) {
        _productsById[product.id] = product;
      }
    }

    _initialized = true;
  }

  @override
  Future<Entitlements> getEntitlements() async {
    final json = prefs.getString(_entitlementsKey);
    if (json == null) {
      return Entitlements.free();
    }

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return Entitlements.fromJson(map);
    } catch (_) {
      return Entitlements.free();
    }
  }

  @override
  Future<void> setEntitlements(Entitlements entitlements) async {
    final json = jsonEncode(entitlements.toJson());
    await prefs.setString(_entitlementsKey, json);
  }

  @override
  Future<bool> purchasePremium(String productId) async {
    await _ensureInitialized();
    if (!_storeAvailable) {
      throw StateError(
        'Google Play Billing não está disponível neste dispositivo. '
        'Para testar compras reais, instale o app pela Play Store em um teste interno ou fechado.',
      );
    }

    final product = _productsById[productId];
    if (product == null) {
      throw StateError(
        'Plano indisponível. Verifique se o produto está ativo na Play Console '
        'e se está publicado para a mesma conta e o mesmo track desta instalação.',
      );
    }

    if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
      throw StateError('Já existe uma compra em andamento.');
    }

    final completer = Completer<bool>();
    _purchaseCompleter = completer;

    final started = await _inAppPurchase.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );

    if (!started) {
      _purchaseCompleter = null;
      return false;
    }

    try {
      return await completer.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () => false,
      );
    } finally {
      if (identical(_purchaseCompleter, completer)) {
        _purchaseCompleter = null;
      }
    }
  }

  @override
  Future<bool> isPremiumActive() async {
    final ent = await getEntitlements();
    return ent.isActive;
  }

  @override
  Future<bool> restorePurchase() async {
    await _ensureInitialized();
    if (!_storeAvailable) {
      throw StateError(
        'Google Play Billing não está disponível neste dispositivo. '
        'A restauração precisa ser testada em uma instalação feita pela Play Store.',
      );
    }

    if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
      throw StateError('Já existe uma restauração em andamento.');
    }

    final completer = Completer<bool>();
    _restoreCompleter = completer;
    await _inAppPurchase.restorePurchases();

    try {
      return await completer.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () async => isPremiumActive(),
      );
    } finally {
      if (identical(_restoreCompleter, completer)) {
        _restoreCompleter = null;
      }
    }
  }

  @override
  Future<void> resetToFree() async {
    await setEntitlements(Entitlements.free());
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchaseDetails in purchaseDetailsList) {
      try {
        if (!PremiumConfig.productIds.contains(purchaseDetails.productID)) {
          continue;
        }

        switch (purchaseDetails.status) {
          case PurchaseStatus.pending:
            continue;
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            await _grantPremium(purchaseDetails);
            if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
              _purchaseCompleter!.complete(true);
            }
            if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
              _restoreCompleter!.complete(true);
            }
            break;
          case PurchaseStatus.canceled:
            if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
              _purchaseCompleter!.complete(false);
            }
            if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
              _restoreCompleter!.complete(false);
            }
            break;
          case PurchaseStatus.error:
            final message =
                purchaseDetails.error?.message ?? 'Falha ao processar compra.';
            final error = StateError(message);
            if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
              _purchaseCompleter!.completeError(error);
            }
            if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
              _restoreCompleter!.completeError(error);
            }
            break;
        }
      } finally {
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  void _handlePurchaseStreamError(Object error) {
    if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
      _purchaseCompleter!.completeError(error);
    }
    if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
      _restoreCompleter!.completeError(error);
    }
  }

  Future<void> _grantPremium(PurchaseDetails purchaseDetails) async {
    final rawDate = purchaseDetails.transactionDate;
    final parsedMillis = rawDate == null ? null : int.tryParse(rawDate);
    final purchaseDate = parsedMillis == null
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(parsedMillis);
    final offer = PremiumConfig.findOffer(purchaseDetails.productID);

    await setEntitlements(
      Entitlements(
        isPremium: true,
        dataCompra: purchaseDate,
        dataExpiracao: offer?.expirationFrom(purchaseDate),
        productId: purchaseDetails.productID,
        planLabel: offer?.planLabel,
      ),
    );
  }
}

