import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'transfer_model.g.dart';

@HiveType(typeId: 3)
enum TransferStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  approved,
  @HiveField(2)
  rejected,
  @HiveField(3)
  completed,
}

@HiveType(typeId: 4)
class TransferModel extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? familyId;

  @HiveField(2)
  String? fromMemberId;

  @HiveField(3)
  String? fromMemberName;

  @HiveField(4)
  String? toMemberId;

  @HiveField(5)
  String? toMemberName;

  @HiveField(6)
  double? amount;

  @HiveField(7)
  String? note;

  @HiveField(8)
  TransferStatus? status;

  @HiveField(9)
  DateTime? createdAt;

  @HiveField(10)
  DateTime? approvedAt;

  @HiveField(11)
  DateTime? rejectedAt;

  @HiveField(12)
  String? rejectionReason;

  @HiveField(13)
  String? senderTransactionId;

  @HiveField(14)
  String? receiverTransactionId;

  TransferModel({
    this.id,
    this.familyId,
    this.fromMemberId,
    this.fromMemberName,
    this.toMemberId,
    this.toMemberName,
    this.amount,
    this.note,
    this.status = TransferStatus.pending,
    this.createdAt,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.senderTransactionId,
    this.receiverTransactionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'fromMemberId': fromMemberId,
      'fromMemberName': fromMemberName,
      'toMemberId': toMemberId,
      'toMemberName': toMemberName,
      'amount': amount,
      'note': note,
      'status': status?.index,
      'createdAt': createdAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'senderTransactionId': senderTransactionId,
      'receiverTransactionId': receiverTransactionId,
    };
  }

  factory TransferModel.fromJson(Map<String, dynamic> json) {
    return TransferModel(
      id: json['id'],
      familyId: json['familyId'],
      fromMemberId: json['fromMemberId'],
      fromMemberName: json['fromMemberName'],
      toMemberId: json['toMemberId'],
      toMemberName: json['toMemberName'],
      amount: json['amount'],
      note: json['note'],
      status: json['status'] != null
          ? TransferStatus.values[json['status']]
          : TransferStatus.pending,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
      rejectedAt: json['rejectedAt'] != null
          ? DateTime.parse(json['rejectedAt'])
          : null,
      rejectionReason: json['rejectionReason'],
      senderTransactionId: json['senderTransactionId'],
      receiverTransactionId: json['receiverTransactionId'],
    );
  }

  TransferModel copyWith({
    String? id,
    String? familyId,
    String? fromMemberId,
    String? fromMemberName,
    String? toMemberId,
    String? toMemberName,
    double? amount,
    String? note,
    TransferStatus? status,
    DateTime? createdAt,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
    String? senderTransactionId,
    String? receiverTransactionId,
  }) {
    return TransferModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      fromMemberId: fromMemberId ?? this.fromMemberId,
      fromMemberName: fromMemberName ?? this.fromMemberName,
      toMemberId: toMemberId ?? this.toMemberId,
      toMemberName: toMemberName ?? this.toMemberName,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      senderTransactionId: senderTransactionId ?? this.senderTransactionId,
      receiverTransactionId: receiverTransactionId ?? this.receiverTransactionId,
    );
  }

  String get statusDisplay {
    switch (status) {
      case TransferStatus.pending:
        return 'Pending';
      case TransferStatus.approved:
        return 'Approved';
      case TransferStatus.rejected:
        return 'Rejected';
      case TransferStatus.completed:
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  Color get statusColor {
    switch (status) {
      case TransferStatus.pending:
        return Colors.orange;
      case TransferStatus.approved:
        return Colors.blue;
      case TransferStatus.rejected:
        return Colors.red;
      case TransferStatus.completed:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
