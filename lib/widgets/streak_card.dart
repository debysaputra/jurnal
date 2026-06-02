import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

/// Kartu streak harian untuk Beranda. Semua lokal dari data jurnal.
class StreakCard extends StatelessWidget {
  final VoidCallback? onTap;
  const StreakCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = StorageService.instance;
    final streak = s.currentStreak;
    final best = s.longestStreak;
    final wroteToday = s.journalsOn(DateTime.now()).isNotEmpty;

    final String message;
    if (streak == 0) {
      message = 'Mulai streak-mu hari ini ✨';
    } else if (!wroteToday) {
      message = 'Tulis hari ini agar streak tak terputus!';
    } else if (streak == 1) {
      message = 'Awal yang bagus, lanjutkan besok 🌱';
    } else {
      message = 'Kamu menulis $streak hari berturut-turut 🌸';
    }

    return GlassCard(
      tint: AppColors.peach,
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(
              streak > 0 ? '🔥' : '🌱',
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$streak',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 3),
                      child: Text(
                        'hari streak',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkSoft,
                    height: 1.3,
                  ),
                ),
                if (best > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Rekor terbaik: $best hari',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.inkSoft.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
        ],
      ),
    );
  }
}
