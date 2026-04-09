import 'dart:math';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import 'package:tradexpro_flutter/utils/language_util.dart';

int makeInt(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return int.parse(value);
  } else if (value is double) {
    return value.toInt();
  } else if (value is int) {
    return value;
  } else if (value is bool) {
    return value ? 1 : 0;
  }
  return 0;
}

double makeDouble(dynamic value) {
  if (value == null) {
    return 0.0;
  }
  if (value is String && value.isNotEmpty) {
    try {
      return double.parse(value);
    } catch (e) {
      var list = value.split(" ");
      if (list.isNotEmpty) {
        return double.parse(list.first.isEmpty ? "0" : list.first);
      }
    }
  } else if (value is int) {
    return value.toDouble();
  } else if (value is double) {
    return value;
  }
  return 0.0;
}

double makeDoubleFixedDeci(dynamic value, int decimal) {
  if (value == null) return 0.0;
  double dValue = double.parse(value.toString());
  final factor = pow(10, decimal);
  return (dValue * factor).truncate() / factor;
}

Decimal makeDecimal(dynamic value) {
  if (value == null) {
    return Decimal.zero;
  }
  if (value is String && value.isNotEmpty) {
    value = value.replaceAll(",", '');
    try {
      return Decimal.parse(value);
    } catch (e) {
      RegExp regex = RegExp(r'[-+]?\d*\.?\d+'); // Match numbers with decimals and signs
      Match? match = regex.firstMatch(value);
      if (match != null) {
        return Decimal.parse(match.group(0)!);
      }
    }
  } else if (value is int) {
    return Decimal.fromInt(value);
  } else if (value is double) {
    return Decimal.parse(value.toString());
  }
  return Decimal.zero;
}

String distanceFormat(dynamic distance) {
  String distanceStr = "0";
  if (distance != null) {
    var kmDis = makeDouble(distance);
    distanceStr = kmDis < 1 ? "1" : kmDis.toStringAsFixed(2);
  }
  return "$distanceStr KM";
}

String coinFormat(num? number, {int fixed = 8}) {
  if (number != null) {
    final numberStr = number.toStringAsFixed(fixed);
    final value = numberStr.replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "");
    return value == "0" ? "0.0" : value;
  }
  return "0.0";
}

String currencyFormat(num? number, {String name = "", int fixed = 3}) {
  if (number != null) {
    final numberStr = NumberFormat.simpleCurrency(locale: LanguageUtil.getCurrentKey(), name: name, decimalDigits: fixed).format(number);
    final value = numberStr.replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "");
    return value == "0" ? "0.0" : value;
  }
  return "${name}0.0";
}

String numberFormatCompact(num? number, {String symbol = "", int? decimals}) {
  if (number != null) {
    return NumberFormat.compactCurrency(locale: "en", symbol: symbol, decimalDigits: decimals).format(number);
  }
  return "${symbol}0.0";
}

String getRandomNumbers({int length = 8}) {
  var rdNumber = "";
  for (var i = 0; i < length; i++) {
    rdNumber = rdNumber + Random().nextInt(9).toString();
  }
  return rdNumber;
}

double getPercentageValue(num? value, num? percentage) {
  if (value != null && percentage != null) {
    return (value * percentage) / 100;
  }
  return 0;
}

String twoDigitInt(int? value) {
  if (value != null) {
    String str = value.toString();
    str = str.length == 1 ? ("0$str") : str;
    return str;
  }
  return "00";
}

bool isNegativeNum(dynamic number) {
  final numberD = makeDouble(number);
  return numberD.isNegative;
}
