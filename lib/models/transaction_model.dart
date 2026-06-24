import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 2)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

@HiveType(typeId: 3)
enum TransactionCategory {
  @HiveField(0)
  food,
  @HiveField(1)
  transport,
  @HiveField(2)
  shopping,
  @HiveField(3)
  entertainment,
  @HiveField(4)
  utilities,
  @HiveField(5)
  rent,
  @HiveField(6)
  healthcare,
  @HiveField(7)
  education,
  @HiveField(8)
  salary,
  @HiveField(9)
  investment,
  @HiveField(10)
  gift,
  @HiveField(11)
  travel,
  @HiveField(12)
  insurance,
  @HiveField(13)
  other,
}

@HiveType(typeId: 1)
class TransactionModel extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? userId;

  @HiveField(2)
  String? familyId;

  @HiveField(3)
  double? amount;

  @HiveField(4)
  String? category;

  @HiveField(5)
  String? description;

  @HiveField(6)
  TransactionType? type;

  @HiveField(7)
  DateTime? date;

  @HiveField(8)
  String? receiptImageUrl;

  @HiveField(9)
  String? createdBy;

  @HiveField(10)
  DateTime? createdAt;

  @HiveField(11)
  String? notes;

  @HiveField(12)
  bool? isRecurring;

  @HiveField(13)
  String? recurrenceFrequency;

  @HiveField(14)
  String? paymentMethod;

  @HiveField(15)
  String? location;

  @HiveField(16)
  List<String>? tags;

  @HiveField(17)
  bool? isSynced;

  @HiveField(18)
  String? receiptImageLocalPath;

  @HiveField(19)
  DateTime? updatedAt;

  @HiveField(20)
  String? currency;

  TransactionModel({
    this.id,
    this.userId,
    this.familyId,
    this.amount,
    this.category,
    this.description,
    this.type,
    this.date,
    this.receiptImageUrl,
    this.createdBy,
    this.createdAt,
    this.notes,
    this.isRecurring = false,
    this.recurrenceFrequency,
    this.paymentMethod,
    this.location,
    this.tags,
    this.isSynced = false,
    this.receiptImageLocalPath,
    this.updatedAt,
    this.currency = 'USD',
  });

  // Convert to JSON for Firebase/Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'familyId': familyId,
      'amount': amount,
      'category': category,
      'description': description,
      'type': type?.index,
      'date': date?.toIso8601String(),
      'receiptImageUrl': receiptImageUrl,
      'createdBy': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'notes': notes,
      'isRecurring': isRecurring,
      'recurrenceFrequency': recurrenceFrequency,
      'paymentMethod': paymentMethod,
      'location': location,
      'tags': tags,
      'isSynced': isSynced,
      'receiptImageLocalPath': receiptImageLocalPath,
      'updatedAt': updatedAt?.toIso8601String(),
      'currency': currency,
    };
  }

  // Create from JSON (Firebase/Firestore)
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      userId: json['userId'],
      familyId: json['familyId'],
      amount: json['amount']?.toDouble(),
      category: json['category'],
      description: json['description'],
      type: json['type'] != null 
          ? TransactionType.values[json['type']] 
          : null,
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : null,
      receiptImageUrl: json['receiptImageUrl'],
      createdBy: json['createdBy'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      notes: json['notes'],
      isRecurring: json['isRecurring'] ?? false,
      recurrenceFrequency: json['recurrenceFrequency'],
      paymentMethod: json['paymentMethod'],
      location: json['location'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isSynced: json['isSynced'] ?? false,
      receiptImageLocalPath: json['receiptImageLocalPath'],
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      currency: json['currency'] ?? 'USD',
    );
  }

  // Create copy with updated fields
  TransactionModel copyWith({
    String? id,
    String? userId,
    String? familyId,
    double? amount,
    String? category,
    String? description,
    TransactionType? type,
    DateTime? date,
    String? receiptImageUrl,
    String? createdBy,
    DateTime? createdAt,
    String? notes,
    bool? isRecurring,
    String? recurrenceFrequency,
    String? paymentMethod,
    String? location,
    List<String>? tags,
    bool? isSynced,
    String? receiptImageLocalPath,
    DateTime? updatedAt,
    String? currency,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      familyId: familyId ?? this.familyId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      type: type ?? this.type,
      date: date ?? this.date,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      isSynced: isSynced ?? this.isSynced,
      receiptImageLocalPath: receiptImageLocalPath ?? this.receiptImageLocalPath,
      updatedAt: updatedAt ?? this.updatedAt,
      currency: currency ?? this.currency,
    );
  }

  // Helper method to get formatted amount
  String get formattedAmount {
    if (amount == null) return '\$0.00';
    return '\$${amount!.toStringAsFixed(2)}';
  }

  // Helper method to get formatted date
  String get formattedDate {
    if (date == null) return '';
    return '${date!.day}/${date!.month}/${date!.year}';
  }

  // Helper method to get transaction type string
  String get typeString {
    return type == TransactionType.income ? 'Income' : 'Expense';
  }

  // Helper method to get category display name
  String get categoryDisplayName {
    if (category == null) return 'Other';
    return category!.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  // Helper method to get color based on type
  Color get typeColor {
    return type == TransactionType.income 
        ? Colors.green 
        : Colors.red;
  }

  // Helper method to get icon based on category
  IconData get categoryIcon {
    if (category == null) return Icons.category;
    switch (category) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.electric_bolt;
      case 'rent':
        return Icons.home;
      case 'healthcare':
        return Icons.health_and_safety;
      case 'education':
        return Icons.school;
      case 'salary':
        return Icons.attach_money;
      case 'investment':
        return Icons.trending_up;
      case 'gift':
        return Icons.card_giftcard;
      case 'travel':
        return Icons.flight;
      case 'insurance':
        return Icons.security;
      default:
        return Icons.category;
    }
  }

  // Helper method to check if transaction is recurring
  bool get isRecurringTransaction => isRecurring ?? false;

  // Helper method to get recurrence frequency display
  String? get recurrenceDisplay {
    if (!isRecurringTransaction) return null;
    switch (recurrenceFrequency) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      default:
        return recurrenceFrequency;
    }
  }

  @override
  String toString() {
    return 'TransactionModel{id: $id, amount: $amount, type: $type, category: $category, date: $date}';
  }
}
