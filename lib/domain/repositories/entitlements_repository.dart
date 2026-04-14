import '../entities/entitlements.dart';
import '../entities/premium_offer.dart';

abstract class EntitlementsRepository {
  Future<List<PremiumOffer>> getAvailableOffers();

  Future<Entitlements> getEntitlements();

  Future<void> setEntitlements(Entitlements entitlements);

  Future<bool> purchasePremium(String productId);

  Future<bool> isPremiumActive();

  Future<bool> restorePurchase();

  Future<void> resetToFree();
}
