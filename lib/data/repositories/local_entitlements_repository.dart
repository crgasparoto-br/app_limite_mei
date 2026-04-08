import 'google_play_entitlements_repository.dart';

@Deprecated('Use GooglePlayEntitlementsRepository.')
class LocalEntitlementsRepository extends GooglePlayEntitlementsRepository {
  LocalEntitlementsRepository({required super.prefs});
}
