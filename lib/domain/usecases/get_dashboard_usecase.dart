import '../repositories/receita_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/entitlements_repository.dart';

/// UseCase: Obter dados do Dashboard
/// Agrupa: total ano, total mês, percentual, restante, status, e validações
class GetDashboardUseCase {
  final ReceitaRepository receitaRepo;
  final SettingsRepository settingsRepo;
  final EntitlementsRepository entitlementsRepo;

  const GetDashboardUseCase({
    required this.receitaRepo,
    required this.settingsRepo,
    required this.entitlementsRepo,
  });

  Future<DashboardData> call() async {
    final year = await settingsRepo.getSelectedYear();
    final settings = await settingsRepo.getSettings();
    final isPremium = await entitlementsRepo.isPremiumActive();

    final totalAno = (await receitaRepo.sumByYear(year)).toDouble();
    final totalMes = (await receitaRepo.sumByYearMonth(year, DateTime.now().month)).toDouble();
    final countReceitas = await receitaRepo.countByYear(year);

    // Usar limite específico do ano se existir, senão usar limite padrão
    final limite = settings.getLimitePorAno(year).toDouble();
    final percentual = limite > 0 ? totalAno / limite : 0.0;
    final restante = (limite - totalAno).clamp(0.0, double.infinity);

    final status = _calculateStatus(percentual, isPremium);
    final canAddMore = isPremium || countReceitas < 120;

    return DashboardData(
      year: year,
      totalAno: totalAno,
      totalMes: totalMes,
      limite: limite,
      percentual: percentual,
      restante: restante,
      status: status,
      countReceitas: countReceitas,
      isPremium: isPremium,
      canAddMore: canAddMore,
    );
  }

  String _calculateStatus(double percentual, bool isPremium) {
    if (percentual >= 1.0) return 'LIMITE_ESTOURADO';
    if (percentual >= 0.9) return 'CRITICO';
    if (percentual >= 0.7 && !isPremium) return 'ALERTA'; // FREE só vê em 90%
    if (percentual >= 0.7) return 'ATENCAO'; // PREMIUM vê em 70%
    return 'OK';
  }
}

/// Dados do Dashboard
class DashboardData {
  final int year;
  final double totalAno;
  final double totalMes;
  final double limite;
  final double percentual;
  final double restante;
  final String status; // OK, ATENCAO, CRITICO, LIMITE_ESTOURADO
  final int countReceitas;
  final bool isPremium;
  final bool canAddMore;

  DashboardData({
    required this.year,
    required this.totalAno,
    required this.totalMes,
    required this.limite,
    required this.percentual,
    required this.restante,
    required this.status,
    required this.countReceitas,
    required this.isPremium,
    required this.canAddMore,
  });
}
