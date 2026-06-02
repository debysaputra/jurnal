import '../models/mood.dart';
import '../utils/dates.dart';
import 'storage_service.dart';

/// Merangkum data lokal (jurnal, mood, tag, to-do, streak) menjadi konteks
/// singkat yang disuntikkan ke AI — agar AI bisa mengingatkan & memberi saran
/// personal. Sengaja ringkas karena context window model kecil terbatas.
class AiContext {
  static String build() {
    final s = StorageService.instance;
    final now = DateTime.now();
    final journals = s.allJournals;

    final parts = <String>[];

    final streak = s.currentStreak;
    if (streak > 0) parts.add('streak menulis $streak hari berturut-turut');
    parts.add('${journals.length} jurnal total');

    if (journals.isNotEmpty) {
      parts.add('mood terakhir ${Mood.values[journals.first.moodIndex].label}');

      final tagCount = <String, int>{};
      for (final j in journals) {
        for (final t in j.tags) {
          tagCount[t] = (tagCount[t] ?? 0) + 1;
        }
      }
      if (tagCount.isNotEmpty) {
        final top = tagCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        parts.add(
            'sering menulis tentang ${top.take(2).map((e) => e.key).join(", ")}');
      }

      final j = journals.first;
      final title = j.title.trim().isEmpty ? 'tanpa judul' : j.title.trim();
      parts.add('jurnal terbaru "$title" (${Dates.relative(j.createdAt)})');
    }

    final todos = s.todosOn(now);
    if (todos.isNotEmpty) {
      final done = todos.where((t) => t.done).length;
      final undone =
          todos.where((t) => !t.done).map((t) => t.title).take(2).toList();
      final sisa =
          undone.isEmpty ? '' : ' (sisa: ${undone.join(", ")})';
      parts.add('to-do hari ini $done/${todos.length} selesai$sisa');
    }

    if (parts.isEmpty) return '';

    return 'Konteks tentang ${s.userName} (pakai untuk mengingatkan & memberi '
        'saran bila relevan, jangan dibacakan ulang apa adanya): '
        '${parts.join("; ")}.';
  }
}
