class SettingsModel {
  final String userId;
  final int year;
  final double annualLimit;
  final bool notificationsEnabled;
  final int? lastAlertYear;
  final int? lastAlertLevel;

  SettingsModel({
    required this.userId,
    required this.year,
    required this.annualLimit,
    required this.notificationsEnabled,
    this.lastAlertYear,
    this.lastAlertLevel,
  });

  factory SettingsModel.fromMap(Map<String, dynamic> m) {
    return SettingsModel(
      userId: m['user_id'].toString(),
      year: (m['year'] as num?)?.toInt() ?? DateTime.now().year,
      annualLimit: (m['annual_limit'] as num?)?.toDouble() ?? 0.0,
      notificationsEnabled: (m['notifications_enabled'] as bool?) ?? true,
      lastAlertYear: (m['last_alert_year'] as num?)?.toInt(),
      lastAlertLevel: (m['last_alert_level'] as num?)?.toInt(),
    );
  }
}