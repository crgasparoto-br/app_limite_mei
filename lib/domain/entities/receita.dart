/// Entidade de domínio para Receita
class Receita {
  final String id;
  final double valor;
  final DateTime data;
  final String? descricao;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;

  Receita({
    required this.id,
    required this.valor,
    required this.data,
    this.descricao,
    required this.criadoEm,
    this.atualizadoEm,
  });

  Receita copyWith({
    String? id,
    double? valor,
    DateTime? data,
    String? descricao,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return Receita(
      id: id ?? this.id,
      valor: valor ?? this.valor,
      data: data ?? this.data,
      descricao: descricao ?? this.descricao,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'valor': valor,
      'data': data.toIso8601String(),
      'descricao': descricao,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
    };
  }

  factory Receita.fromJson(Map<String, dynamic> json) {
    return Receita(
      id: json['id'] as String,
      valor: (json['valor'] as num).toDouble(),
      data: DateTime.parse(json['data'] as String),
      descricao: json['descricao'] as String?,
      criadoEm: DateTime.parse(json['criado_em'] as String),
      atualizadoEm: json['atualizado_em'] != null 
          ? DateTime.parse(json['atualizado_em'] as String) 
          : null,
    );
  }
}
