// ignore_for_file: avoid_types_as_parameter_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class HabitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'habits';

  // Get all habits for a user
  Stream<List<Habit>> getUserHabits(String userId) {
    if (kDebugMode) print('HabitService: Getting habits for user: $userId');
    
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          if (kDebugMode) print('HabitService: Received ${snapshot.docs.length} habits');
          final habits = snapshot.docs
              .map((doc) => _mapDocumentToHabit(doc))
              .toList();
          // Sort client-side by createdAt (descending) until index is created
          habits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return habits;
        })
        .handleError((error) {
          if (kDebugMode) print('HabitService: Error loading habits - $error');
          throw Exception('Failed to load habits: $error');
        });
  }

  // Add a new habit
  Future<String> addHabit(Habit habit, String userId) async {
    try {
      final docRef = await _firestore.collection(_collection).add({
        'userId': userId,
        'name': habit.name,
        'description': habit.description,
        'frequency': habit.frequency,
        'completedDays': habit.completedDays,
        'totalDays': habit.totalDays,
        'icon': habit.icon,
        'color': habit.color,
        'createdAt': Timestamp.fromDate(habit.createdAt),
        'updatedAt': Timestamp.now(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add habit: $e');
    }
  }

  // Update an existing habit
  Future<void> updateHabit(Habit habit, String userId) async {
    try {
      await _firestore.collection(_collection).doc(habit.id).update({
        'name': habit.name,
        'description': habit.description,
        'frequency': habit.frequency,
        'completedDays': habit.completedDays,
        'totalDays': habit.totalDays,
        'icon': habit.icon,
        'color': habit.color,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update habit: $e');
    }
  }

  // Delete a habit
  Future<void> deleteHabit(String habitId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(habitId).delete();
    } catch (e) {
      throw Exception('Failed to delete habit: $e');
    }
  }

  // Mark habit as complete for today
  Future<void> markHabitComplete(String habitId, String userId) async {
    try {
      final docRef = _firestore.collection(_collection).doc(habitId);
      
      // Use a transaction to safely increment the completed days
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) {
          throw Exception('Habit not found');
        }
        
        final data = doc.data()!;
        final completedDays = data['completedDays'] as int;
        final totalDays = data['totalDays'] as int;
        
        // Only increment if not already completed
        if (completedDays < totalDays) {
          transaction.update(docRef, {
            'completedDays': completedDays + 1,
            'updatedAt': Timestamp.now(),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to mark habit complete: $e');
    }
  }

  // Get habit statistics
  Future<Map<String, dynamic>> getHabitStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();
      
      final habits = snapshot.docs.map((doc) => _mapDocumentToHabit(doc)).toList();
      
      int totalHabits = habits.length;
      int activeHabits = habits.where((h) => h.completedDays < h.totalDays).length;
      int completedHabits = habits.where((h) => h.completedDays >= h.totalDays).length;
      
      double overallProgress = totalHabits > 0 
          ? habits.fold(0.0, (sum, habit) => sum + (habit.completedDays / habit.totalDays)) / totalHabits
          : 0.0;
      
      return {
        'totalHabits': totalHabits,
        'activeHabits': activeHabits,
        'completedHabits': completedHabits,
        'overallProgress': overallProgress,
      };
    } catch (e) {
      throw Exception('Failed to get habit stats: $e');
    }
  }

  // Helper method to map Firestore document to Habit model
  Habit _mapDocumentToHabit(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Habit(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      frequency: data['frequency'] ?? 'Daily',
      completedDays: data['completedDays'] ?? 0,
      totalDays: data['totalDays'] ?? 30,
      icon: data['icon'] ?? 'star',
      color: data['color'] ?? 'blue',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
