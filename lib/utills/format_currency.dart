import 'package:intl/intl.dart';

// 기본 통화 포맷
final formatter = NumberFormat.currency(
  locale: 'ko_KR',
  symbol: '₩',
  decimalDigits: 0,
);

String formatCurrency(num amount) {
  if (amount >= 100000000) {
    return '${(amount / 100000000).toStringAsFixed(1)}억원';
  } else if (amount >= 10000) {
    return '${(amount / 10000).toStringAsFixed(0)}만원';
  } else if (amount >= 1000) {
    return '${(amount / 1000).toStringAsFixed(0)}천원';
  } else {
    return '${amount.toStringAsFixed(0)}원';
  }
}
