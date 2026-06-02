import 'package:intl/intl.dart';

class Dates {
  static String greeting(DateTime now) {
    final h = now.hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 19) return 'Selamat sore';
    return 'Selamat malam';
  }

  static String fullDate(DateTime d) =>
      DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(d);

  static String monthDay(DateTime d) =>
      DateFormat('d MMM', 'id_ID').format(d);

  static String hourMinute(DateTime d) => DateFormat('HH:mm').format(d);

  static String relative(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('d MMM yyyy', 'id_ID').format(d);
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

const dailyQuotes = [
  'Setiap hari adalah lembaran baru. Tulislah dengan penuh syukur.',
  'Tidak ada cerita yang terlalu kecil untuk dirayakan.',
  'Kebahagiaan tumbuh dari kebiasaan kecil yang konsisten.',
  'Hari ini, perlakukan dirimu seperti sahabat baik.',
  'Pikiran yang ditulis lebih ringan untuk dibawa pulang.',
  'Bertumbuh tidak selalu cepat, tapi selalu berarti.',
  'Tarik napas, lepaskan. Kamu sudah melakukannya dengan baik.',
];
