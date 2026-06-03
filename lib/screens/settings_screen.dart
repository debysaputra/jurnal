import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/companion.dart';
import '../services/achievement_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/companion_avatar.dart';
import '../widgets/glass_card.dart';
import '../widgets/user_avatar.dart';
import 'achievements_screen.dart';
import 'companion_picker_screen.dart';
import 'offline_ai_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = StorageService.instance;
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: _storage.userName);
    _storage.addListener(_onChange);
  }

  @override
  void dispose() {
    _storage.removeListener(_onChange);
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onChange() => setState(() {});

  Future<void> _pickAvatar() async {
    final hasAvatar = _storage.avatarPath != null;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inkSoft.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Foto profil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.lavender.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded),
              ),
              title: const Text(
                'Pilih dari galeri',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.peach.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_camera_rounded),
              ),
              title: const Text(
                'Ambil dari kamera',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            if (hasAvatar)
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                ),
                title: const Text(
                  'Hapus foto',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ],
        ),
      ),
    );

    if (choice == null) return;
    if (choice == 'remove') {
      await _storage.setAvatarPath(null);
      return;
    }
    final source =
        choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked != null) {
        await _storage.setAvatarPath(picked.path);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa membuka kamera/galeri'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _storage.reminderHour,
        minute: _storage.reminderMinute,
      ),
    );
    if (t != null) {
      await _storage.setReminderTime(t.hour, t.minute);
      if (_storage.reminderEnabled) {
        await NotificationService.instance.scheduleDaily(t.hour, t.minute);
      }
    }
  }

  Future<void> _toggleReminder(bool v) async {
    _storage.reminderEnabled = v;
    if (v) {
      await NotificationService.instance.scheduleDaily(
        _storage.reminderHour,
        _storage.reminderMinute,
      );
    } else {
      await NotificationService.instance.cancelAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hour = _storage.reminderHour.toString().padLeft(2, '0');
    final min = _storage.reminderMinute.toString().padLeft(2, '0');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 180),
      children: [
        const SizedBox(height: 8),
        const Text(
          'Profil & Pengaturan',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Row(
            children: [
              UserAvatar(
                size: 72,
                fontSize: 30,
                showEditBadge: true,
                onTap: _pickAvatar,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _storage.userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_storage.allJournals.length} entri jurnal',
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.camera_alt_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Ganti foto',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _SectionLabel('Progres'),
        GlassCard(
          tint: AppColors.mint,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AchievementsScreen(),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Text('🏅', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pencapaian',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AchievementService.instance.unlockedCount()} terbuka  ·  '
                      'streak ${_storage.currentStreak} hari',
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.inkSoft),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _SectionLabel('Akun'),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nama panggilan',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                onSubmitted: (v) =>
                    _storage.userName = v.trim().isEmpty ? 'Sahabat' : v.trim(),
                decoration: const InputDecoration(
                  hintText: 'Tulis namamu...',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final v = _nameCtrl.text.trim();
                    _storage.userName = v.isEmpty ? 'Sahabat' : v;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tersimpan ✨'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _SectionLabel('AI Pendamping'),
        Builder(builder: (context) {
          final companion =
              Companion.byId(_storage.selectedCompanionId);
          return GlassCard(
            tint: companion.accent,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CompanionPickerScreen(),
              ),
            ),
            child: Row(
              children: [
                CompanionAvatar(companion: companion, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companion.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        companion.role,
                        style: const TextStyle(
                          color: AppColors.inkSoft,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Ganti Karakter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        GlassCard(
          tint: AppColors.lavender,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const OfflineAiScreen(),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Text('🤖', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Chat AI (Gemini)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 6),
                        _BetaTag(),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ngobrol dengan asisten pintar (online)',
                      style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.inkSoft),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _SectionLabel('Pengingat harian'),
        GlassCard(
          tint: AppColors.peach,
          child: Column(
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Aktifkan pengingat',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Notifikasi setiap hari'),
                value: _storage.reminderEnabled,
                activeTrackColor: AppColors.primary,
                onChanged: _toggleReminder,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: _pickTime,
                leading: const Icon(Icons.alarm_rounded),
                title: const Text(
                  'Waktu pengingat',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: Text(
                  '$hour:$min',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _SectionLabel('Tentang'),
        GlassCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.menu_book_rounded),
                title: const Text(
                  'MyJurnal',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text('Versi 1.0.0'),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.favorite_rounded, color: Colors.redAccent),
                title: Text(
                  'Dibuat dengan Flutter',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Tetap konsisten menulis, sahabat.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BetaTag extends StatelessWidget {
  const _BetaTag();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'BETA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.3,
            fontWeight: FontWeight.w800,
            color: AppColors.inkSoft,
          ),
        ),
      );
}
