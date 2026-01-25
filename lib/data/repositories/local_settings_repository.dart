import 'dart:convert' show jsonEncode, jsonDecode;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Implementação local de SettingsRepository
class LocalSettingsRepository implements SettingsRepository {
  static const String _settingsKey = 'limite_mei_settings';
  static const String _selectedYearKey = 'limite_mei_selected_year';

  final SharedPreferences prefs;

  LocalSettingsRepository({required this.prefs});

  @override
  Future<AppSettings> getSettings() async {
    final json = prefs.getString(_settingsKey);
    if (json == null) {
      return AppSettings.defaultSettings();
    }
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return AppSettings.fromJson(map);
    } catch (_) {
      return AppSettings.defaultSettings();
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    final json = jsonEncode(settings.toJson());
    await prefs.setString(_settingsKey, json);
  }

  @override
  Future<int> getSelectedYear() async {
    return prefs.getInt(_selectedYearKey) ?? DateTime.now().year;
  }

  @override
  Future<void> setSelectedYear(int year) async {
    await prefs.setInt(_selectedYearKey, year);
  }
}
