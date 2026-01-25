import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/entitlements.dart';
import '../../domain/repositories/entitlements_repository.dart';

/// Implementação local de EntitlementsRepository
/// Nota: Integração com Google Play Billing será feita após MVP
class LocalEntitlementsRepository implements EntitlementsRepository {
  static const String _entitlementsKey = 'limite_mei_entitlements';

  final SharedPreferences prefs;

  LocalEntitlementsRepository({required this.prefs});

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
  Future<bool> isPremiumActive() async {
    final ent = await getEntitlements();
    return ent.isActive;
  }

  @override
  Future<bool> restorePurchase() async {
    // TODO: Integrar com Google Play Billing quando tivermos acesso à store
    // Por enquanto, apenas verificar se já tem entitlement salvo
    final ent = await getEntitlements();
    return ent.isPremium;
  }

  @override
  Future<void> resetToFree() async {
    await setEntitlements(Entitlements.free());
  }
}
