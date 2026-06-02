import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../services/achievement_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
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
    final items = AchievementService.instance.all();
    final unlocked = items.where((a) => a.unlocked).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Pencapaian'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: AnimationLimiter(
            child: GridView.count(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.82,
              children: [
                _HeaderCard(unlocked: unlocked, total: items.length),
                ...AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 400),
                  childAnimationBuilder: (w) => ScaleAnimation(
                    scale: 0.92,
                    child: FadeInAnimation(child: w),
                  ),
                  children: items.map((a) => _BadgeCard(a)).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final int unlocked;
  final int total;
  const _HeaderCard({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tint: AppColors.lavender,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏅', style: TextStyle(fontSize: 30)),
          const SizedBox(height: 8),
          Text(
            '$unlocked / $total',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const Text(
            'pencapaian terbuka',
            style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : unlocked / total,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final Achievement a;
  const _BadgeCard(this.a);

  @override
  Widget build(BuildContext context) {
    final unlocked = a.unlocked;
    return GlassCard(
      tint: unlocked ? AppColors.mint : Colors.white,
      padding: const EdgeInsets.all(14),
      child: Opacity(
        opacity: unlocked ? 1 : 0.55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  a.emoji,
                  style: TextStyle(
                    fontSize: 30,
                    color: unlocked ? null : Colors.grey,
                  ),
                ),
                Icon(
                  unlocked
                      ? Icons.check_circle_rounded
                      : Icons.lock_outline_rounded,
                  size: 18,
                  color: unlocked ? AppColors.ink : AppColors.inkSoft,
                ),
              ],
            ),
            const Spacer(),
            Text(
              a.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              a.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 8),
            if (!unlocked) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: a.progress,
                  minHeight: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.lavender),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                a.progressLabel,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
            ] else
              const Text(
                'Terbuka ✓',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
