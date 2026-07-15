// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // CREATE
  // ============================================================

  Future<String> create(String collection, Map<String, dynamic> data) async {
    try {
      final docRef = await _firestore.collection(collection).add(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create document: $e');
    }
  }

  Future<void> set(String collection, String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(id).set(data);
    } catch (e) {
      throw Exception('Failed to set document: $e');
    }
  }

  // ============================================================
  // READ
  // ============================================================

  Future<Map<String, dynamic>?> get(String collection, String id) async {
    try {
      final doc = await _firestore.collection(collection).doc(id).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get document: $e');
    }
  }

  // ✅ FIXED: Cast to List<Map<String, dynamic>>
  Future<List<Map<String, dynamic>>> getAll(String collection) async {
    try {
      final snapshot = await _firestore.collection(collection).get();
      return snapshot.docs.map((doc) => doc.data()).whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      throw Exception('Failed to get documents: $e');
    }
  }

  Future<List<Map<String, dynamic>>> query(
    String collection, {
    String? field,
    dynamic isEqualTo,
    String? isNotEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    List<Object?>? whereIn,
    List<Object?>? whereNotIn,
    bool? isNull,
    List<Map<String, dynamic>>? orderBy,
    int? limit,
    dynamic startAfter,
    dynamic endBefore,
    List<Object?>? arrayContainsAny,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (field != null) {
        if (isEqualTo != null) {
          query = query.where(field, isEqualTo: isEqualTo);
        } else if (isNotEqualTo != null) {
          query = query.where(field, isNotEqualTo: isNotEqualTo);
        } else if (isGreaterThan != null) {
          query = query.where(field, isGreaterThan: isGreaterThan);
        } else if (isGreaterThanOrEqualTo != null) {
          query = query.where(field, isGreaterThanOrEqualTo: isGreaterThanOrEqualTo);
        } else if (isLessThan != null) {
          query = query.where(field, isLessThan: isLessThan);
        } else if (isLessThanOrEqualTo != null) {
          query = query.where(field, isLessThanOrEqualTo: isLessThanOrEqualTo);
        } else if (isNull == true) {
          query = query.where(field, isNull: true);
        } else if (whereIn != null && whereIn.isNotEmpty) {
          query = query.where(field, whereIn: whereIn);
        } else if (whereNotIn != null && whereNotIn.isNotEmpty) {
          query = query.where(field, whereNotIn: whereNotIn);
        } else if (arrayContainsAny != null && arrayContainsAny.isNotEmpty) {
          query = query.where(field, arrayContainsAny: arrayContainsAny);
        }
      }

      if (orderBy != null) {
        for (var order in orderBy) {
          final field = order['field'] as String;
          final descending = order['descending'] as bool? ?? false;
          query = query.orderBy(field, descending: descending);
        }
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      if (startAfter != null) {
        query = query.startAfter([startAfter]);
      }

      if (endBefore != null) {
        query = query.endBefore([endBefore]);
      }

      final snapshot = await query.get();
      // ✅ FIXED: Cast to List<Map<String, dynamic>>
      return snapshot.docs.map((doc) => doc.data()).whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      throw Exception('Failed to query documents: $e');
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<void> update(String collection, String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update document: $e');
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> delete(String collection, String id) async {
    try {
      await _firestore.collection(collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  // ============================================================
  // BATCH
  // ============================================================

  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    try {
      final batch = _firestore.batch();
      
      for (var op in operations) {
        final type = op['type'] as String;
        final collection = op['collection'] as String;
        final id = op['id'] as String;
        final data = op['data'] as Map<String, dynamic>?;

        final docRef = _firestore.collection(collection).doc(id);

        if (type == 'set') {
          batch.set(docRef, data!);
        } else if (type == 'update') {
          batch.update(docRef, data!);
        } else if (type == 'delete') {
          batch.delete(docRef);
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch write: $e');
    }
  }

  // ============================================================
  // REAL-TIME STREAMS
  // ============================================================

  Stream<Map<String, dynamic>?> streamDocument(String collection, String id) {
    return _firestore.collection(collection).doc(id).snapshots().map(
      (doc) => doc.exists ? doc.data() : null,
    );
  }

  // ✅ FIXED: Cast to List<Map<String, dynamic>>
  Stream<List<Map<String, dynamic>>> streamCollection(String collection) {
    return _firestore.collection(collection).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.data()).whereType<Map<String, dynamic>>().toList(),
    );
  }

  // ✅ FIXED: Cast to List<Map<String, dynamic>>
  Stream<List<Map<String, dynamic>>> streamQuery(
    String collection, {
    String? field,
    dynamic isEqualTo,
    List<Map<String, dynamic>>? orderBy,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    if (field != null && isEqualTo != null) {
      query = query.where(field, isEqualTo: isEqualTo);
    }

    if (orderBy != null) {
      for (var order in orderBy) {
        final field = order['field'] as String;
        final descending = order['descending'] as bool? ?? false;
        query = query.orderBy(field, descending: descending);
      }
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.data()).whereType<Map<String, dynamic>>().toList(),
    );
  }

  // ============================================================
  // TRANSACTIONS
  // ============================================================

  Future<T> runTransaction<T>(Future<T> Function(Transaction) transaction) async {
    try {
      return await _firestore.runTransaction(transaction);
    } catch (e) {
      throw Exception('Transaction failed: $e');
    }
  }
}
