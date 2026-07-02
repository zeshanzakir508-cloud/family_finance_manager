import 'package:hive/hive.dart';

part 'transfer_model.g.dart';

@HiveType(typeId: 3)
class TransferModel extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? familyId;

  @HiveField(2)
  String? fromMemberId;

  @HiveField(3)
  String? toMemberId;

  @HiveField(4)
  double? amount;

  @HiveField(5)
  String? currency;  // ✅ ADDED

  @HiveField(6)
  String? status;

  @HiveField(7)
  String? notes;

  @HiveField(8)
  DateTime? createdAt;

  @HiveField(9)
  DateTime? approvedAt;

  @HiveField(10)
  String? createdBy;

  TransferModel({
    this.id,
    this.familyId,
    this.fromMemberId,
    this.toMemberId,
    this.amount,
    this.currency,  // ✅ ADDED
    this.status = 'pending',
    this.notes,
    this.createdAt,
    this.approvedAt,
    this.createdBy,
  });

  TransferModel copyWith({
    String? id,
    String? familyId,
    String? fromMemberId,
    String? toMemberId,
    double? amount,
    String? currency,  // ✅ ADDED
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? approvedAt,
    String? createdBy,
  }) {
    return TransferModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      fromMemberId: fromMemberId ?? this.fromMemberId,
      toMemberId: toMemberId ?? this.toMemberId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,  // ✅ ADDED
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'fromMemberId': fromMemberId,
      'toMemberId': toMemberId,
      'amount': amount,
      'currency': currency,  // ✅ ADDED
      'status': status,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory TransferModel.fromJson(Map<String, dynamic> json) {
    return TransferModel(
      id: json['id'],
      familyId: json['familyId'],
      fromMemberId: json['fromMemberId'],
      toMemberId: json['toMemberId'],
      amount: json['amount']?.toDouble(),
      currency: json['currency'],  // ✅ ADDED
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      createdBy: json['createdBy'],
    );
  }
}
