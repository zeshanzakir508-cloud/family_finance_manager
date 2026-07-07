// lib/models/category_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

// ✅ FIXED: Uncommented part directive for build_runner
part 'category_model.g.dart';

@HiveType(typeId: 12)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? icon;

  @HiveField(3)
  final String? color;

  @HiveField(4)
  final String type; // 'income', 'expense', or 'both'

  @HiveField(5)
  final String? userId;

  @HiveField(6)
  final String? familyId;

  @HiveField(7)
  final bool isDefault;

  @HiveField(8)
  final bool isActive;

  @HiveField(9)
  final DateTime? createdAt;

  @HiveField(10)
  final int? order;

  CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    this.type = 'expense',
    this.userId,
    this.familyId,
    this.isDefault = false,
    this.isActive = true,
    this.createdAt,
    this.order,
  });

  // Safe Timestamp parser
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'userId': userId,
      'familyId': familyId,
      'isDefault': isDefault,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'order': order,
    };
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Uncategorized',
      icon: json['icon'],
      color: json['color'],
      type: json['type'] ?? 'expense',
      userId: json['userId'],
      familyId: json['familyId'],
      isDefault: json['isDefault'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: _parseTimestamp(json['createdAt']),
      order: json['order'],
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    String? type,
    String? userId,
    String? familyId,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    int? order,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      familyId: familyId ?? this.familyId,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      order: order ?? this.order,
    );
  }

  // ==================== HELPERS ====================

  Color get colorValue {
    if (color == null) return Colors.grey;
    try {
      return Color(int.parse('0xFF${color!.replaceAll('#', '')}'));
    } catch (_) {
      return Colors.grey;
    }
  }

  IconData get iconData {
    if (icon == null) return Icons.category;
    try {
      // Support for material icons by name
      return IconData(
        int.parse(icon!.replaceFirst('0x', '')),
        fontFamily: 'MaterialIcons',
      );
    } catch (_) {
      return Icons.category;
    }
  }

  bool get isIncome => type == 'income' || type == 'both';
  bool get isExpense => type == 'expense' || type == 'both';

  String get displayName => name;

  bool get isCustom => !isDefault;

  // Default categories
  static List<CategoryModel> get defaultCategories {
    return [
      // Income categories
      CategoryModel(
        id: 'income_salary',
        name: 'Salary',
        icon: '0xe8b0', // Icons.attach_money
        color: '#4CAF50',
        type: 'income',
        isDefault: true,
        order: 0,
      ),
      CategoryModel(
        id: 'income_business',
        name: 'Business',
        icon: '0xe53f', // Icons.business
        color: '#2196F3',
        type: 'income',
        isDefault: true,
        order: 1,
      ),
      CategoryModel(
        id: 'income_investment',
        name: 'Investment',
        icon: '0xe3b0', // Icons.trending_up
        color: '#9C27B0',
        type: 'income',
        isDefault: true,
        order: 2,
      ),
      CategoryModel(
        id: 'income_gift',
        name: 'Gift',
        icon: '0xe8f6', // Icons.card_giftcard
        color: '#FF9800',
        type: 'income',
        isDefault: true,
        order: 3,
      ),
      CategoryModel(
        id: 'income_other',
        name: 'Other Income',
        icon: '0xe88a', // Icons.money
        color: '#607D8B',
        type: 'income',
        isDefault: true,
        order: 4,
      ),

      // Expense categories
      CategoryModel(
        id: 'expense_food',
        name: 'Food',
        icon: '0xe56c', // Icons.restaurant
        color: '#F44336',
        type: 'expense',
        isDefault: true,
        order: 5,
      ),
      CategoryModel(
        id: 'expense_transport',
        name: 'Transport',
        icon: '0xe531', // Icons.directions_car
        color: '#FF5722',
        type: 'expense',
        isDefault: true,
        order: 6,
      ),
      CategoryModel(
        id: 'expense_shopping',
        name: 'Shopping',
        icon: '0xe8cc', // Icons.shopping_bag
        color: '#E91E63',
        type: 'expense',
        isDefault: true,
        order: 7,
      ),
      CategoryModel(
        id: 'expense_entertainment',
        name: 'Entertainment',
        icon: '0xe04b', // Icons.movie
        color: '#9C27B0',
        type: 'expense',
        isDefault: true,
        order: 8,
      ),
      CategoryModel(
        id: 'expense_utilities',
        name: 'Utilities',
        icon: '0xe7e4', // Icons.electric_bolt
        color: '#00BCD4',
        type: 'expense',
        isDefault: true,
        order: 9,
      ),
      CategoryModel(
        id: 'expense_rent',
        name: 'Rent',
        icon: '0xe88a', // Icons.home
        color: '#8BC34A',
        type: 'expense',
        isDefault: true,
        order: 10,
      ),
      CategoryModel(
        id: 'expense_healthcare',
        name: 'Healthcare',
        icon: '0xe7fb', // Icons.health_and_safety
        color: '#4CAF50',
        type: 'expense',
        isDefault: true,
        order: 11,
      ),
      CategoryModel(
        id: 'expense_education',
        name: 'Education',
        icon: '0xe80c', // Icons.school
        color: '#3F51B5',
        type: 'expense',
        isDefault: true,
        order: 12,
      ),
      CategoryModel(
        id: 'expense_travel',
        name: 'Travel',
        icon: '0xe532', // Icons.flight
        color: '#2196F3',
        type: 'expense',
        isDefault: true,
        order: 13,
      ),
      CategoryModel(
        id: 'expense_insurance',
        name: 'Insurance',
        icon: '0xe3c3', // Icons.security
        color: '#FF9800',
        type: 'expense',
        isDefault: true,
        order: 14,
      ),
      CategoryModel(
        id: 'expense_other',
        name: 'Other Expense',
        icon: '0xe88a', // Icons.money
        color: '#607D8B',
        type: 'expense',
        isDefault: true,
        order: 15,
      ),
    ];
  }

  // Get default categories by type
  static List<CategoryModel> getDefaultByType(String type) {
    return defaultCategories.where((c) => c.type == type || c.type == 'both').toList();
  }

  // Get income default categories
  static List<CategoryModel> get defaultIncomeCategories {
    return getDefaultByType('income');
  }

  // Get expense default categories
  static List<CategoryModel> get defaultExpenseCategories {
    return getDefaultByType('expense');
  }
}
