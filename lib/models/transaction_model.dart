import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 1)
class TransactionModel extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? userId;

  @HiveField(2)
  double? amount;

  @HiveField(3)
  String? category;

  @HiveField(4)
  String? description;

  @HiveField(5)
  String? type; // 'income' or 'expense'

  @HiveField(6)
  DateTime? date;

  @HiveField(7)
  String? notes;

  @HiveField(8)
  DateTime? createdAt;

  @HiveField(9)
  String? familyId;

  @HiveField(10)
  String? memberId;

  @HiveField(11)
  String? memberName;

  @HiveField(12)
  bool? isFamilyTransaction;

  TransactionModel({
    this.id,
    this.userId,
    this.amount,
    this.category,
    this.description,
    this.type,
    this.date,
    this.notes,
    this.createdAt,
    this.familyId,
    this.memberId,
    this.memberName,
    this.isFamilyTransaction = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'category': category,
      'description': description,
      'type': type,
      'date': date?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'familyId': familyId,
      'memberId': memberId,
      'memberName': memberName,
      'isFamilyTransaction': isFamilyTransaction,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      userId: json['userId'],
      amount: json['amount']?.toDouble(),
      category: json['category'],
      description: json['description'],
      type: json['type'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      notes: json['notes'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      familyId: json['familyId'],
      memberId: json['memberId'],
      memberName: json['memberName'],
      isFamilyTransaction: json['isFamilyTransaction'] ?? false,
    );
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? category,
    String? description,
    String? type,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
    String? familyId,
    String? memberId,
    String? memberName,
    bool? isFamilyTransaction,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      type: type ?? this.type,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      familyId: familyId ?? this.familyId,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      isFamilyTransaction: isFamilyTransaction ?? this.isFamilyTransaction,
    );
  }

  // Helper methods
  String get formattedAmount {
    if (amount == null) return '\$0.00';
    return '\$${amount!.toStringAsFixed(2)}';
  }

  String get formattedDate {
    if (date == null) return '';
    return '${date!.day}/${date!.month}/${date!.year}';
  }

  String get typeDisplay {
    return type == 'income' ? 'Income' : 'Expense';
  }

  Color get typeColor {
    return type == 'income' ? Colors.green : Colors.red;
  }

  String get categoryDisplay {
    if (category == null) return 'Other';
    return category!.split('_').map((word) =>
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  IconData get categoryIcon {
    switch (category) {
      case 'Food': return Icons.restaurant;
      case 'Transport': return Icons.directions_car;
      case 'Shopping': return Icons.shopping_bag;
      case 'Entertainment': return Icons.movie;
      case 'Utilities': return Icons.electric_bolt;
      case 'Rent': return Icons.home;
      case 'Healthcare': return Icons.health_and_safety;
      case 'Education': return Icons.school;
      case 'Salary': return Icons.attach_money;
      case 'Investment': return Icons.trending_up;
      case 'Gift': return Icons.card_giftcard;
      case 'Travel': return Icons.flight;
      case 'Insurance': return Icons.security;
      default: return Icons.category;
    }
  }
}
