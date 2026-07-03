// lib/models/transfer_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TransferModel {
  final String id;
  final String familyId;
  final String fromUserId;
  final String toUserId;
  final String fromUserName;
  final String toUserName;
  final double amount;
  final DateTime date;
  final String? description;
  final String status; // pending, approved, rejected, completed
  final bool isRecurring;
  final String? recurringType; // daily, weekly, monthly, yearly
  final String createdBy;
  final DateTime createdAt;
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
