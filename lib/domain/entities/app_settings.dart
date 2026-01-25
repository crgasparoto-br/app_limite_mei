/// Entidade de Configurações do App
class AppSettings {
  final double limiteAnual; // Limite padrão (usado por FREE e como fallback)
  final Map<int, double> limitesPorAno; // Premium: limites específicos por ano
  final Map<int, bool> alertasAtivos; // 70, 80, 90, 95, 100
  final bool backupAutomatico;

  AppSettings({
    required this.limiteAnual,
    Map<int, double>? limitesPorAno,
    required this.alertasAtivos,
    this.backupAutomatico = false,
  }) : limitesPorAno = limitesPorAno ?? {};

  /// Retorna o limite para um ano específico
  /// Se não houver limite configurado para o ano, retorna limiteAnual padrão
  double getLimitePorAno(int ano) {
    return limitesPorAno[ano] ?? limiteAnual;
  }

  AppSettings copyWith({
    double? limiteAnual,
    Map<int, double>? limitesPorAno,
    Map<int, bool>? alertasAtivos,
    bool? backupAutomatico,
  }) {
    return AppSettings(
      limiteAnual: limiteAnual ?? this.limiteAnual,
      limitesPorAno: limitesPorAno ?? this.limitesPorAno,
      alertasAtivos: alertasAtivos ?? this.alertasAtivos,
      backupAutomatico: backupAutomatico ?? this.backupAutomatico,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'limite_anual': limiteAnual,
      'limites_por_ano': limitesPorAno.map((k, v) => MapEntry(k.toString(), v)),
      'alertas_ativos': alertasAtivos.map((k, v) => MapEntry(k.toString(), v)),
      'backup_automatico': backupAutomatico,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    Map<int, bool> alertas;
    
    if (json['alertas_ativos'] != null) {
      final raw = json['alertas_ativos'];
      alertas = {};
      
      if (raw is Map) {
        raw.forEach((key, value) {
          final intKey = key is int ? key : int.tryParse(key.toString());
          if (intKey != null) {
            alertas[intKey] = value as bool;
          }
        });
      }
    } else {
      alertas = {70: false, 80: false, 90: true, 95: false, 100: true};
    }

    Map<int, double> limitesPorAno = {};
    if (json['limites_por_ano'] != null) {
      final raw = json['limites_por_ano'];
      if (raw is Map) {
        raw.forEach((key, value) {
          final intKey = key is int ? key : int.tryParse(key.toString());
          if (intKey != null) {
            limitesPorAno[intKey] = (value as num).toDouble();
          }
        });
      }
    }
    
    return AppSettings(
      limiteAnual: (json['limite_anual'] as num?)?.toDouble() ?? 81000.0,
      limitesPorAno: limitesPorAno,
      alertasAtivos: alertas,
      backupAutomatico: json['backup_automatico'] as bool? ?? false,
    );
  }

  static AppSettings defaultSettings() {
    return AppSettings(
      limiteAnual: 81000.0,
      alertasAtivos: {70: false, 80: false, 90: true, 95: false, 100: true},
      backupAutomatico: false,
    );
  }
}
