import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/models.dart';
import 'package:flutter/foundation.dart';

class GoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // Get current user
  auth.User? get currentUser => _auth.currentUser;

  // Get auth state changes
  Stream<auth.User?> authStateChanges() => _auth.authStateChanges();

  // Get goals stream for specific user
  Stream<List<Goal>> getUserGoalsStream(String userId) {
    if (kDebugMode) print('GoalService: Getting goals for user: $userId');
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('goals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          if (kDebugMode) print('GoalService: Received ${snapshot.docs.length} goals');
          return snapshot.docs
              .map((doc) => _docToGoal(doc.id, doc.data()))
              .toList();
        })
        .handleError((error) {
          if (kDebugMode) print('GoalService: Error loading goals - $error');
          throw Exception('Failed to load goals: $error');
        });
  }

  // Get goals stream for current user
  Stream<List<Goal>> getGoalsStream() {
    final userId = currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('goals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _docToGoal(doc.id, doc.data()))
            .toList());
  }

  // Get goals once (for non-reactive usage)
  Future<List<Goal>> getGoals() async {
    final userId = currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => _docToGoal(doc.id, doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      if (kDebugMode) print('GoalService: Error getting goals - $e');
      throw _getErrorMessage(e);
    } catch (e) {
      if (kDebugMode) print('GoalService: Unexpected error getting goals - $e');
      throw 'Failed to load goals: ${e.toString()}';
    }
  }

  // Add a new goal
  Future<String> addGoal({
    required String title,
    required String description,
    required double targetProgress,
    required String action,
    required String frequency,
    String unit = 'units',
    String icon = 'star',
    String color = 'blue',
  }) async {
    final userId = currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .add({
        'title': title,
        'description': description,
        'currentProgress': 0.0,
        'targetProgress': targetProgress,
        'unit': unit,
        'icon': icon,
        'color': color,
        'action': action,
        'frequency': frequency,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      if (kDebugMode) print('GoalService: Goal added with ID: ${docRef.id}');
      return docRef.id;
    } on FirebaseException catch (e) {
      if (kDebugMode) print('GoalService: Error adding goal - $e');
      throw _getErrorMessage(e);
    } catch (e) {
      if (kDebugMode) print('GoalService: Unexpected error adding goal - $e');
      throw 'Failed to add goal: ${e.toString()}';
    }
  }

  // Update an existing goal
  Future<void> updateGoal({
    required String id,
    required String title,
    required String description,
    required double targetProgress,
    required String action,
    required String frequency,
  }) async {
    final userId = currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(id)
          .update({
        'title': title,
        'description': description,
        'targetProgress': targetProgress,
        'action': action,
        'frequency': frequency,
        'updatedAt': Timestamp.now(),
      });

      if (kDebugMode) print('GoalService: Goal $id updated successfully');
    } on FirebaseException catch (e) {
      if (kDebugMode) print('GoalService: Error updating goal - $e');
      throw _getErrorMessage(e);
    } catch (e) {
      if (kDebugMode) print('GoalService: Unexpected error updating goal - $e');
      throw 'Failed to update goal: ${e.toString()}';
    }
  }

  // Update goal progress
  Future<void> updateGoalProgress({
    required String id,
    required double currentProgress,
  }) async {
    final userId = currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(id)
          .update({
        'currentProgress': currentProgress,
        'updatedAt': Timestamp.now(),
      });

      if (kDebugMode) print('GoalService: Goal progress updated for $id');
    } on FirebaseException catch (e) {
      if (kDebugMode) print('GoalService: Error updating goal progress - $e');
      throw _getErrorMessage(e);
    } catch (e) {
      if (kDebugMode) print('GoalService: Unexpected error updating goal progress - $e');
      throw 'Failed to update goal progress: ${e.toString()}';
    }
  }

  // Delete a goal
  Future<void> deleteGoal(String id) async {
    final userId = currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(id)
          .delete();

      if (kDebugMode) print('GoalService: Goal $id deleted successfully');
    } on FirebaseException catch (e) {
      if (kDebugMode) print('GoalService: Error deleting goal - $e');
      throw _getErrorMessage(e);
    } catch (e) {
      if (kDebugMode) print('GoalService: Unexpected error deleting goal - $e');
      throw 'Failed to delete goal: ${e.toString()}';
    }
  }

  // Convert Firestore document to Goal object
  Goal _docToGoal(String id, Map<String, dynamic> data) {
    return Goal(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      currentProgress: (data['currentProgress'] ?? 0).toDouble(),
      targetProgress: (data['targetProgress'] ?? 0).toDouble(),
      unit: data['unit'] ?? 'units',
      icon: data['icon'] ?? 'star',
      color: data['color'] ?? 'blue',
      action: data['action'] ?? '',
      frequency: data['frequency'] ?? 'daily',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
    );
  }

  // Get user-friendly error messages
  String _getErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You don\'t have permission to access these goals.';
      case 'not-found':
        return 'Goal not found.';
      case 'unavailable':
        return 'Service is temporarily unavailable. Please try again.';
      case 'deadline-exceeded':
        return 'Request timed out. Please check your connection and try again.';
      case 'unauthenticated':
        return 'You must be signed in to access goals.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
