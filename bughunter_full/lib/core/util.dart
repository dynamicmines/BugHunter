/// Склонение числительных: plural(1, 'задача', 'задачи', 'задач') даёт «задача».
String plural(int n, String one, String few, String many) {
  final m100 = n % 100;
  final m10 = n % 10;
  if (m100 >= 11 && m100 <= 14) return many;
  if (m10 == 1) return one;
  if (m10 >= 2 && m10 <= 4) return few;
  return many;
}

String countText(int n, String one, String few, String many) =>
    '$n ${plural(n, one, few, many)}';
