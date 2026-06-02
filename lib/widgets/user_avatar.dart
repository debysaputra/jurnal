import 'dart:io';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final double size;
  final double fontSize;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const UserAvatar({
    super.key,
    this.size = 64,
    this.fontSize = 28,
    this.onTap,
    this.showEditBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = StorageService.instance;
    final path = s.avatarPath;
    final hasPhoto = path != null && File(path).existsSync();
    final name = s.userName;
    final letter = name.isEmpty ? '✨' : name[0].toUpperCase();

    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasPhoto
            ? null
            : const LinearGradient(
                colors: [AppColors.lavender, AppColors.pink],
              ),
        boxShadow: [
          BoxShadow(
            color: AppColors.lavender.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
        image: hasPhoto
            ? DecorationImage(
                image: FileImage(File(path)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: hasPhoto
          ? null
          : Text(
              letter,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
    );

    final stack = showEditBadge
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              circle,
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          )
        : circle;

    return onTap == null
        ? stack
        : GestureDetector(onTap: onTap, child: stack);
  }
}
