// lib/models/transfer_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

// ✅ FIXED: Uncommented part directive for build_runner
part 'transfer_model.g.dart';

@HiveType(typeId: 3)
class TransferModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String familyId;
  
  @HiveField(2)
  final String fromUserId;
  
  @HiveField(3)
  final String toUserId;
  
  @HiveField(4)
  final String fromUserName;
  
  @HiveField(5)
  final String toUserName;
  
  @HiveField(6)
  final double amount;
  
  @HiveField(7)
  final DateTime date;
  
  @HiveField(8)
  final String? description;
  
  @HiveField(9)
  final String status; // pending, approved, rejected, completed
  
  @HiveField(10)
  final bool isRecurring;
  
  @HiveField(11)
  final String? recurringType; // daily, weekly, monthly, yearly
  
  @HiveField(12)
  final String createdBy;
  
  @HiveField(13)
  final DateTime createdAt;
  
  @HiveField(14)
  final DateTime? updatedAt;

  TransferModel({
    required this.id,
    required this.familyId,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUserName,
    required this.toUserName,
    required this.amount,
    required this.date,
    this.description,
    this.status = 'pending',
    this.isRecurring = false,
    this.recurringType,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isCompleted => status == 'completed';

  TransferModel copyWith({
    String? id,
    String? familyId,
    String? fromUserId,
    String? toUserId,
    String? fromUserName,
    String? toUserName,
    double? amount,
    DateTime? date,
    String? description,
    String? status,
    bool? isRecurring,
    String? recurringType,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransferModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      toUserName: toUserName ?? this.toUserName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      status: status ?? this.status,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringType: recurringType ?? this.recurringType,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromUserName': fromUserName,
      'toUserName': toUserName,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'description': description,
      'status': status,
      'isRecurring': isRecurring,
      'recurringType': recurringType,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory TransferModel.fromJson(Map<String, dynamic> json) {
    return TransferModel(
      id: json['id'] ?? '',
      familyId: json['familyId'] ?? '',
      fromUserId: json['fromUserId'] ?? '',
      toUserId: json['toUserId'] ?? '',
      fromUserName: json['fromUserName'] ?? 'Unknown',
      toUserName: json['toUserName'] ?? 'Unknown',
      amount: (json['amount'] ?? 0).toDouble(),
      date: (json['date'] as Timestamp).toDate(),
      description: json['description'],
      status: json['status'] ?? 'pending',
      isRecurring: json['isRecurring'] ?? false,
      recurringType: json['recurringType'],
      createdBy: json['createdBy'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null ? (json['updatedAt'] as Timestamp).toDate() : null,
    );
  }
}
