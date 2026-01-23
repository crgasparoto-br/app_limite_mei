// contents of file
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/entitlements.dart';

class EntitlementsService {
  EntitlementsService._();
  static final EntitlementsService instance = EntitlementsService._();

  final ValueNotifier<Entitlements> notifier =
      ValueNotifier<Entitlements>(Entitlements(isPremium: false));

  bool _loaded = false;
  bool _shownThisSession = false;

  static const _kIsPremium = 'ent_is_premium';
  static const _kTrialEnds = 'ent_trial_ends_at';
  static const _kPremiumEnds = 'ent_premium_ends_at';
  static const _kUpdatedAt = 'ent_updated_at';

  Entitlements get current => notifier.value;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();

    final isPremium = prefs.getBool(_kIsPremium) ?? false;
    final trialStr = prefs.getString(_kTrialEnds);
    final premiumStr = prefs.getString(_kPremiumEnds);

    final local = Entitlements(
      isPremium: isPremium,
      trialEndsAt: trialStr != null ? DateTime.tryParse(trialStr)?.toLocal() : null,
      premiumEndsAt: premiumStr != null ? DateTime.tryParse(premiumStr)?.toLocal() : null,
    );

    notifier.value = local;

    // if user logged in, try to sync with Supabase
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final row = await supabase
            .from('user_entitlements')
            .select('is_premium, trial_ends_at, premium_ends_at, updated_at')
            .eq('user_id', user.id)
            .maybeSingle();
        if (row != null) {
          final remote = Entitlements.fromMap(row);
          final remoteUpdated = DateTime.tryParse(row['updated_at'] ?? '')?.toUtc();
          final localUpdatedStr = prefs.getString(_kUpdatedAt);
          final localUpdated = localUpdatedStr != null ? DateTime.tryParse(localUpdatedStr)?.toUtc() : null;

          // simple resolution: prefer the newest updated_at; if none, prefer remote
          if (remoteUpdated != null && (localUpdated == null || remoteUpdated.isAfter(localUpdated))) {
            notifier.value = remote;
            await _saveLocal(remote);
          } else if (localUpdated != null && (remoteUpdated == null || localUpdated.isAfter(remoteUpdated))) {
            await _saveRemote(notifier.value, user.id);
          } else {
            // if no timestamps, prefer remote data (safe)
            notifier.value = remote;
            await _saveLocal(remote);
          }
        } else {
          // no remote row -> push local if not default
          if (local.isPremium || local.trialEndsAt != null || local.premiumEndsAt != null) {
            await _saveRemote(local, user.id);
          }
        }
      } catch (e) {
        if (kDebugMode) print('Entitlements sync failed: $e');
      }
    }

    _loaded = true;
  }

  Future<void> startTrial({int days = 7}) async {
    final ends = DateTime.now().add(Duration(days: days));
    notifier.value = notifier.value.copyWith(trialEndsAt: ends);
    await _saveLocal(notifier.value);
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) await _saveRemote(notifier.value, user.id);
    // analytics simple log
    if (kDebugMode) print('trial_started source=paywall days=$days');
  }

  Future<void> setPremiumActive(DateTime? until) async {
    notifier.value = notifier.value.copyWith(isPremium: true, premiumEndsAt: until);
    await _saveLocal(notifier.value);
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) await _saveRemote(notifier.value, user.id);
  }

  Future<void> clearPremium() async {
    notifier.value = notifier.value.copyWith(isPremium: false, premiumEndsAt: null, trialEndsAt: null);
    await _saveLocal(notifier.value);
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) await _saveRemote(notifier.value, user.id);
  }

  void markShownThisSession() => _shownThisSession = true;
  bool get shownThisSession => _shownThisSession;

  Future<void> _saveLocal(Entitlements e) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsPremium, e.isPremium);
    if (e.trialEndsAt != null) {
      await prefs.setString(_kTrialEnds, e.trialEndsAt!.toUtc().toIso8601String());
    } else {
      await prefs.remove(_kTrialEnds);
    }
    if (e.premiumEndsAt != null) {
      await prefs.setString(_kPremiumEnds, e.premiumEndsAt!.toUtc().toIso8601String());
    } else {
      await prefs.remove(_kPremiumEnds);
    }
    await prefs.setString(_kUpdatedAt, DateTime.now().toUtc().toIso8601String());
  }

  Future<void> _saveRemote(Entitlements e, String userId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('user_entitlements').upsert({
        'user_id': userId,
        'is_premium': e.isPremium,
        'trial_ends_at': e.trialEndsAt?.toUtc().toIso8601String(),
        'premium_ends_at': e.premiumEndsAt?.toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      if (kDebugMode) print('Failed saveRemote entitlements: $e');
    }
  }
}