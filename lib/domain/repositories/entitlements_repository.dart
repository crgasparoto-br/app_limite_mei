import '../entities/entitlements.dart';

abstract class EntitlementsRepository {
  Future<Entitlements> getEntitlements();

  Future<void> setEntitlements(Entitlements entitlements);

  Future<bool> purchasePremium(String productId);

  Future<bool> isPremiumActive();

  Future<bool> restorePurchase();

  Future<void> resetToFree();
}
