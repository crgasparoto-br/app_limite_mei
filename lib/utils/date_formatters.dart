import 'package:intl/intl.dart';

class DateFormatters {
  static final DateFormat _date = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final DateFormat _dateTime = DateFormat(
    "dd/MM/yyyy 'às' HH:mm",
    'pt_BR',
  );

  static String date(DateTime value) => _date.format(value);

  static String dateTime(DateTime value) => _dateTime.format(value);
}
