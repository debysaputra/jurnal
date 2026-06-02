import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/companion.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/companion_avatar.dart';
import '../widgets/glass_card.dart';

/// Layar "Pilih Asisten" — memilih karakter pendamping AI.
/// Menyimpan pilihan ke [StorageService.selectedCompanionId].
class CompanionPickerScreen extends StatefulWidget {
  const CompanionPickerScreen({super.key});

  @override
  State<CompanionPickerScreen> createState() => _CompanionPickerScreenState();
}

class _CompanionPickerScreenState extends State<CompanionPickerScreen> {
  final _storage = StorageService.instance;
  late String _selectedId = _storage.selectedCompanionId;

  void _select(Companion c) {
    setState(() => _selectedId = c.id);
    _storage.selectedCompanionId = c.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Pilih Asisten'),
        centerTitle: true,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Setiap karakter punya kepribadian berbeda',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                ),
              ),
              Expanded(
                child: AnimationLimiter(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 350),
                      childAnimationBuilder: (w) => SlideAnimation(
                        verticalOffset: 20,
                        child: FadeInAnimation(child: w),
                      ),
                      children: Companion.all
                          .map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _CompanionCard(
                                  companion: c,
                                  selected: c.id == _selectedId,
                                  onTap: () => _select(c),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanionCard extends StatelessWidget {
  final Companion companion;
  final bool selected;
  final VoidCallback onTap;

  const _CompanionCard({
    required this.companion,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tint: selected ? companion.accent : Colors.white,
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      shadows: selected
          ? [
              BoxShadow(
                color: companion.accent.withValues(alpha: 0.5),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ]
          : null,
      child: Row(
        children: [
          CompanionAvatar(companion: companion, size: 64, selected: selected),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      companion.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        companion.role,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  companion.description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkSoft,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.check_circle_rounded, color: AppColors.ink),
            ),
        ],
      ),
    );
  }
}
