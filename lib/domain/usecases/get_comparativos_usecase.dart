import '../entities/comparativo_mensal.dart';
import '../repositories/receita_repository.dart';
import '../repositories/settings_repository.dart';

class GetComparativosUseCase {
  final ReceitaRepository _receitaRepository;
  final SettingsRepository _settingsRepository;

  GetComparativosUseCase(this._receitaRepository, this._settingsRepository);

  Future<ComparativoMensal> compararMeses(int anoBase, int mesBase) async {
    // Calcular mês anterior
    int anoComparado = anoBase;
    int mesComparado = mesBase - 1;
    if (mesComparado < 1) {
      mesComparado = 12;
      anoComparado = anoBase - 1;
    }
    
    final receitasBase = await _receitaRepository.getReceitasByYear(anoBase);
    final totalBase = receitasBase
        .where((r) => r.data.month == mesBase)
        .fold<double>(0.0, (sum, r) => sum + r.valor);
    
    final receitasComparado = await _receitaRepository.getReceitasByYear(anoComparado);
    final totalComparado = receitasComparado
        .where((r) => r.data.month == mesComparado)
        .fold<double>(0.0, (sum, r) => sum + r.valor);
    
    final delta = totalBase - totalComparado;
    final deltaPorcentagem = totalComparado > 0 
        ? ((delta / totalComparado) * 100).toDouble()
        : 0.0;
    
    return ComparativoMensal(
      anoBase: anoBase,
      mesBase: mesBase,
      totalBase: totalBase,
      anoComparado: anoComparado,
      mesComparado: mesComparado,
      totalComparado: totalComparado,
      delta: delta,
      deltaPorcentagem: deltaPorcentagem,
    );
  }

  Future<ComparativoAnual> compararAnos(int anoBase) async {
    final anoAnterior = anoBase - 1;
    
    final receitasBase = await _receitaRepository.getReceitasByYear(anoBase);
    final receitasAnterior = await _receitaRepository.getReceitasByYear(anoAnterior);
    
    final totalAnoBase = receitasBase.fold<double>(0.0, (sum, r) => sum + r.valor);
    final totalAnoAnterior = receitasAnterior.fold<double>(0.0, (sum, r) => sum + r.valor);
    
    final delta = totalAnoBase - totalAnoAnterior;
    final deltaPorcentagem = totalAnoAnterior > 0 
        ? ((delta / totalAnoAnterior) * 100).toDouble()
        : 0.0;
    
    // Comparativo por mês
    final comparativoPorMes = <int, ComparativoMes>{};
    for (int mes = 1; mes <= 12; mes++) {
      final totalBase = receitasBase
          .where((r) => r.data.month == mes)
          .fold<double>(0.0, (sum, r) => sum + r.valor);
      
      final totalAnterior = receitasAnterior
          .where((r) => r.data.month == mes)
          .fold<double>(0.0, (sum, r) => sum + r.valor);
      
      comparativoPorMes[mes] = ComparativoMes(
        mes: mes,
        totalBase: totalBase,
        totalAnterior: totalAnterior,
        delta: totalBase - totalAnterior,
      );
    }
    
    return ComparativoAnual(
      anoBase: anoBase,
      anoAnterior: anoAnterior,
      totalAnoBase: totalAnoBase,
      totalAnoAnterior: totalAnoAnterior,
      delta: delta,
      deltaPorcentagem: deltaPorcentagem,
      comparativoPorMes: comparativoPorMes,
    );
  }

  Future<MetaRitmo> getMetaRitmo(int ano) async {
    final settings = await _settingsRepository.getSettings();
    final limiteAnual = settings.getLimitePorAno(ano);
    final mediaIdeal = (limiteAnual / 12).toDouble();
    
    final receitas = await _receitaRepository.getReceitasByYear(ano);
    final totalAno = receitas.fold<double>(0.0, (sum, r) => sum + r.valor);
    
    final now = DateTime.now();
    final mesAtual = now.year == ano ? now.month : 12;
    final mediaAtual = mesAtual > 0 ? (totalAno / mesAtual).toDouble() : 0.0;
    
    final acimaDoRitmo = mediaAtual > mediaIdeal;
    
    return MetaRitmo(
      limiteAnual: limiteAnual,
      mediaIdeal: mediaIdeal,
      mediaAtual: mediaAtual,
      acimaDoRitmo: acimaDoRitmo,
      totalAno: totalAno,
      mesAtual: mesAtual,
    );
  }
}
