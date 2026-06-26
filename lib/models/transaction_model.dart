import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

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
