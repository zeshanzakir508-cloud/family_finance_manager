// lib/services/goal_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/goal_model.dart';

class GoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // CREATE
  // ============================================================

  Future<String> createGoal(GoalModel goal) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final data = goal.toJson();
      data['userId'] = user.uid;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection('goals').add(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create goal: $e');
    }
  }

  // ============================================================
  // READ
  // ============================================================

  Future<List<GoalModel>> getGoalsByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('goals')
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: false)
          .orderBy('deadline')
          .get();

      return snapshot.docs
          .map((doc) => GoalModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get goals: $e');
    }
  }

  Future<List<GoalModel>> getCompletedGoalsByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('goals')
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: true)
          .orderBy('completedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => GoalModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get completed goals: $e');
    }
  }

  Future<List<GoalModel>> getGoalsByFamily(String familyId) async {
    try {
      final snapshot = await _firestore
          .collection('goals')
          .where('familyId', isEqualTo: familyId)
          .where('isCompleted', isEqualTo: false)
          .orderBy('deadline')
          .get();

      return snapshot.docs
          .map((doc) => GoalModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get family goals: $e');
    }
  }

  Future<GoalModel?> getGoalById(String id) async {
    try {
      final doc = await _firestore.collection('goals').doc(id).get();
      if (!doc.exists) return null;
      return GoalModel.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get goal: $e');
    }
  }

  Stream<List<GoalModel>> streamGoalsByUser(String userId) {
    return _firestore
        .collection('goals')
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: false)
        .orderBy('deadline')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GoalModel.fromJson(doc.data()))
            .toList());
  }

  Stream<List<GoalModel>> streamCompletedGoalsByUser(String userId) {
    return _firestore
        .collection('goals')
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: true)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GoalModel.fromJson(doc.data()))
            .toList());
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<void> updateGoal(String id, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('goals').doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update goal: $e');
    }
  }

  // ============================================================
  // CONTRIBUTIONS
  // ============================================================

  Future<void> addContribution(String goalId, double amount, {String? note}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final doc = await _firestore.collection('goals').doc(goalId).get();
      if (!doc.exists) throw Exception('Goal not found');

      final goal = GoalModel.fromJson(doc.data()!);
      if (goal.userId != user.uid) {
        throw Exception('You can only contribute to your own goals');
      }
      if (goal.isAchieved) {
        throw Exception('Goal is already completed');
      }

      final updatedGoal = goal.addContribution(amount, note: note);

      await _firestore.collection('goals').doc(goalId).update({
        'currentAmount': updatedGoal.currentAmount,
        'contributions': updatedGoal.contributions?.map((c) => c.toJson()).toList(),
        'isCompleted': updatedGoal.isCompleted,
        'completedAt': updatedGoal.completedAt != null 
            ? Timestamp.fromDate(updatedGoal.completedAt!) 
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add contribution: $e');
    }
  }

  Future<void> removeContribution(String goalId, String contributionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final doc = await _firestore.collection('goals').doc(goalId).get();
      if (!doc.exists) throw Exception('Goal not found');

      final goal = GoalModel.fromJson(doc.data()!);
      if (goal.userId != user.uid) {
        throw Exception('You can only remove contributions from your own goals');
      }

      final contributions = goal.contributions ?? [];
      final contribution = contributions.firstWhere(
        (c) => c.id == contributionId,
        orElse: () => throw Exception('Contribution not found'),
      );

      final updatedContributions = contributions.where((c) => c.id != contributionId).toList();
      final newCurrentAmount = (goal.currentAmount ?? 0.0) - contribution.amount;

      await _firestore.collection('goals').doc(goalId).update({
        'currentAmount': newCurrentAmount,
        'contributions': updatedContributions.map((c) => c.toJson()).toList(),
        'isCompleted': false,
        'completedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove contribution: $e');
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteGoal(String id) async {
    try {
      await _firestore.collection('goals').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete goal: $e');
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Future<double> getTotalSaved(String userId) async {
    try {
      final goals = await getGoalsByUser(userId);
      final completed = await getCompletedGoalsByUser(userId);
      
      double totalSaved = 0.0;
      
      for (var goal in goals) {
        totalSaved += goal.currentAmount ?? 0.0;
      }
      
      for (var goal in completed) {
        totalSaved += goal.currentAmount ?? 0.0;
      }
      
      return totalSaved;
    } catch (e) {
      return 0.0;
    }
  }

  Future<int> getActiveGoalsCount(String userId) async {
    try {
      final goals = await getGoalsByUser(userId);
      return goals.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getCompletedGoalsCount(String userId) async {
    try {
      final goals = await getCompletedGoalsByUser(userId);
      return goals.length;
    } catch (e) {
      return 0;
    }
  }

  Future<List<GoalModel>> getOverdueGoals(String userId) async {
    try {
      final goals = await getGoalsByUser(userId);
      return goals.where((g) => g.isOverdue).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<GoalModel>> getOnTrackGoals(String userId) async {
    try {
      final goals = await getGoalsByUser(userId);
      return goals.where((g) => g.isOnTrack).toList();
    } catch (e) {
      return [];
    }
  }

  Future<double> getGoalProgressPercentage(String goalId) async {
    try {
      final goal = await getGoalById(goalId);
      if (goal == null) return 0.0;
      return goal.progress * 100;
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> getAverageCompletionRate(String userId) async {
    try {
      final total = await getGoalsByUser(userId);
      final completed = await getCompletedGoalsByUser(userId);
      
      if (total.isEmpty) return 0.0;
      return (completed.length / total.length) * 100;
    } catch (e) {
      return 0.0;
    }
  }
}
