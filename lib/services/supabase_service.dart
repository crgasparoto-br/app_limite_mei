import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lancamento.dart';
import '../models/settings_model.dart';

class FluxoMes {
  final int month;
  final double receitas;
  final double despesas;
  FluxoMes(this.month, this.receitas, this.despesas);
}

class SupabaseService {
  final client = Supabase.instance.client;

  Future<SettingsModel?> getSettingsForUser(String userId) async {
    final row = await client
        .from('settings')
        .select('user_id, year, annual_limit, notifications_enabled, last_alert_year, last_alert_level')
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return SettingsModel.fromMap((row as Map).cast<String, dynamic>());
  }

  Future<double> getTotalReceitasAno(String userId, int year) async {
    final row = await client.from('vw_receitas_total_ano').select('total').eq('user_id', userId).eq('year', year).maybeSingle();
    return (row?['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<FluxoMes>> getFluxoPorMes(String userId, int year) async {
    final rows = await client.from('vw_fluxo_por_mes').select('month, receitas, despesas').eq('user_id', userId).eq('year', year);
    return (rows as List).map((r) {
      final m = (r['month'] as num?)?.toInt() ?? 0;
      final rec = (r['receitas'] as num?)?.toDouble() ?? 0.0;
      final d = (r['despesas'] as num?)?.toDouble() ?? 0.0;
      return FluxoMes(m, rec, d);
    }).toList();
  }

  Future<List<Lancamento>> getReceitasInRange(String userId, DateTime start, DateTime end) async {
    final rows = await client
        .from('receitas')
        .select('id, data, valor, descricao, tipo, categoria, created_at')
        .eq('user_id', userId)
        .gte('data', _formatDate(start))
        .lt('data', _formatDate(end))
        .order('data', ascending: false)
        .limit(600);
    return (rows as List).map((e) => Lancamento.fromMap((e as Map).cast<String, dynamic>())).toList();
  }

  Future<void> deleteLancamentoById(dynamic id, String userId) async {
    await client.from('receitas').delete().eq('id', id).eq('user_id', userId);
  }

  Future<void> updateAlertMetadata(String userId, int year, int level) async {
    await client.from('settings').update({
      'last_alert_year': year,
      'last_alert_level': level,
      'last_alert_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('user_id', userId);
  }

  String formatBRL(double v) {
    final negative = v < 0;
    final absV = v.abs();
    final s = absV.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final posFromEnd = intPart.length - i;
      buf.write(intPart[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buf.write('.');
    }
    final sign = negative ? '-' : '';
    return 'R\$ $sign${buf.toString()},$decPart';
  }

  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}