import 'package:hive/hive.dart';

part 'journal_entry.g.dart';

@HiveType(typeId: 0)
class JournalEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  int moodIndex;

  @HiveField(4)
  List<String> tags;

  @HiveField(5)
  List<String> photoPaths;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  @HiveField(8)
  bool favorite;

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.moodIndex,
    required this.tags,
    required this.photoPaths,
    required this.createdAt,
    required this.updatedAt,
    this.favorite = false,
  });
}
