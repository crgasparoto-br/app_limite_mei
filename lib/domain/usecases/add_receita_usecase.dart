import '../entities/receita.dart';
import '../repositories/receita_repository.dart';
import '../repositories/entitlements_repository.dart';

/// UseCase: Adicionar nova receita
/// Regra: FREE permite máximo 120 receitas
class AddReceitaUseCase {
  final ReceitaRepository receitaRepo;
  final EntitlementsRepository entitlementsRepo;

  const AddReceitaUseCase({
    required this.receitaRepo,
    required this.entitlementsRepo,
  });

  Future<AddReceitaResult> call(Receita receita) async {
    // Verificar se é FREE e já tem 120 receitas
    final isPremium = await entitlementsRepo.isPremiumActive();
    if (!isPremium) {
      final count = await receitaRepo.countAll();
      if (count >= 120) {
        return AddReceitaResult.limitReached();
      }
    }

    // Validação: valor deve ser > 0
    if (receita.valor <= 0) {
      return AddReceitaResult.invalidValue();
    }

    // Validação: data não pode ser futura
    if (receita.data.isAfter(DateTime.now())) {
      return AddReceitaResult.futureDate();
    }

    try {
      await receitaRepo.addReceita(receita);
      return AddReceitaResult.success();
    } catch (e) {
      return AddReceitaResult.error(e.toString());
    }
  }
}

/// Resultado da operação AddReceita
class AddReceitaResult {
  final bool success;
  final String? error;
  final bool isLimitReached;

  AddReceitaResult({
    required this.success,
    this.error,
    this.isLimitReached = false,
  });

  factory AddReceitaResult.success() => AddReceitaResult(success: true);

  factory AddReceitaResult.error(String error) => AddReceitaResult(
    success: false,
    error: error,
  );

  factory AddReceitaResult.limitReached() => AddReceitaResult(
    success: false,
    error: 'Limite de 120 receitas atingido. Upgrade para Premium!',
    isLimitReached: true,
  );

  factory AddReceitaResult.invalidValue() => AddReceitaResult(
    success: false,
    error: 'Valor deve ser maior que zero',
  );

  factory AddReceitaResult.futureDate() => AddReceitaResult(
    success: false,
    error: 'Data não pode ser futura',
  );
}
