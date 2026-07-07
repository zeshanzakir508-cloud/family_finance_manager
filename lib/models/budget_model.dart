// lib/models/budget_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

// ✅ FIXED: Uncommented part directive for build_runner
part 'budget_model.g.dart';

// ==================== BUDGET CATEGORY MODEL ====================

@HiveType(typeId: 10)
class BudgetCategory extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String? icon;
  
  @HiveField(3)
  final String? color;
  
  @HiveField(4)
  final double allocated;
  
  @HiveField(5)
  final double spent;
  
  @HiveField(6)
  final double remaining;
  
  @HiveField(7)
  final String? notes;

  BudgetCategory({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    required this.allocated,
    required this.spent,
    required this.remaining,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'allocated': allocated,
      'spent': spent,
      'remaining': remaining,
      'notes': notes,
    };
  }

  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    return BudgetCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Uncategorized',
      icon: json['icon'],
      color: json['color'],
      allocated: (json['allocated'] as num?)?.toDouble() ?? 0.0,
      spent: (json['spent'] as num?)?.toDouble() ?? 0.0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'],
    );
  }

  BudgetCategory copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    double? allocated,
    double? spent,
    double? remaining,
    String? notes,
  }) {
    return BudgetCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      allocated: allocated ?? this.allocated,
      spent: spent ?? this.spent,
      remaining: remaining ?? this.remaining,
      notes: notes ?? this.notes,
    );
  }

  // Helper: progress percentage
  double get progressPercentage {
    if (allocated == 0) return 0.0;
    return (spent / allocated).clamp(0.0, 1.0);
  }

  // Helper: is over budget
  bool get isOverBudget => spent > allocated;

  // Helper: is near budget (80% or more)
  bool get isNearBudget => progressPercentage >= 0.8 && !isOverBudget;
}

// ==================== BUDGET MODEL ====================

