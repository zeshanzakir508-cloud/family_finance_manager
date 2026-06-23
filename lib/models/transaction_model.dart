import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 1)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

@HiveType(typeId: 2)
class TransactionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String category;

  @HiveField(3)
  String description;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  TransactionType type;

  @HiveField(6)
  String? photoPath;

  @HiveField(7)
  bool isImportant;

  TransactionModel({
    String? id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.type,
    this.photoPath,
    this.isImportant = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'category': category,
        'description': description,
        'date': date.toIso8601String(),
        'type': type.name,
        'photoPath': photoPath,
        'isImportant': isImportant,
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
        id: json['id'],
        amount: json['amount'].toDouble(),
        category: json['category'],
        description: json['description'],
        date: DateTime.parse(json['date']),
        type: json['type'] == 'income' ? TransactionType.income : TransactionType.expense,
        photoPath: json['photoPath'],
        isImportant: json['isImportant'] ?? false,
      );
}