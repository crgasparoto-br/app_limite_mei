class Lancamento {
  final dynamic id;
  final DateTime data;
  final double valor;
  final String tipo; // 'R' ou 'D'
  final String descricao;
  final String categoria;

  Lancamento({
    required this.id,
    required this.data,
    required this.valor,
    required this.tipo,
    required this.descricao,
    required this.categoria,
  });

  factory Lancamento.fromMap(Map<String, dynamic> m) {
    return Lancamento(
      id: m['id'],
      data: DateTime.parse((m['data'] ?? '').toString()),
      valor: (m['valor'] as num?)?.toDouble() ?? 0.0,
      tipo: (m['tipo'] ?? 'R').toString(),
      descricao: (m['descricao'] ?? '').toString(),
      categoria: (m['categoria'] ?? 'Geral').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'data': data.toIso8601String().split('T').first,
        'valor': valor,
        'tipo': tipo,
        'descricao': descricao,
        'categoria': categoria,
      };
}