@HiveType(typeId: 11)
class BudgetModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final String? familyId;
  
  @HiveField(3)
  final String name;
  
  @HiveField(4)
  final String? description;
  
  @HiveField(5)
  final int month;
  
  @HiveField(6)
  final int year;
  
  @HiveField(7)
  final double totalAllocated;
  
  @HiveField(8)
  final double totalSpent;
  
  @HiveField(9)
  final double totalRemaining;
  
  @HiveField(10)
  final List<BudgetCategory> categories;
  
  @HiveField(11)
  final bool isRollover;
  
  @HiveField(12)
  final String? previousBudgetId;
  
  @HiveField(13)
  final DateTime createdAt;
  
  @HiveField(14)
  final DateTime? updatedAt;
  
  @HiveField(15)
  final bool isActive;

  BudgetModel({
    required this.id,
    required this.userId,
    this.familyId,
    required this.name,
    this.description,
    required this.month,
    required this.year,
    required this.totalAllocated,
    required this.totalSpent,
    required this.totalRemaining,
    this.categories = const [],
    this.isRollover = false,
    this.previousBudgetId,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'familyId': familyId,
      'name': name,
      'description': description,
      'month': month,
      'year': year,
      'totalAllocated': totalAllocated,
      'totalSpent': totalSpent,
      'totalRemaining': totalRemaining,
      'categories': categories.map((c) => c.toJson()).toList(),
      'isRollover': isRollover,
      'previousBudgetId': previousBudgetId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
    };
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      familyId: json['familyId'],
      name: json['name'] ?? 'Budget',
      description: json['description'],
      month: json['month'] ?? DateTime.now().month,
      year: json['year'] ?? DateTime.now().year,
      totalAllocated: (json['totalAllocated'] as num?)?.toDouble() ?? 0.0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      totalRemaining: (json['totalRemaining'] as num?)?.toDouble() ?? 0.0,
      categories: json['categories'] != null
          ? (json['categories'] as List)
              .map((c) => BudgetCategory.fromJson(c))
              .toList()
          : [],
      isRollover: json['isRollover'] ?? false,
      previousBudgetId: json['previousBudgetId'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: json['isActive'] ?? true,
    );
  }

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? familyId,
    String? name,
    String? description,
    int? month,
    int? year,
    double? totalAllocated,
    double? totalSpent,
    double? totalRemaining,
    List<BudgetCategory>? categories,
    bool? isRollover,
    String? previousBudgetId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      description: description ?? this.description,
      month: month ?? this.month,
      year: year ?? this.year,
      totalAllocated: totalAllocated ?? this.totalAllocated,
      totalSpent: totalSpent ?? this.totalSpent,
      totalRemaining: totalRemaining ?? this.totalRemaining,
      categories: categories ?? this.categories,
      isRollover: isRollover ?? this.isRollover,
      previousBudgetId: previousBudgetId ?? this.previousBudgetId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // ==================== HELPERS ====================

  // Get month/year display
  String get monthYearDisplay => '$month/$year';
  
  // Get month name
  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  // Get progress percentage
  double get progressPercentage {
    if (totalAllocated == 0) return 0.0;
    return (totalSpent / totalAllocated).clamp(0.0, 1.0);
  }

  // Check if over budget
  bool get isOverBudget => totalSpent > totalAllocated;

  // Check if near budget (80% or more)
  bool get isNearBudget => progressPercentage >= 0.8 && !isOverBudget;

  // Get category by id
  BudgetCategory? getCategoryById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // Get category by name
  BudgetCategory? getCategoryByName(String name) {
    try {
      return categories.firstWhere((c) => c.name.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  BudgetModel updateCategorySpent(String categoryId, double amount) {
    final updatedCategories = categories.map((category) {
      if (category.id == categoryId) {
        final newSpent = category.spent + amount;
        return category.copyWith(
          spent: newSpent,
          remaining: category.allocated - newSpent,
        );
      }
      return category;
    }).toList();

    return copyWith(
      categories: updatedCategories,
      totalSpent: updatedCategories.fold(0.0, (sum, c) => sum + c.spent),
      totalRemaining: updatedCategories.fold(0.0, (sum, c) => sum + c.remaining),
    );
  }

  BudgetModel resetForNewMonth() {
    final resetCategories = categories.map((category) {
      return category.copyWith(
        spent: 0.0,
        remaining: isRollover ? category.remaining + category.allocated : category.allocated,
      );
    }).toList();

    return copyWith(
      categories: resetCategories,
      totalSpent: 0.0,
      totalRemaining: resetCategories.fold(0.0, (sum, c) => sum + c.remaining),
      updatedAt: DateTime.now(),
    );
  }

  BudgetModel addCategory(BudgetCategory category) {
    final updatedCategories = List<BudgetCategory>.from(categories)..add(category);
    
    final newTotalAllocated = updatedCategories.fold<double>(
      0.0, 
      (sum, c) => sum + c.allocated
    );
    
    final newTotalSpent = updatedCategories.fold<double>(
      0.0, 
      (sum, c) => sum + c.spent
    );
    
    final newTotalRemaining = updatedCategories.fold<double>(
      0.0, 
      (sum, c) => sum + c.remaining
    );

    return copyWith(
      categories: updatedCategories,
      totalAllocated: newTotalAllocated,
      totalSpent: newTotalSpent,
      totalRemaining: newTotalRemaining,
      updatedAt: DateTime.now(),
    );
  }

  BudgetModel removeCategory(String categoryId) {
    final updatedCategories = categories.where((c) => c.id != categoryId).toList();
    
    final newTotalAllocated = updatedCategories.fold<double>(
      0.0, 
      (sum, c) => sum + c.allocated
    );
    
    final newTotalSpent = updatedCategories.fold<double>(
      0.0, 
      (sum, c) => sum + c.spent
    );
    
    final newTotalRemaining = updatedCategories.fold<double>(
      0.0, 
      (sum, c) => sum + c.remaining
    );

    return copyWith(
      categories: updatedCategories,
      totalAllocated: newTotalAllocated,
      totalSpent: newTotalSpent,
      totalRemaining: newTotalRemaining,
      updatedAt: DateTime.now(),
    );
  }
}
