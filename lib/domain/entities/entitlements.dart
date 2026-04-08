/// Entidade de Direitos (Entitlements) - FREE vs PREMIUM
class Entitlements {
  final bool isPremium;
  final DateTime? dataExpiracao;
  final DateTime? dataCompra;
  final String? productId;
  final String? planLabel;

  Entitlements({
    required this.isPremium,
    this.dataExpiracao,
    this.dataCompra,
    this.productId,
    this.planLabel,
  });

  bool get isActive {
    if (!isPremium) return false;
    if (dataExpiracao == null) return true;
    return DateTime.now().isBefore(dataExpiracao!);
  }

  Entitlements copyWith({
    bool? isPremium,
    DateTime? dataExpiracao,
    DateTime? dataCompra,
    String? productId,
    String? planLabel,
  }) {
    return Entitlements(
      isPremium: isPremium ?? this.isPremium,
      dataExpiracao: dataExpiracao ?? this.dataExpiracao,
      dataCompra: dataCompra ?? this.dataCompra,
      productId: productId ?? this.productId,
      planLabel: planLabel ?? this.planLabel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_premium': isPremium,
      'data_expiracao': dataExpiracao?.toIso8601String(),
      'data_compra': dataCompra?.toIso8601String(),
      'product_id': productId,
      'plan_label': planLabel,
    };
  }

  factory Entitlements.fromJson(Map<String, dynamic> json) {
    return Entitlements(
      isPremium: json['is_premium'] as bool? ?? false,
      dataExpiracao: json['data_expiracao'] != null
          ? DateTime.parse(json['data_expiracao'] as String)
          : null,
      dataCompra: json['data_compra'] != null
          ? DateTime.parse(json['data_compra'] as String)
          : null,
      productId: json['product_id'] as String?,
      planLabel: json['plan_label'] as String?,
    );
  }

  static Entitlements free() => Entitlements(isPremium: false);
}
