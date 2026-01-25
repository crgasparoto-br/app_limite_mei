import '../entities/receita.dart';

/// Interface abstrata do repositório de Receitas
/// Permite trocar implementação (SharedPreferences → SQLite → Backend)
abstract class ReceitaRepository {
  /// Adiciona nova receita
  Future<void> addReceita(Receita receita);

  /// Lista receitas do ano especificado
  Future<List<Receita>> getReceitasByYear(int year);

  /// Lista receitas do mês especificado
  Future<List<Receita>> getReceitasByYearMonth(int year, int month);

  /// Obtém receita por ID
  Future<Receita?> getReceitaById(String id);

  /// Atualiza receita existente
  Future<void> updateReceita(Receita receita);

  /// Deleta receita
  Future<void> deleteReceita(String id);

  /// Conta total de receitas (usado para validar limite FREE)
  Future<int> countAll();

  /// Conta receitas do ano
  Future<int> countByYear(int year);

  /// Soma valores do ano
  Future<double> sumByYear(int year);

  /// Soma valores do mês
  Future<double> sumByYearMonth(int year, int month);

  /// Limpa todas as receitas
  Future<void> deleteAll();
}
