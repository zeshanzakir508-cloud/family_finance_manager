import 'package:hive/hive.dart';

part 'goal_model.g.dart';

@HiveType(typeId: 8)
class GoalModel extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? userId;

  @HiveField(2)
  String? name;

  @HiveField(3)
  double? totalAmount;

  @HiveField(4)
  String? note;

  @HiveField(5)
  DateTime? createdAt;

  @HiveField(6)
  double? currentProgress;

  @HiveField(7)
  bool? isCompleted;

  GoalModel({
    this.id,
    this.userId,
    this.name,
    this.totalAmount,
    this.note,
    this.createdAt,
    this.currentProgress = 0,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'totalAmount': totalAmount,
      'note': note,
      'createdAt': createdAt?.toIso8601String(),
      'currentProgress': currentProgress,
      'isCompleted': isCompleted,
    };
  }

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      totalAmount: json['totalAmount'],
      note: json['note'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      currentProgress: json['currentProgress'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}
