import 'package:hive/hive.dart';

part 'todo_item.g.dart';

@HiveType(typeId: 1)
class TodoItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool done;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  int priority; // 0 low, 1 medium, 2 high

  TodoItem({
    required this.id,
    required this.title,
    required this.done,
    required this.date,
    required this.createdAt,
    this.priority = 1,
  });
}
