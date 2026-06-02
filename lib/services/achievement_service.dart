import 'storage_service.dart';

/// Satu pencapaian. `current`/`target` dihitung dari data lokal,
/// jadi status terkunci/terbuka selalu sinkron dengan jurnal user.
class Achievement {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final int current;
  final int target;

  const Achievement({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.current,
    required this.target,
  });

  bool get unlocked => current >= target;

  /// 0.0–1.0 untuk progress bar.
  double get progress => target == 0 ? 1 : (current / target).clamp(0.0, 1.0);

  /// Teks progres, mis. "3/7".
  String get progressLabel => '${current.clamp(0, target)}/$target';
}

/// Membangun daftar achievement dari data lokal (tanpa server).
class AchievementService {
  AchievementService._();
  static final AchievementService instance = AchievementService._();

  List<Achievement> all() {
    final s = StorageService.instance;
    final total = s.totalJournals;
    final best = s.longestStreak; // pakai streak terbaik agar badge tak hilang
    final moods = s.distinctMoodsUsed;
    final favs = s.favoriteCount;

    return [
      Achievement(
        id: 'first_entry',
        emoji: '✍️',
        title: 'Langkah Pertama',
        description: 'Menulis jurnal pertamamu',
        current: total,
        target: 1,
      ),
      Achievement(
        id: 'streak_3',
        emoji: '🔥',
        title: 'Konsisten 3 Hari',
        description: 'Menulis 3 hari berturut-turut',
        current: best,
        target: 3,
      ),
      Achievement(
        id: 'streak_7',
        emoji: '🌸',
        title: 'Seminggu Penuh',
        description: 'Menulis 7 hari berturut-turut',
        current: best,
        target: 7,
      ),
      Achievement(
        id: 'streak_30',
        emoji: '🏆',
        title: 'Sebulan Setia',
        description: 'Menulis 30 hari berturut-turut',
        current: best,
        target: 30,
      ),
      Achievement(
        id: 'entries_50',
        emoji: '⭐',
        title: 'Penulis Rajin',
        description: 'Mengumpulkan 50 entri jurnal',
        current: total,
        target: 50,
      ),
      Achievement(
        id: 'entries_100',
        emoji: '📚',
        title: 'Seratus Cerita',
        description: 'Mengumpulkan 100 entri jurnal',
        current: total,
        target: 100,
      ),
      Achievement(
        id: 'all_moods',
        emoji: '🎭',
        title: 'Mood Tracker Master',
        description: 'Mencatat kelima jenis mood',
        current: moods,
        target: 5,
      ),
      Achievement(
        id: 'favorites_10',
        emoji: '💖',
        title: 'Kolektor Kenangan',
        description: 'Menandai 10 jurnal favorit',
        current: favs,
        target: 10,
      ),
    ];
  }

  int unlockedCount() => all().where((a) => a.unlocked).length;
}
