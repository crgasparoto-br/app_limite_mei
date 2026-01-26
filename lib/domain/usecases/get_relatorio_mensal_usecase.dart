import '../entities/relatorio_mensal.dart';
import '../repositories/receita_repository.dart';

class GetRelatorioMensalUseCase {
  final ReceitaRepository _receitaRepository;

  GetRelatorioMensalUseCase(this._receitaRepository);

  Future<RelatorioMensal> call(int ano, int mes) async {
    final todasReceitas = await _receitaRepository.getReceitasByYear(ano);
    
    // Filtrar receitas do mês
    final receitasDoMes = todasReceitas.where((r) => r.data.month == mes).toList();
    
    // Total do mês
    final totalMes = receitasDoMes.fold<double>(0.0, (sum, r) => sum + r.valor);
    
    // Quantidade de lançamentos
    final qtdLancamentos = receitasDoMes.length;
    
    // Média por lançamento
    final mediaPorLancamento = qtdLancamentos > 0 ? (totalMes / qtdLancamentos).toDouble() : 0.0;
    
    // Maior lançamento
    double maiorLancamento = 0;
    DateTime? dataMaiorLancamento;
    if (receitasDoMes.isNotEmpty) {
      final receitaMaior = receitasDoMes.reduce((a, b) => a.valor > b.valor ? a : b);
      maiorLancamento = receitaMaior.valor;
      dataMaiorLancamento = receitaMaior.data;
    }
    
    // Total por semana
    final totalPorSemana = <int, double>{};
    for (var receita in receitasDoMes) {
      final semana = ((receita.data.day - 1) ~/ 7) + 1;
      totalPorSemana[semana] = (totalPorSemana[semana] ?? 0) + receita.valor;
    }
    
    // Top 5 dias
    final totalPorDia = <DateTime, DiaComTotal>{};
    for (var receita in receitasDoMes) {
      final dia = DateTime(receita.data.year, receita.data.month, receita.data.day);
      if (totalPorDia.containsKey(dia)) {
        totalPorDia[dia] = DiaComTotal(
          data: dia,
          total: totalPorDia[dia]!.total + receita.valor,
          qtdLancamentos: totalPorDia[dia]!.qtdLancamentos + 1,
        );
      } else {
        totalPorDia[dia] = DiaComTotal(
          data: dia,
          total: receita.valor,
          qtdLancamentos: 1,
        );
      }
    }
    
    final top5Dias = totalPorDia.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    final top5 = top5Dias.take(5).toList();
    
    // Dia de pico (dia com maior faturamento)
    final diaDePico = top5Dias.isNotEmpty ? top5Dias.first : null;
    
    return RelatorioMensal(
      ano: ano,
      mes: mes,
      totalMes: totalMes,
      qtdLancamentos: qtdLancamentos,
      mediaPorLancamento: mediaPorLancamento,
      maiorLancamento: maiorLancamento,
      dataMaiorLancamento: dataMaiorLancamento,
      totalPorSemana: totalPorSemana,
      top5Dias: top5,
      diaDePico: diaDePico,
    );
  }
}
