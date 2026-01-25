import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço de gerenciamento de alertas com anti-spam
/// Garante que cada threshold dispara apenas uma vez por ano
class AlertService {
  static const String _alertFlagsKey = 'limite_mei_alert_flags';

  final SharedPreferences prefs;

  AlertService({required this.prefs});

  /// Obtém thresholds ativos para FREE vs PREMIUM
  List<int> getActiveThresholds(bool isPremium) {
    if (isPremium) {
      return [70, 80, 90, 95, 100];
    } else {
      return [90, 100];
    }
  }

  /// Verifica se alerta deve disparar (não foi enviado neste ano)
  bool shouldFireAlert(int threshold, int year) {
    final flags = _getAlertFlags();
    final key = '${threshold}_$year';
    return !flags.containsKey(key) || !(flags[key] as bool);
  }

  /// Marca alerta como disparado para este ano
  Future<void> markAlertAsSent(int threshold, int year) async {
    final flags = _getAlertFlags();
    flags['${threshold}_$year'] = true;
    await _saveAlertFlags(flags);
  }

  /// Avalia percentual e retorna thresholds que devem disparar alerta
  /// Retorna lista de thresholds atingidos que ainda não foram alertados
  List<int> evaluateThresholds(double percentual, bool isPremium, int year) {
    final activeThresholds = getActiveThresholds(isPremium);
    final toAlert = <int>[];

    // Converter percentual para percentagem (0-1 → 0-100)
    final percent = percentual * 100;

    for (final threshold in activeThresholds) {
      // Disparar alerta se percentual >= threshold e ainda não foi enviado
      if (percent >= threshold && shouldFireAlert(threshold, year)) {
        toAlert.add(threshold);
      }
    }

    return toAlert;
  }

  /// Privado: Obtem flags de alertas enviados
  Map<String, dynamic> _getAlertFlags() {
    final json = prefs.getString(_alertFlagsKey) ?? '{}';
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Privado: Salva flags
  Future<void> _saveAlertFlags(Map<String, dynamic> flags) async {
    final json = jsonEncode(flags);
    await prefs.setString(_alertFlagsKey, json);
  }

  /// Limpar flags de um ano específico (para testes ou reset)
  Future<void> clearAlertsForYear(int year) async {
    final flags = _getAlertFlags();
    flags.removeWhere((k, v) => k.endsWith('_$year'));
    await _saveAlertFlags(flags);
  }
}
