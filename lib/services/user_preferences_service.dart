import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserPreferencesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get user preferences stream
  Stream<Map<String, dynamic>> getUserPreferencesStream() {
    final userId = currentUser?.uid;
    if (userId == null) {
      return Stream.value({});
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('preferences')
        .doc('settings')
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }

  // Get user preferences once
  Future<Map<String, dynamic>> getUserPreferences() async {
    final userId = currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('settings')
          .get();

      return doc.data() ?? {};
    } on FirebaseException catch (e) {
      if (kDebugMode) print('UserPreferencesService: Error getting preferences - $e');
      throw _getErrorMessage(e);
    } catch (e) {
      if (kDebugMode) print('UserPreferencesService: Unexpected error getting preferences - $e');
      throw 'Failed to load preferences: ${e.toString()}';
    }
  }

  // Update email preferences
  Future<void> updateEmailPreferences({
    bool? dailyReminders,
    bool? weeklySummary,
    bool? goalUpdates,
  }) async {
    final userId = currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final preferencesRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('settings');

      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (dailyReminders != null) updateData['emailDailyReminders'] = dailyReminders;
      if (weeklySummary != null) updateData['emailWeeklySummary'] = weeklySummary;
      if (goalUpdates != null) updateData['emailGoalUpdates'] = goalUpdates;

      await preferencesRef.set(updateData, SetOptions(merge: true));

      if (kDebugMode) print('UserPreferencesService: Email preferences updated');
    } on FirebaseException catch (e) {
      if (kDebugMode) print('UserPreferencesService: Error updating email preferences - $e');
      throw _getErrorMessage(e);
    } catch (e) {
      if (kDebugMode) print('UserPreferencesService: Unexpected error updating email preferences - $e');
      throw 'Failed to update email preferences: ${e.toString()}';
    }
  }

  // Update notification settings
  Future<void> updateNotificationSettings({
    bool? enabled,
  }) async {
    final userId = currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final preferencesRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('settings');

      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (enabled != null) updateData['notificationsEnabled'] = enabled;

      await preferencesRef.set(updateData, SetOptions(merge: true));

      if (kDebugMode) print('UserPreferencesService: Notification settings updated');
    } on FirebaseException catch (e) {
      if (kDebugMode) print('UserPreferencesService: Error updating notification settings - $e');
      throw _getErrorMessage(e);
    } catch (e) {
      if (kDebugMode) print('UserPreferencesService: Unexpected error updating notification settings - $e');
      throw 'Failed to update notification settings: ${e.toString()}';
    }
  }

  // updateLanguage method removed - language switcher functionality deleted

  // Export user data
  Future<Map<String, dynamic>> exportUserData() async {
    final userId = currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get user profile
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      // Get goals
      final goalsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .get();
      
      // Get habits (if they exist)
      final habitsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .get();

      return {
        'user': userDoc.data(),
        'goals': goalsSnapshot.docs.map((doc) => doc.data()).toList(),
        'habits': habitsSnapshot.docs.map((doc) => doc.data()).toList(),
        'exportedAt': Timestamp.now(),
      };
    } on FirebaseException catch (e) {
      if (kDebugMode) print('UserPreferencesService: Error exporting data - $e');
      throw _getErrorMessage(e);
    } catch (e) {
      if (kDebugMode) print('UserPreferencesService: Unexpected error exporting data - $e');
      throw 'Failed to export data: ${e.toString()}';
    }
  }

  // Import user data
  Future<void> importUserData(Map<String, dynamic> data) async {
    final userId = currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final batch = _firestore.batch();

      // Import goals
      if (data['goals'] != null) {
        final goalsRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('goals');
        
        for (final goal in data['goals']) {
          final docRef = goalsRef.doc();
          batch.set(docRef, {
            ...goal,
            'importedAt': Timestamp.now(),
          });
        }
      }

      // Import habits
      if (data['habits'] != null) {
        final habitsRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('habits');
        
        for (final habit in data['habits']) {
          final docRef = habitsRef.doc();
          batch.set(docRef, {
            ...habit,
            'importedAt': Timestamp.now(),
          });
        }
      }

      await batch.commit();

      if (kDebugMode) print('UserPreferencesService: Data imported successfully');
    } on FirebaseException catch (e) {
      if (kDebugMode) print('UserPreferencesService: Error importing data - $e');
      throw _getErrorMessage(e);
    } catch (e) {
      if (kDebugMode) print('UserPreferencesService: Unexpected error importing data - $e');
      throw 'Failed to import data: ${e.toString()}';
    }
  }

  // Clear cache (placeholder - actual cache clearing would be platform-specific)
  Future<void> clearCache() async {
    try {
      // This is a placeholder for cache clearing functionality
      // In a real app, you might clear local storage, image cache, etc.
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (kDebugMode) print('UserPreferencesService: Cache cleared');
    } catch (e) {
      if (kDebugMode) print('UserPreferencesService: Error clearing cache - $e');
      throw 'Failed to clear cache: ${e.toString()}';
    }
  }

  // Get user-friendly error messages
  String _getErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You don\'t have permission to access these settings.';
      case 'not-found':
        return 'Settings not found.';
      case 'unavailable':
        return 'Service is temporarily unavailable. Please try again.';
      case 'deadline-exceeded':
        return 'Request timed out. Please check your connection and try again.';
      case 'unauthenticated':
        return 'You must be signed in to access settings.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
