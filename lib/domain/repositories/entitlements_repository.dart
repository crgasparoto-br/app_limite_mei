import '../entities/entitlements.dart';

/// Interface para gerenciar direitos (Entitlements)
abstract class EntitlementsRepository {
  /// Obtém entitlements atuais
  Future<Entitlements> getEntitlements();

  /// Define entitlements (após compra ou restauração)
  Future<void> setEntitlements(Entitlements entitlements);

  /// Verifica se é Premium ativo
  Future<bool> isPremiumActive();

  /// Restaura compra (verifica estado no dispositivo/store)
  Future<bool> restorePurchase();

  /// Faz logout/reset dos entitlements para FREE
  Future<void> resetToFree();
}
