import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/companion.dart';
import '../models/mood.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';
import '../widgets/companion_avatar.dart';
import '../widgets/glass_card.dart';
import '../widgets/streak_card.dart';
import '../widgets/user_avatar.dart';
import 'achievements_screen.dart';
import 'companion_picker_screen.dart';
import 'journal_edit_screen.dart';
import 'offline_ai_screen.dart';
import 'root_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _storage = StorageService.instance;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _storage.addListener(_onChange);
    WidgetsBinding.instance.addObserver(this);
    // Segarkan greeting/data "hari ini" tiap menit agar selalu sesuai waktu.
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _storage.removeListener(_onChange);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = Dates.greeting(now);
    final dateStr = Dates.fullDate(now);
    final entriesToday = _storage.journalsOn(now);
    final todosToday = _storage.todosOn(now);
    final doneTodos = todosToday.where((t) => t.done).length;
    final quote = dailyQuotes[now.day % dailyQuotes.length];
    final allJournals = _storage.allJournals;
    final lastMood = allJournals.isEmpty
        ? null
        : Mood.values[allJournals.first.moodIndex];

    // Mood dominan untuk ringkasan statistik di beranda.
    final moodCount = <Mood, int>{for (final m in Mood.values) m: 0};
    for (final j in allJournals) {
      final m = Mood.values[j.moodIndex];
      moodCount[m] = moodCount[m]! + 1;
    }
    Mood? domMood;
    var domCount = 0;
    moodCount.forEach((m, c) {
      if (c > domCount) {
        domCount = c;
        domMood = m;
      }
    });
    final domPct = allJournals.isEmpty ? 0.0 : domCount / allJournals.length;

    return AnimationLimiter(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 180),
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 450),
          childAnimationBuilder: (w) => SlideAnimation(
            verticalOffset: 24,
            child: FadeInAnimation(child: w),
          ),
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting,',
                        style: const TextStyle(
                          color: AppColors.inkSoft,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _storage.userName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: AppColors.inkSoft,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    UserAvatar(
                      size: 56,
                      fontSize: 24,
                      onTap: () {
                        RootScreen.of(context)?.goTo(4);
                      },
                    ),
                    if (lastMood != null)
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: lastMood.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            lastMood.emoji,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            StreakCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AchievementsScreen(),
                ),
              ),
            ),
            const SizedBox(height: 18),
            GlassCard(
              tint: AppColors.peach,
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✨', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quote hari ini',
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          quote,
                          style: const TextStyle(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            color: AppColors.ink,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    icon: Icons.menu_book_rounded,
                    label: 'Jurnal\nhari ini',
                    value: entriesToday.length.toString(),
                    tint: AppColors.lavender,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.check_circle_rounded,
                    label: 'To-Do\nselesai',
                    value: '$doneTodos/${todosToday.length}',
                    tint: AppColors.mint,
                    onTap: () => RootScreen.of(context)?.goTo(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.favorite_rounded,
                    label: 'Total\njurnal',
                    value: _storage.allJournals.length.toString(),
                    tint: AppColors.pink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Karakter Asisten',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CompanionPickerScreen(),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Lihat semua',
                        style: TextStyle(
                          color: AppColors.inkSoft,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: AppColors.inkSoft),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: Companion.all.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (_, i) {
                  final c = Companion.all[i];
                  final selected = c.id == _storage.selectedCompanionId;
                  return SizedBox(
                    width: 68,
                    child: Column(
                      children: [
                        CompanionAvatar(
                          companion: c,
                          size: 58,
                          selected: selected,
                          onTap: () => _openChatWith(c),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          c.role,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.5,
                            height: 1.1,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Catat mood-mu sekarang',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: Mood.values
                    .map((m) => _MoodPick(
                          mood: m,
                          onTap: () => _quickJournal(m),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Statistik',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                GestureDetector(
                  onTap: _openStats,
                  child: const Row(
                    children: [
                      Text(
                        'Lihat semua',
                        style: TextStyle(
                          color: AppColors.inkSoft,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: AppColors.inkSoft),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GlassCard(
              tint: AppColors.lavender,
              onTap: _openStats,
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: (domMood?.color ?? AppColors.inkSoft)
                          .withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      domMood?.emoji ?? '🫥',
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MOOD TERBANYAK',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w800,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          domMood?.label ?? 'Belum ada data',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: domPct,
                          strokeWidth: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                        Text(
                          '${(domPct * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aktivitas terbaru',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            if (_storage.allJournals.isEmpty)
              GlassCard(
                child: Column(
                  children: [
                    const Text('🌱', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    const Text(
                      'Belum ada jurnal',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Mulai tuangkan ceritamu hari ini.',
                      style: TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const JournalEditScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Tulis sekarang'),
                    ),
                  ],
                ),
              )
            else
              ..._storage.allJournals.take(3).map(
                    (j) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => JournalEditScreen(entry: j),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Mood.values[j.moodIndex]
                                    .color
                                    .withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                Mood.values[j.moodIndex].emoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    j.title.isEmpty
                                        ? 'Tanpa judul'
                                        : j.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    Dates.relative(j.createdAt),
                                    style: const TextStyle(
                                      color: AppColors.inkSoft,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.inkSoft,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _openStats() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(backgroundColor: Colors.transparent),
          body: const GradientBackground(
            child: SafeArea(child: StatsScreen()),
          ),
        ),
      ),
    );
  }

  void _openChatWith(Companion c) {
    _storage.selectedCompanionId = c.id;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OfflineAiScreen()),
    );
  }

  Future<void> _quickJournal(Mood m) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JournalEditScreen(initialMood: m),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  final VoidCallback? onTap;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tint: tint,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.ink),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              height: 1.2,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodPick extends StatelessWidget {
  final Mood mood;
  final VoidCallback onTap;
  const _MoodPick({required this.mood, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: mood.color.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(mood.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: 6),
          Text(
            mood.label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
