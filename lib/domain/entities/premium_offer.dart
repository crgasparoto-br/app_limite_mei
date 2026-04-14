import 'dart:ui';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:intl/intl.dart';

enum PremiumPlanType { monthly, annual, lifetime }

class PremiumOffer {
  const PremiumOffer({
    required this.id,
    required this.title,
    required this.totalPriceLabel,
    required this.type,
    this.subtitle,
    this.badge,
    this.breakdownPriceLabel,
    this.chargeLabel,
  });

  final String id;
  final String title;
  final String totalPriceLabel;
  final PremiumPlanType type;
  final String? subtitle;
  final String? badge;
  final String? breakdownPriceLabel;
  final String? chargeLabel;

  bool get isSubscription => type != PremiumPlanType.lifetime;

  String get actionLabel => isSubscription ? 'Assinar' : 'Comprar';

  String get purchaseTypeLabel =>
      isSubscription ? 'Assinatura' : 'Compra única';

  String get effectiveChargeLabel {
    if (chargeLabel != null) return chargeLabel!;

    switch (type) {
      case PremiumPlanType.monthly:
        return 'cobrado por mês';
      case PremiumPlanType.annual:
        return 'cobrado por ano';
      case PremiumPlanType.lifetime:
        return 'pagamento único';
    }
  }

  String get termsSummary {
    switch (type) {
      case PremiumPlanType.monthly:
        return '$totalPriceLabel por mês com renovação automática até cancelamento.';
      case PremiumPlanType.annual:
        final breakdown = breakdownPriceLabel == null
            ? ''
            : ' ($breakdownPriceLabel)';
        return '$totalPriceLabel por ano$breakdown com renovação automática até cancelamento.';
      case PremiumPlanType.lifetime:
        return '$totalPriceLabel em pagamento único, sem renovação automática.';
    }
  }

  PremiumOffer copyWith({
    String? id,
    String? title,
    String? totalPriceLabel,
    PremiumPlanType? type,
    String? subtitle,
    String? badge,
    String? breakdownPriceLabel,
    String? chargeLabel,
  }) {
    return PremiumOffer(
      id: id ?? this.id,
      title: title ?? this.title,
      totalPriceLabel: totalPriceLabel ?? this.totalPriceLabel,
      type: type ?? this.type,
      subtitle: subtitle ?? this.subtitle,
      badge: badge ?? this.badge,
      breakdownPriceLabel: breakdownPriceLabel ?? this.breakdownPriceLabel,
      chargeLabel: chargeLabel ?? this.chargeLabel,
    );
  }

  PremiumOffer resolveWithProduct(ProductDetails? product) {
    if (product == null) return this;

    if (type == PremiumPlanType.lifetime) {
      return copyWith(
        totalPriceLabel: product.price,
        chargeLabel: 'pagamento único',
      );
    }

    if (product is GooglePlayProductDetails &&
        product.subscriptionIndex != null &&
        product.productDetails.subscriptionOfferDetails != null) {
      final subscriptionDetails = product
          .productDetails
          .subscriptionOfferDetails![product.subscriptionIndex!];
      final pricingPhase = subscriptionDetails.pricingPhases.last;
      final recurringPrice = pricingPhase.priceAmountMicros / 1000000.0;
      final commitment = subscriptionDetails.installmentPlanDetails;

      if (commitment != null && commitment.commitmentPaymentsCount > 1) {
        final total = recurringPrice * commitment.commitmentPaymentsCount;
        return copyWith(
          totalPriceLabel: _formatCurrency(
            total,
            currencyCode: pricingPhase.priceCurrencyCode,
            currencySymbol: product.currencySymbol,
          ),
          breakdownPriceLabel:
              '${commitment.commitmentPaymentsCount}x de ${pricingPhase.formattedPrice}',
          chargeLabel:
              'compromisso anual em ${commitment.commitmentPaymentsCount} parcelas',
        );
      }

      if (pricingPhase.billingPeriod == 'P1Y') {
        return copyWith(
          totalPriceLabel: pricingPhase.formattedPrice,
          breakdownPriceLabel:
              'equivale a ${_formatCurrency(recurringPrice / 12, currencyCode: pricingPhase.priceCurrencyCode, currencySymbol: product.currencySymbol)} por mês',
          chargeLabel: 'cobrado por ano',
        );
      }

      if (pricingPhase.billingPeriod == 'P1M') {
        return copyWith(
          totalPriceLabel: pricingPhase.formattedPrice,
          chargeLabel: 'cobrado por mês',
        );
      }
    }

    return copyWith(totalPriceLabel: product.price);
  }

  DateTime? expirationFrom(DateTime purchaseDate) {
    switch (type) {
      case PremiumPlanType.monthly:
        return DateTime(
          purchaseDate.year,
          purchaseDate.month + 1,
          purchaseDate.day,
          purchaseDate.hour,
          purchaseDate.minute,
          purchaseDate.second,
          purchaseDate.millisecond,
          purchaseDate.microsecond,
        );
      case PremiumPlanType.annual:
        return DateTime(
          purchaseDate.year + 1,
          purchaseDate.month,
          purchaseDate.day,
          purchaseDate.hour,
          purchaseDate.minute,
          purchaseDate.second,
          purchaseDate.millisecond,
          purchaseDate.microsecond,
        );
      case PremiumPlanType.lifetime:
        return null;
    }
  }

  String get planLabel {
    switch (type) {
      case PremiumPlanType.monthly:
        return 'Mensal';
      case PremiumPlanType.annual:
        return 'Anual';
      case PremiumPlanType.lifetime:
        return 'Vitalício';
    }
  }

  static String _formatCurrency(
    double value, {
    required String currencyCode,
    required String currencySymbol,
  }) {
    final locale =
        Intl.defaultLocale ?? PlatformDispatcher.instance.locale.toString();
    final formatter = NumberFormat.currency(
      locale: locale.isEmpty ? 'pt_BR' : locale,
      name: currencyCode,
      symbol: currencySymbol,
      decimalDigits: 2,
    );

    return formatter.format(value).replaceAll('\u00A0', ' ');
  }
}
