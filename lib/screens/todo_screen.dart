import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../models/todo_item.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';
import '../widgets/glass_card.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});
  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final _storage = StorageService.instance;
  DateTime _selected = DateTime.now();
  CalendarFormat _format = CalendarFormat.week;

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

  Future<void> _addTodo() async {
    final ctrl = TextEditingController();
    int priority = 1;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (ctx, set) => Container(
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.inkSoft.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tugas baru',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Apa yang ingin kamu kerjakan?',
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Prioritas',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(3, (i) {
                    final labels = ['Rendah', 'Sedang', 'Tinggi'];
                    final colors = [
                      AppColors.mint,
                      AppColors.peach,
                      AppColors.pink,
                    ];
                    final sel = priority == i;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
                        child: GestureDetector(
                          onTap: () => set(() => priority = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: sel
                                  ? colors[i]
                                  : Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: sel
                                    ? AppColors.primary
                                    : Colors.white.withValues(alpha: 0.12),
                                width: 1.2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              labels[i],
                              style: TextStyle(
                                fontWeight:
                                    sel ? FontWeight.w800 : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Tambah tugas'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ok == true && ctrl.text.trim().isNotEmpty) {
      final t = TodoItem(
        id: const Uuid().v4(),
        title: ctrl.text.trim(),
        done: false,
        date: DateTime(_selected.year, _selected.month, _selected.day),
        createdAt: DateTime.now(),
        priority: priority,
      );
      await _storage.saveTodo(t);
    }
  }

  @override
  Widget build(BuildContext context) {
    final todos = _storage.todosOn(_selected);
    final done = todos.where((t) => t.done).length;
    final progress = todos.isEmpty ? 0.0 : done / todos.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 180),
      children: [
        const SizedBox(height: 8),
        const Text(
          'Daftar tugas',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          Dates.fullDate(_selected),
          style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _selected,
            selectedDayPredicate: (d) => Dates.sameDay(d, _selected),
            calendarFormat: _format,
            availableCalendarFormats: const {
              CalendarFormat.week: 'Minggu',
              CalendarFormat.month: 'Bulan',
            },
            onFormatChanged: (f) => setState(() => _format = f),
            onDaySelected: (s, _) => setState(() => _selected = s),
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              formatButtonTextStyle: TextStyle(color: Colors.white),
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.peach.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
              weekendTextStyle: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          tint: AppColors.mint,
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$done dari ${todos.length} selesai',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tetap semangat, kamu bisa!',
                      style: TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                onPressed: _addTodo,
                icon: const Icon(Icons.add_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (todos.isEmpty)
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                const Text('🌤️', style: TextStyle(fontSize: 42)),
                const SizedBox(height: 10),
                const Text(
                  'Belum ada tugas hari ini',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tambahkan tugas dengan tombol +',
                  style: TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          AnimationLimiter(
            child: Column(
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 350),
                childAnimationBuilder: (w) => SlideAnimation(
                  horizontalOffset: 24,
                  child: FadeInAnimation(child: w),
                ),
                children: todos.map((t) => _TodoTile(item: t)).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

class _TodoTile extends StatelessWidget {
  final TodoItem item;
  const _TodoTile({required this.item});

  Color get _priorityColor {
    switch (item.priority) {
      case 2:
        return AppColors.pink;
      case 1:
        return AppColors.peach;
      default:
        return AppColors.mint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        key: ValueKey(item.id),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => StorageService.instance.deleteTodo(item.id),
              icon: Icons.delete_rounded,
              label: 'Hapus',
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ],
        ),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          onTap: () => StorageService.instance.toggleTodo(item.id),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: item.done ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.done ? AppColors.primary : AppColors.inkSoft,
                    width: 1.5,
                  ),
                ),
                child: item.done
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: item.done
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: item.done ? AppColors.inkSoft : AppColors.ink,
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 28,
                decoration: BoxDecoration(
                  color: _priorityColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
