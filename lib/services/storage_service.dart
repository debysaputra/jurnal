import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/journal_entry.dart';
import '../models/todo_item.dart';

class StorageService extends ChangeNotifier {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const journalBox = 'journal_entries';
  static const todoBox = 'todos';
  static const prefsBox = 'prefs';

  late Box<JournalEntry> _journals;
  late Box<TodoItem> _todos;
  late Box _prefs;

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(JournalEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TodoItemAdapter());
    }
    _journals = await Hive.openBox<JournalEntry>(journalBox);
    _todos = await Hive.openBox<TodoItem>(todoBox);
    _prefs = await Hive.openBox(prefsBox);
  }

  // ---------- Journal ----------
  List<JournalEntry> get allJournals {
    final list = _journals.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> saveJournal(JournalEntry entry) async {
    await _journals.put(entry.id, entry);
    notifyListeners();
  }

  Future<void> deleteJournal(String id) async {
    await _journals.delete(id);
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final j = _journals.get(id);
    if (j == null) return;
    j.favorite = !j.favorite;
    await j.save();
    notifyListeners();
  }

  List<JournalEntry> journalsOn(DateTime day) {
    return _journals.values
        .where((j) =>
            j.createdAt.year == day.year &&
            j.createdAt.month == day.month &&
            j.createdAt.day == day.day)
        .toList();
  }

  // ---------- Streak & statistik ----------
  /// Set tanggal (tanpa jam) yang memiliki minimal satu entri jurnal.
  Set<DateTime> get _journalDays => _journals.values
      .map((j) => DateTime(j.createdAt.year, j.createdAt.month, j.createdAt.day))
      .toSet();

  /// Jumlah hari berturut-turut menulis, berakhir hari ini atau kemarin.
  /// Bernilai 0 bila hari terakhir menulis lebih lama dari kemarin.
  int get currentStreak {
    final days = _journalDays;
    if (days.isEmpty) return 0;
    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Streak terpanjang yang pernah dicapai (untuk badge).
  int get longestStreak {
    final days = _journalDays.toList()..sort();
    if (days.isEmpty) return 0;
    var longest = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        run++;
      } else {
        run = 1;
      }
      if (run > longest) longest = run;
    }
    return longest;
  }

  int get totalJournals => _journals.length;

  /// Berapa jenis mood (dari 5) yang pernah dipakai.
  int get distinctMoodsUsed =>
      _journals.values.map((j) => j.moodIndex).toSet().length;

  int get favoriteCount =>
      _journals.values.where((j) => j.favorite).length;

  // ---------- Todo ----------
  List<TodoItem> todosOn(DateTime day) {
    final list = _todos.values
        .where((t) =>
            t.date.year == day.year &&
            t.date.month == day.month &&
            t.date.day == day.day)
        .toList();
    list.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      return b.priority.compareTo(a.priority);
    });
    return list;
  }

  Future<void> saveTodo(TodoItem t) async {
    await _todos.put(t.id, t);
    notifyListeners();
  }

  Future<void> deleteTodo(String id) async {
    await _todos.delete(id);
    notifyListeners();
  }

  Future<void> toggleTodo(String id) async {
    final t = _todos.get(id);
    if (t == null) return;
    t.done = !t.done;
    await t.save();
    notifyListeners();
  }

  // ---------- Prefs ----------
  bool get reminderEnabled => _prefs.get('reminder_enabled', defaultValue: false) as bool;
  set reminderEnabled(bool v) {
    _prefs.put('reminder_enabled', v);
    notifyListeners();
  }

  int get reminderHour => _prefs.get('reminder_hour', defaultValue: 21) as int;
  int get reminderMinute => _prefs.get('reminder_minute', defaultValue: 0) as int;
  Future<void> setReminderTime(int h, int m) async {
    await _prefs.put('reminder_hour', h);
    await _prefs.put('reminder_minute', m);
    notifyListeners();
  }

  String get userName => _prefs.get('user_name', defaultValue: 'Sahabat') as String;
  set userName(String v) {
    _prefs.put('user_name', v);
    notifyListeners();
  }

  String get selectedCompanionId =>
      _prefs.get('companion_id', defaultValue: 'freya') as String;
  set selectedCompanionId(String v) {
    _prefs.put('companion_id', v);
    notifyListeners();
  }

  // ---------- AI Cloud (Gemini) ----------
  String get geminiApiKey =>
      _prefs.get('gemini_key', defaultValue: '') as String;
  set geminiApiKey(String v) {
    _prefs.put('gemini_key', v.trim());
    notifyListeners();
  }

  // ---------- Riwayat chat (per karakter) ----------
  /// Daftar pesan {'u': bool fromUser, 't': String text}.
  List<Map<String, dynamic>> chatHistory(String companionId) {
    final raw = _prefs.get('chat_$companionId');
    if (raw is String && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
      } catch (_) {}
    }
    return [];
  }

  Future<void> saveChatHistory(
      String companionId, List<Map<String, dynamic>> messages) async {
    await _prefs.put('chat_$companionId', jsonEncode(messages));
  }

  Future<void> clearChatHistory(String companionId) async {
    await _prefs.delete('chat_$companionId');
  }

  String? get avatarPath {
    final v = _prefs.get('avatar_path');
    return v is String && v.isNotEmpty ? v : null;
  }

  Future<void> setAvatarPath(String? path) async {
    if (path == null || path.isEmpty) {
      await _prefs.delete('avatar_path');
    } else {
      await _prefs.put('avatar_path', path);
    }
    notifyListeners();
  }
}
