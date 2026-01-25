import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/receita.dart';
import '../../domain/repositories/receita_repository.dart';

/// Implementação local do ReceitaRepository usando SharedPreferences
class LocalReceitaRepository implements ReceitaRepository {
  static const String _receitasKey = 'limite_mei_receitas';
  final SharedPreferences prefs;

  LocalReceitaRepository({required this.prefs});

  @override
  Future<void> addReceita(Receita receita) async {
    final receitas = await getAll();
    receitas.add(receita);
    await _saveAll(receitas);
  }

  @override
  Future<List<Receita>> getReceitasByYear(int year) async {
    final all = await getAll();
    return all.where((r) => r.data.year == year).toList();
  }

  @override
  Future<List<Receita>> getReceitasByYearMonth(int year, int month) async {
    final all = await getAll();
    return all
        .where((r) => r.data.year == year && r.data.month == month)
        .toList();
  }

  @override
  Future<Receita?> getReceitaById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateReceita(Receita receita) async {
    final receitas = await getAll();
    final index = receitas.indexWhere((r) => r.id == receita.id);
    if (index != -1) {
      receitas[index] = receita;
      await _saveAll(receitas);
    }
  }

  @override
  Future<void> deleteReceita(String id) async {
    final receitas = await getAll();
    receitas.removeWhere((r) => r.id == id);
    await _saveAll(receitas);
  }

  @override
  Future<int> countAll() async {
    final all = await getAll();
    return all.length;
  }

  @override
  Future<int> countByYear(int year) async {
    final receitas = await getReceitasByYear(year);
    return receitas.length;
  }

  @override
  Future<double> sumByYear(int year) async {
    final receitas = await getReceitasByYear(year);
    return receitas.fold<double>(0.0, (sum, r) => sum + r.valor);
  }

  @override
  Future<double> sumByYearMonth(int year, int month) async {
    final receitas = await getReceitasByYearMonth(year, month);
    return receitas.fold<double>(0.0, (sum, r) => sum + r.valor);
  }

  @override
  Future<void> deleteAll() async {
    await prefs.remove(_receitasKey);
  }

  /// Privado: Obtem todas as receitas
  Future<List<Receita>> getAll() async {
    final json = prefs.getString(_receitasKey) ?? '[]';
    final list = jsonDecode(json) as List;
    return list
        .map((e) => Receita.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Privado: Salva todas as receitas
  Future<void> _saveAll(List<Receita> receitas) async {
    final json = jsonEncode(receitas.map((r) => r.toJson()).toList());
    await prefs.setString(_receitasKey, json);
  }
}
