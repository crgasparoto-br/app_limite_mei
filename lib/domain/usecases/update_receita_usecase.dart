import '../entities/receita.dart';
import '../repositories/receita_repository.dart';

/// UseCase: Atualizar receita existente
class UpdateReceitaUseCase {
  final ReceitaRepository receitaRepo;

  const UpdateReceitaUseCase({
    required this.receitaRepo,
  });

  Future<UpdateReceitaResult> call(Receita receita) async {
    // Validação: valor deve ser > 0
    if (receita.valor <= 0) {
      return UpdateReceitaResult.invalidValue();
    }

    // Validação: data não pode ser futura
    if (receita.data.isAfter(DateTime.now())) {
      return UpdateReceitaResult.futureDate();
    }

    try {
      // Atualizar a data de modificação
      final receitaAtualizada = Receita(
        id: receita.id,
        valor: receita.valor,
        data: receita.data,
        descricao: receita.descricao,
        criadoEm: receita.criadoEm,
        atualizadoEm: DateTime.now(),
      );

      await receitaRepo.updateReceita(receitaAtualizada);
      return UpdateReceitaResult.success();
    } catch (e) {
      return UpdateReceitaResult.error(e.toString());
    }
  }
}

/// Resultado da operação UpdateReceita
class UpdateReceitaResult {
  final bool success;
  final String? error;

  UpdateReceitaResult({
    required this.success,
    this.error,
  });

  factory UpdateReceitaResult.success() => UpdateReceitaResult(success: true);

  factory UpdateReceitaResult.error(String error) => UpdateReceitaResult(
    success: false,
    error: error,
  );

  factory UpdateReceitaResult.invalidValue() => UpdateReceitaResult(
    success: false,
    error: 'Valor deve ser maior que zero',
  );

  factory UpdateReceitaResult.futureDate() => UpdateReceitaResult(
    success: false,
    error: 'Data não pode ser futura',
  );
}
