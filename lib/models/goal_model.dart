import 'package:hive/hive.dart';

part 'goal_model.g.dart'; // ✅ Already present - good!

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
      totalAmount: json['totalAmount']?.toDouble(), // ✅ Fixed: ensure double
      note: json['note'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      currentProgress: json['currentProgress']?.toDouble() ?? 0, // ✅ Fixed: ensure double
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  GoalModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? totalAmount,
    String? note,
    DateTime? createdAt,
    double? currentProgress,
    bool? isCompleted,
  }) {
    return GoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      totalAmount: totalAmount ?? this.totalAmount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      currentProgress: currentProgress ?? this.currentProgress,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  String get displayName => name ?? 'Goal';

  double get progress {
    if (totalAmount == null || totalAmount == 0) return 0;
    return (currentProgress ?? 0) / totalAmount!;
  }

  bool get isAchieved => progress >= 1.0;

  String get formattedAmount => '\$${totalAmount?.toStringAsFixed(2) ?? '0.00'}';
}
