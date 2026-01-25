class RelatorioMensal {
  final int ano;
  final int mes;
  final double totalMes;
  final int qtdLancamentos;
  final double mediaPorLancamento;
  final double maiorLancamento;
  final DateTime? dataMaiorLancamento;
  final Map<int, double> totalPorSemana; // semana (1-5) -> total
  final List<DiaComTotal> top5Dias;

  RelatorioMensal({
    required this.ano,
    required this.mes,
    required this.totalMes,
    required this.qtdLancamentos,
    required this.mediaPorLancamento,
    required this.maiorLancamento,
    this.dataMaiorLancamento,
    required this.totalPorSemana,
    required this.top5Dias,
  });

  double get percentualDoLimite => 0.0; // Será calculado com o limite
}

class DiaComTotal {
  final DateTime data;
  final double total;
  final int qtdLancamentos;

  DiaComTotal({
    required this.data,
    required this.total,
    required this.qtdLancamentos,
  });
}
