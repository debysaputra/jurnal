import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Karakter pendamping AI. Persona hanya mengubah `systemInstruction` model;
/// `accent`/`emoji` untuk tampilan (avatar placeholder).
class Companion {
  final String id;
  final String name;
  final String emoji;
  final String role;
  final String description;
  final Color accent;

  /// Path aset gambar avatar (anime). Bila file belum ada, avatar otomatis
  /// jatuh ke emoji. Taruh file di `assets/images/characters/{id}.png`
  final String imageAsset;

  /// Portrait penuh untuk header chat (opsional).
  final String? portraitAsset;

  /// Ekspresi alternatif (mis. kesal/sedih) untuk mood negatif (opsional).
  final String? altAsset;

  final String systemInstruction;

  const Companion({
    required this.id,
    required this.name,
    required this.emoji,
    required this.role,
    required this.description,
    required this.accent,
    required this.systemInstruction,
    String? imageAsset,
    this.portraitAsset,
    this.altAsset,
  }) : imageAsset = imageAsset ?? 'assets/images/characters/$id.png';

  /// Aset avatar sesuai konteks: ekspresi alternatif bila [negative] & tersedia.
  String avatarAsset({bool negative = false}) =>
      (negative && altAsset != null) ? altAsset! : imageAsset;

  /// Portrait (header chat) sesuai ekspresi; alt bila [negative] & tersedia.
  String? portraitFor({bool negative = false}) =>
      (negative && altAsset != null) ? altAsset : portraitAsset;

  bool get hasPortrait => portraitAsset != null;

  /// Pengingat singkat yang diselipkan tiap giliran agar model kecil
  /// tetap memegang karakter (system instruction saja sering "lupa").
  String get chatReminder =>
      '(Ingat: kamu $name, $role. Jawab dalam Bahasa Indonesia, singkat, dan '
      'tetap dalam karakter.)';

  static const all = [freya];

  static Companion byId(String? id) =>
      all.firstWhere((c) => c.id == id, orElse: () => freya);

  static const _safety =
      'Selalu menjawab dalam Bahasa Indonesia, singkat (2–4 kalimat), dan '
      'TETAP dalam karakter. Jangan pernah mengaku sebagai AI, model, asisten '
      'virtual, atau program — kamu benar-benar tokoh tersebut. '
      'Kamu bukan terapis; untuk topik berat (menyakiti diri, dsb.) tanggapi '
      'dengan empati dan sarankan bantuan profesional.';

  static const freya = Companion(
    id: 'freya',
    name: 'Freya',
    emoji: '🔥',
    role: 'Teman Ceria',
    description: 'Ceria dan jujur—senyumnya menular, tapi jangan bikin dia kesal ya.',
    accent: AppColors.pink,
    imageAsset: 'assets/images/characters/freya/happy.png',
    portraitAsset: 'assets/images/characters/freya/happy.png',
    altAsset: 'assets/images/characters/freya/mad.png',
    systemInstruction:
        'Kamu adalah Freya, teman yang ceria, jujur, dan ekspresif di aplikasi '
        'jurnal MyJurnal. Hangat dan menyemangati, sesekali usil. $_safety',
  );
}
