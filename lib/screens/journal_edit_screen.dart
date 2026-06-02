import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/companion.dart';
import '../models/journal_entry.dart';
import '../models/mood.dart';
import '../services/reflection_engine.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';
import '../widgets/companion_avatar.dart';
import '../widgets/glass_card.dart';

class JournalEditScreen extends StatefulWidget {
  final JournalEntry? entry;
  final Mood? initialMood;

  const JournalEditScreen({super.key, this.entry, this.initialMood});

  @override
  State<JournalEditScreen> createState() => _JournalEditScreenState();
}

class _JournalEditScreenState extends State<JournalEditScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  late TextEditingController _tagCtrl;
  late Mood _mood;
  late List<String> _tags;
  late List<String> _photos;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _contentCtrl = TextEditingController(text: e?.content ?? '');
    _tagCtrl = TextEditingController();
    _mood = e != null
        ? Mood.values[e.moodIndex]
        : (widget.initialMood ?? Mood.happy);
    _tags = List<String>.from(e?.tags ?? const []);
    _photos = List<String>.from(e?.photoPaths ?? const []);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final now = DateTime.now();
    final e = widget.entry;
    final entry = JournalEntry(
      id: e?.id ?? const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      moodIndex: _mood.index,
      tags: _tags,
      photoPaths: _photos,
      createdAt: e?.createdAt ?? now,
      updatedAt: now,
      favorite: e?.favorite ?? false,
    );
    await StorageService.instance.saveJournal(entry);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _addPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() => _photos.add(picked.path));
      }
    } catch (_) {}
  }

  void _addTag(String raw) {
    final t = raw.trim().replaceAll(RegExp(r'\s+'), '_').toLowerCase();
    if (t.isEmpty) return;
    if (!_tags.contains(t)) {
      setState(() => _tags.add(t));
    }
    _tagCtrl.clear();
  }

  Future<void> _delete() async {
    final e = widget.entry;
    if (e == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus jurnal?'),
        content: const Text('Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await StorageService.instance.deleteJournal(e.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.entry != null;
    final companion =
        Companion.byId(StorageService.instance.selectedCompanionId);
    final negativeMood = _mood == Mood.sad || _mood == Mood.angry;
    final assistantNote = ReflectionEngine.note(
      mood: _mood,
      content: _contentCtrl.text,
      tags: _tags,
      companion: companion,
    );
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit jurnal' : 'Tulis jurnal',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isEdit)
                      IconButton(
                        onPressed: _delete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                        ),
                      ),
                    FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Simpan'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    Text(
                      Dates.fullDate(widget.entry?.createdAt ?? DateTime.now()),
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GlassCard(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bagaimana perasaanmu?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkSoft,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: Mood.values.map((m) {
                              final sel = m == _mood;
                              return GestureDetector(
                                onTap: () => setState(() => _mood = m),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? m.color
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: sel
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      width: 1.4,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        m.emoji,
                                        style: TextStyle(
                                          fontSize: sel ? 32 : 26,
                                        ),
                                      ),
                                      Text(
                                        m.label,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: sel
                                              ? FontWeight.w800
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleCtrl,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Judul...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contentCtrl,
                      minLines: 8,
                      maxLines: 20,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 15, height: 1.5),
                      decoration: const InputDecoration(
                        hintText: 'Tuliskan ceritamu hari ini...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagCtrl,
                            onSubmitted: _addTag,
                            decoration: const InputDecoration(
                              hintText: 'Tambah tag... lalu Enter',
                              prefixIcon: Icon(Icons.tag_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags
                            .map((t) => Chip(
                                  label: Text('#$t'),
                                  onDeleted: () =>
                                      setState(() => _tags.remove(t)),
                                  deleteIcon: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    GlassCard(
                      tint: companion.accent,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CompanionAvatar(
                            companion: companion,
                            size: 40,
                            negative: negativeMood,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Catatan ${companion.name} · opsional',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  assistantNote,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.35,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _addPhoto(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_rounded),
                            label: const Text('Galeri'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _addPhoto(ImageSource.camera),
                            icon: const Icon(Icons.photo_camera_rounded),
                            label: const Text('Kamera'),
                          ),
                        ),
                      ],
                    ),
                    if (_photos.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _photos.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (_, i) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  File(_photos[i]),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _photos.removeAt(i)),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
