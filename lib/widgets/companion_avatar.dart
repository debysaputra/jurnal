import 'package:flutter/material.dart';
import '../models/companion.dart';

/// Avatar placeholder untuk karakter pendamping.
/// Lingkaran beraksen warna + emoji karakter. Nanti bisa diganti gambar asli
/// dengan menaruh aset & menambah field `imagePath` di [Companion].
class CompanionAvatar extends StatelessWidget {
  final Companion companion;
  final double size;
  final bool selected;
  final VoidCallback? onTap;

  /// Pakai ekspresi alternatif (mis. saat mood negatif).
  final bool negative;

  const CompanionAvatar({
    super.key,
    required this.companion,
    this.size = 56,
    this.selected = false,
    this.onTap,
    this.negative = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              companion.accent.withValues(alpha: 0.95),
              companion.accent.withValues(alpha: 0.55),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.white.withValues(alpha: 0.6),
            width: selected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: companion.accent.withValues(alpha: selected ? 0.55 : 0.3),
              blurRadius: selected ? 16 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: ClipOval(
          child: Image.asset(
            companion.avatarAsset(negative: negative),
            width: size,
            height: size,
            fit: BoxFit.cover,
            // Portrait tinggi: ratakan ke atas agar wajah terlihat.
            alignment: Alignment.topCenter,
            // Bila file gambar belum ada, tampilkan emoji sebagai placeholder.
            errorBuilder: (_, _, _) => Center(
              child: Text(
                companion.emoji,
                style: TextStyle(fontSize: size * 0.42),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
