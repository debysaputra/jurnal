import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_banner.dart';
import '../widgets/glass_card.dart';
import 'home_screen.dart';
import 'journal_list_screen.dart';
import 'todo_screen.dart';
import 'settings_screen.dart';
import 'journal_edit_screen.dart';
import 'offline_ai_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  static RootScreenController? of(BuildContext context) =>
      context.findAncestorStateOfType<_RootScreenState>();

  @override
  State<RootScreen> createState() => _RootScreenState();
}

abstract class RootScreenController {
  void goTo(int i);
}

class _RootScreenState extends State<RootScreen>
    implements RootScreenController {
  int _index = 0;

  @override
  void goTo(int i) {
    if (i < 0 || i >= _pages.length) return;
    setState(() => _index = i);
  }

  // Indeks 2 (Chat) tidak punya halaman embedded — di-push sebagai layar penuh
  // agar input chat tak bentrok dengan bottom bar mengambang.
  final _pages = const [
    HomeScreen(),
    JournalListScreen(),
    SizedBox.shrink(),
    TodoScreen(),
    SettingsScreen(),
  ];

  static const _chatIndex = 2;

  final _items = const [
    _NavItem(Icons.home_rounded, 'Beranda'),
    _NavItem(Icons.menu_book_rounded, 'Jurnal'),
    _NavItem(Icons.chat_bubble_rounded, 'Chat'),
    _NavItem(Icons.checklist_rounded, 'To-Do'),
    _NavItem(Icons.person_rounded, 'Profil'),
  ];

  void _onNavTap(int i) {
    if (i == _chatIndex) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OfflineAiScreen()),
      );
      return;
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: GradientBackground(
        child: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            child: KeyedSubtree(
              key: ValueKey(_index),
              child: _pages[_index],
            ),
          ),
        ),
      ),
      floatingActionButton: _index == 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const JournalEditScreen(),
                ),
              ),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              label: const Text(
                'Tulis',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdBannerWidget(),
          const SizedBox(height: 8),
          _BottomBar(
            index: _index,
            items: _items,
            onTap: _onNavTap,
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _BottomBar extends StatelessWidget {
  final int index;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _BottomBar({
    required this.index,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                final selected = i == index;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: selected ? 16 : 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[i].icon,
                          color: selected ? Colors.white : AppColors.inkSoft,
                          size: 22,
                        ),
                        if (selected) ...[
                          const SizedBox(width: 6),
                          Text(
                            items[i].label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
