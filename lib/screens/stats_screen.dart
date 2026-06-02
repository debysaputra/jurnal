import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mood.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _storage = StorageService.instance;

  @override
  void initState() {
    super.initState();
    _storage.addListener(_onChange);
  }

  @override
  void dispose() {
    _storage.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final journals = _storage.allJournals;
    final now = DateTime.now();

    final weekData = List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
      final dayJ = journals
          .where((j) =>
              j.createdAt.year == day.year &&
              j.createdAt.month == day.month &&
              j.createdAt.day == day.day)
          .toList();
      if (dayJ.isEmpty) return _DayPoint(day, 0);
      final avg = dayJ.map((j) => Mood.values[j.moodIndex].score).reduce(
            (a, b) => a + b,
          ) /
          dayJ.length;
      return _DayPoint(day, avg);
    });

    final moodCount = <Mood, int>{for (final m in Mood.values) m: 0};
    for (final j in journals) {
      moodCount[Mood.values[j.moodIndex]] =
          (moodCount[Mood.values[j.moodIndex]] ?? 0) + 1;
    }

    final tagCount = <String, int>{};
    for (final j in journals) {
      for (final t in j.tags) {
        tagCount[t] = (tagCount[t] ?? 0) + 1;
      }
    }
    final topTags = tagCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Mood dominan ("Mood Terbanyak")
    final totalEntries = journals.length;
    Mood? domMood;
    var domCount = 0;
    moodCount.forEach((m, c) {
      if (c > domCount) {
        domCount = c;
        domMood = m;
      }
    });
    final domPct = totalEntries == 0 ? 0.0 : domCount / totalEntries;

    // "Pemicu Mood" — mood dominan per tag + porsinya
    final tagMood = <String, Map<Mood, int>>{};
    for (final j in journals) {
      final m = Mood.values[j.moodIndex];
      for (final t in j.tags) {
        (tagMood[t] ??= <Mood, int>{})[m] =
            ((tagMood[t]![m]) ?? 0) + 1;
      }
    }
    final totalTagHits = tagCount.values.fold<int>(0, (a, b) => a + b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 180),
      children: [
        const SizedBox(height: 8),
        const Text(
          'Statistik',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pantau perjalanan mood-mu',
          style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
        ),
        const SizedBox(height: 18),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mood 7 hari terakhir',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 5,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: AppColors.lavender.withValues(alpha: 0.25),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (v, meta) {
                            final i = v.toInt();
                            if (i < 0 || i >= weekData.length) {
                              return const SizedBox();
                            }
                            final d = weekData[i].day;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                DateFormat('E', 'id_ID').format(d)[0],
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.inkSoft,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          weekData.length,
                          (i) => FlSpot(i.toDouble(), weekData[i].score),
                        ),
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 3,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.lavender.withValues(alpha: 0.5),
                              AppColors.pink.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, _, _, _) =>
                              FlDotCirclePainter(
                            radius: 5,
                            color: Colors.white,
                            strokeColor: AppColors.primary,
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          tint: AppColors.lavender,
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
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: domPct,
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.primary),
                      ),
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
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Distribusi mood',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              ...Mood.values.map((m) {
                final count = moodCount[m] ?? 0;
                final total = journals.isEmpty ? 1 : journals.length;
                final pct = count / total;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Text(m.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  m.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 8,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.12),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(m.color),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          tint: AppColors.pink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pemicu mood',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Topik yang paling sering kamu tulis',
                style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
              ),
              const SizedBox(height: 14),
              if (topTags.isEmpty)
                const Text(
                  'Belum ada tag yang kamu gunakan.',
                  style: TextStyle(color: AppColors.inkSoft),
                )
              else
                ...topTags.take(5).map((e) {
                  final pct = totalTagHits == 0 ? 0.0 : e.value / totalTagHits;
                  final dom = _dominantMood(tagMood[e.key] ?? const {});
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Text(dom.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '#${e.key}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${(pct * 100).round()}%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 8,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.12),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(dom.color),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

Mood _dominantMood(Map<Mood, int> counts) {
  var best = Mood.neutral;
  var bestCount = -1;
  counts.forEach((mood, c) {
    if (c > bestCount) {
      bestCount = c;
      best = mood;
    }
  });
  return best;
}

class _DayPoint {
  final DateTime day;
  final double score;
  _DayPoint(this.day, this.score);
}
