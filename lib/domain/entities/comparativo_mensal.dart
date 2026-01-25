class ComparativoMensal {
  final int anoBase;
  final int mesBase;
  final double totalBase;
  final int anoComparado;
  final int mesComparado;
  final double totalComparado;
  final double delta;
  final double deltaPorcentagem;

  ComparativoMensal({
    required this.anoBase,
    required this.mesBase,
    required this.totalBase,
    required this.anoComparado,
    required this.mesComparado,
    required this.totalComparado,
    required this.delta,
    required this.deltaPorcentagem,
  });

  bool get isPositivo => delta >= 0;
  bool get temComparacao => totalComparado > 0;
}

class ComparativoAnual {
  final int anoBase;
  final int anoAnterior;
  final double totalAnoBase;
  final double totalAnoAnterior;
  final double delta;
  final double deltaPorcentagem;
  final Map<int, ComparativoMes> comparativoPorMes; // mes (1-12) -> comparativo

  ComparativoAnual({
    required this.anoBase,
    required this.anoAnterior,
    required this.totalAnoBase,
    required this.totalAnoAnterior,
    required this.delta,
    required this.deltaPorcentagem,
    required this.comparativoPorMes,
  });

  bool get isPositivo => delta >= 0;
  
  ComparativoMes? get mesMaiorDiferenca {
    if (comparativoPorMes.isEmpty) return null;
    return comparativoPorMes.values.reduce((a, b) => 
      a.delta.abs() > b.delta.abs() ? a : b
    );
  }
}

class ComparativoMes {
  final int mes;
  final double totalBase;
  final double totalAnterior;
  final double delta;

  ComparativoMes({
    required this.mes,
    required this.totalBase,
    required this.totalAnterior,
    required this.delta,
  });
}

class MetaRitmo {
  final double limiteAnual;
  final double mediaIdeal; // limite/12
  final double mediaAtual; // total_ano / mes_atual
  final bool acimaDoRitmo;
  final double totalAno;
  final int mesAtual;

  MetaRitmo({
    required this.limiteAnual,
    required this.mediaIdeal,
    required this.mediaAtual,
    required this.acimaDoRitmo,
    required this.totalAno,
    required this.mesAtual,
  });

  double get diferencaMensal => mediaAtual - mediaIdeal;
  double get porcentagemDoRitmo => mediaIdeal > 0 ? (mediaAtual / mediaIdeal) * 100 : 0;
}
