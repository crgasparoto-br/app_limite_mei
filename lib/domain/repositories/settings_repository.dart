import '../entities/app_settings.dart';

/// Interface para persistência de configurações
abstract class SettingsRepository {
  /// Obtém configurações atuais
  Future<AppSettings> getSettings();

  /// Salva configurações
  Future<void> saveSettings(AppSettings settings);

  /// Obtém ano selecionado
  Future<int> getSelectedYear();

  /// Define ano selecionado
  Future<void> setSelectedYear(int year);
}
