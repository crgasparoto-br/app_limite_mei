import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/src/l10n/generated_material_localizations.dart';
import 'package:intl/intl.dart' as intl;

class CustomMaterialLocalizationsPtBr extends MaterialLocalizationPt {
  CustomMaterialLocalizationsPtBr({
    required super.localeName,
    required super.fullYearFormat,
    required super.compactDateFormat,
    required super.shortDateFormat,
    required super.mediumDateFormat,
    required super.longDateFormat,
    required super.yearMonthFormat,
    required super.shortMonthDayFormat,
    required super.decimalFormat,
    required super.twoDigitZeroPaddedFormat,
  });

  static const List<String> _shortWeekdays = <String>[
    'seg',
    'ter',
    'qua',
    'qui',
    'sex',
    'sáb',
    'dom',
  ];

  static const List<String> _shortMonths = <String>[
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];

  static const List<String> _narrowWeekdays = <String>[
    'D',
    'S',
    'T',
    'Q',
    'Q',
    'S',
    'S',
  ];

  static Future<CustomMaterialLocalizationsPtBr> load(Locale locale) {
    final localeName = intl.Intl.canonicalizedLocale(locale.toString());

    return SynchronousFuture(
      CustomMaterialLocalizationsPtBr(
        localeName: localeName,
        fullYearFormat: intl.DateFormat.y(localeName),
        compactDateFormat: intl.DateFormat.yMd(localeName),
        shortDateFormat: intl.DateFormat('dd/MM/yyyy', localeName),
        mediumDateFormat: intl.DateFormat.yMMMd(localeName),
        longDateFormat: intl.DateFormat.yMMMMEEEEd(localeName),
        yearMonthFormat: intl.DateFormat.yMMMM(localeName),
        shortMonthDayFormat: intl.DateFormat.MMMd(localeName),
        decimalFormat: intl.NumberFormat.decimalPattern(localeName),
        twoDigitZeroPaddedFormat: intl.NumberFormat('00', localeName),
      ),
    );
  }

  @override
  List<String> get narrowWeekdays => _narrowWeekdays;

  @override
  String formatMediumDate(DateTime date) {
    final weekday = _shortWeekdays[date.weekday - DateTime.monday];
    final month = _shortMonths[date.month - DateTime.january];
    return '$weekday, ${date.day} de $month';
  }

  @override
  String formatShortMonthDay(DateTime date) {
    final month = _shortMonths[date.month - DateTime.january];
    return '${date.day} de $month';
  }
}

class CustomMaterialLocalizationsPtBrDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const CustomMaterialLocalizationsPtBrDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'pt' && locale.countryCode == 'BR';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      CustomMaterialLocalizationsPtBr.load(locale);

  @override
  bool shouldReload(CustomMaterialLocalizationsPtBrDelegate old) => false;
}
