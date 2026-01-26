import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/receita.dart';
import '../../domain/entities/app_settings.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  /// Inicializa Supabase (já deve ter sido inicializado no main.dart)
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  /// Cliente Supabase
  static SupabaseClient get client => Supabase.instance.client;

  /// Verifica se usuário está autenticado
  bool get isAuthenticated => _client.auth.currentUser != null;

  /// ID do usuário autenticado
  String? get userId => _client.auth.currentUser?.id;

  /// Enviar código OTP para email
  Future<void> sendOTP(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: null,
    );
  }

  /// Verificar código OTP
  Future<bool> verifyOTP(String email, String token) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );
      
      if (response.user != null) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Fazer logout
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Fazer backup de receitas
  Future<void> backupReceitas(List<Receita> receitas) async {
    if (!isAuthenticated) {
      throw Exception('Usuário não autenticado');
    }

    final userId = _client.auth.currentUser!.id;

    // Deletar receitas antigas deste usuário
    await _client
        .from('receitas')
        .delete()
        .eq('user_id', userId);

    // Inserir novas receitas
    final receitasData = receitas.map((r) => {
      'user_id': userId,
      'id': r.id,
      'valor': r.valor,
      'data': r.data.toIso8601String(),
      'descricao': r.descricao,
      'criado_em': r.criadoEm.toIso8601String(),
      'atualizado_em': r.atualizadoEm?.toIso8601String(),
    }).toList();

    if (receitasData.isNotEmpty) {
      await _client.from('receitas').insert(receitasData);
    }
  }

  /// Restaurar receitas do backup
  Future<List<Receita>> restoreReceitas() async {
    if (!isAuthenticated) {
      throw Exception('Usuário não autenticado');
    }

    final userId = _client.auth.currentUser!.id;

    final response = await _client
        .from('receitas')
        .select()
        .eq('user_id', userId);

    final List<Receita> receitas = [];
    for (final item in response) {
      receitas.add(Receita(
        id: item['id'] as String,
        valor: (item['valor'] as num).toDouble(),
        data: DateTime.parse(item['data'] as String),
        descricao: item['descricao'] as String?,
        criadoEm: DateTime.parse(item['criado_em'] as String),
        atualizadoEm: item['atualizado_em'] != null
            ? DateTime.parse(item['atualizado_em'] as String)
            : null,
      ));
    }

    return receitas;
  }

  /// Fazer backup de configurações
  Future<void> backupSettings(AppSettings settings) async {
    if (!isAuthenticated) {
      throw Exception('Usuário não autenticado');
    }

    final userId = _client.auth.currentUser!.id;

    final data = {
      'user_id': userId,
      'limite_anual': settings.limiteAnual,
      'limites_por_ano': settings.limitesPorAno.map((k, v) => MapEntry(k.toString(), v)),
      'alertas_ativos': settings.alertasAtivos.map((k, v) => MapEntry(k.toString(), v)),
      'backup_automatico': settings.backupAutomatico,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Upsert (insert or update)
    await _client
        .from('settings')
        .upsert(data);
  }

  /// Restaurar configurações do backup
  Future<AppSettings?> restoreSettings() async {
    if (!isAuthenticated) {
      throw Exception('Usuário não autenticado');
    }

    final userId = _client.auth.currentUser!.id;

    final response = await _client
        .from('settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    // Converter limites_por_ano
    final limitesPorAno = <int, double>{};
    if (response['limites_por_ano'] != null) {
      final raw = response['limites_por_ano'] as Map;
      raw.forEach((key, value) {
        final intKey = int.tryParse(key.toString());
        if (intKey != null) {
          limitesPorAno[intKey] = (value as num).toDouble();
        }
      });
    }

    // Converter alertas_ativos
    final alertasAtivos = <int, bool>{};
    if (response['alertas_ativos'] != null) {
      final raw = response['alertas_ativos'] as Map;
      raw.forEach((key, value) {
        final intKey = int.tryParse(key.toString());
        if (intKey != null) {
          alertasAtivos[intKey] = value as bool;
        }
      });
    }

    return AppSettings(
      limiteAnual: (response['limite_anual'] as num).toDouble(),
      limitesPorAno: limitesPorAno,
      alertasAtivos: alertasAtivos,
      backupAutomatico: response['backup_automatico'] as bool? ?? false,
    );
  }
}
