import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/journal_entry.dart';
import '../models/mood.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';
import '../widgets/glass_card.dart';
import 'journal_edit_screen.dart';

class JournalListScreen extends StatefulWidget {
  const JournalListScreen({super.key});
  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> {
  final _storage = StorageService.instance;
  final _searchCtrl = TextEditingController();
  Mood? _moodFilter;
  String? _tagFilter;

  @override
  void initState() {
    super.initState();
    _storage.addListener(_onChange);
  }

  @override
  void dispose() {
    _storage.removeListener(_onChange);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChange() => setState(() {});

  List<JournalEntry> get _filtered {
    var list = _storage.allJournals;
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((e) =>
              e.title.toLowerCase().contains(q) ||
              e.content.toLowerCase().contains(q))
          .toList();
    }
    if (_moodFilter != null) {
      list = list.where((e) => e.moodIndex == _moodFilter!.index).toList();
    }
    if (_tagFilter != null) {
      list = list.where((e) => e.tags.contains(_tagFilter)).toList();
    }
    return list;
  }

  Set<String> get _allTags => {
        for (final j in _storage.allJournals) ...j.tags,
      };

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 180),
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Jurnal saya',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            GlassCard(
              padding: const EdgeInsets.all(10),
              borderRadius: 14,
              child: Text(
                '${_storage.allJournals.length} entri',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Cari jurnal...',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'Semua',
                selected: _moodFilter == null && _tagFilter == null,
                onTap: () => setState(() {
                  _moodFilter = null;
                  _tagFilter = null;
                }),
              ),
              const SizedBox(width: 8),
              ...Mood.values.map((m) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: '${m.emoji} ${m.label}',
                      selected: _moodFilter == m,
                      onTap: () => setState(() {
                        _moodFilter = _moodFilter == m ? null : m;
                      }),
                    ),
                  )),
              ..._allTags.map((t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: '#$t',
                      selected: _tagFilter == t,
                      onTap: () => setState(() {
                        _tagFilter = _tagFilter == t ? null : t;
                      }),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            child: Column(
              children: [
                const Text('📖', style: TextStyle(fontSize: 42)),
                const SizedBox(height: 10),
                const Text(
                  'Belum ada jurnal sesuai filter',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tekan tombol Tulis untuk mulai mencatat.',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          AnimationLimiter(
            child: Column(
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 400),
                childAnimationBuilder: (w) => SlideAnimation(
                  verticalOffset: 30,
                  child: FadeInAnimation(child: w),
                ),
                children: items
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _JournalCard(entry: e),
                        ))
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final JournalEntry entry;
  const _JournalCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final mood = Mood.values[entry.moodIndex];
    return GlassCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JournalEditScreen(entry: entry),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: mood.color.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(mood.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title.isEmpty ? 'Tanpa judul' : entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Dates.fullDate(entry.createdAt),
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => StorageService.instance.toggleFavorite(entry.id),
                icon: Icon(
                  entry.favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  color: entry.favorite ? Colors.redAccent : AppColors.inkSoft,
                ),
              ),
            ],
          ),
          if (entry.content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entry.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.inkSoft,
                height: 1.4,
                fontSize: 13.5,
              ),
            ),
          ],
          if (entry.photoPaths.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: entry.photoPaths.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final p = entry.photoPaths[i];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(p),
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 76,
                        height: 76,
                        color: AppColors.lavender.withValues(alpha: 0.3),
                        child: const Icon(Icons.broken_image_rounded),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (entry.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: entry.tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lavender.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '#$t',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
