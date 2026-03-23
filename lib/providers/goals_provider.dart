// ignore_for_file: unused_import

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/goal_service.dart';
import '../providers/auth_provider_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

// Goals state
class GoalsState {
  final List<Goal> goals;
  final String selectedFilter;
  final bool isLoading;
  final String? error;

  GoalsState({
    required this.goals,
    this.selectedFilter = 'All',
    this.isLoading = false,
    this.error,
  });

  GoalsState copyWith({
    List<Goal>? goals,
    String? selectedFilter,
    bool? isLoading,
    String? error,
  }) {
    return GoalsState(
      goals: goals ?? this.goals,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  List<Goal> get filteredGoals {
    switch (selectedFilter) {
      case 'In Progress':
        return goals.where((goal) => goal.currentProgress < goal.targetProgress).toList();
      case 'Completed':
        return goals.where((goal) => goal.currentProgress >= goal.targetProgress).toList();
      default:
        return goals;
    }
  }
}

// Goals notifier
class GoalsNotifier extends StateNotifier<GoalsState> {
  final GoalService _goalService = GoalService();
  StreamSubscription<List<Goal>>? _goalsSubscription;
  StreamSubscription? _authSubscription;

  GoalsNotifier() : super(GoalsState(goals: [], isLoading: true)) {
    _initializeGoals();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

  void _initializeGoals() {
    // Listen to auth state changes
    _authSubscription?.cancel();
    _authSubscription = _goalService.authStateChanges().listen((user) {
      if (user != null) {
        _startListeningToGoals(user.uid);
      } else {
        _stopListeningToGoals();
      }
    });
  }

  void _startListeningToGoals(String userId) {
    if (kDebugMode) print('GoalsNotifier: Starting to listen for goals for user: $userId');
    
    _goalsSubscription?.cancel();
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      _goalsSubscription = _goalService.getUserGoalsStream(userId).listen(
        (goals) {
          if (kDebugMode) print('GoalsNotifier: Received ${goals.length} goals');
          state = state.copyWith(
            goals: goals,
            isLoading: false,
            error: null,
          );
        },
        onError: (error) {
          if (kDebugMode) print('GoalsNotifier: Error loading goals - $error');
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to load goals: $error',
          );
        },
      );
    } catch (e) {
      if (kDebugMode) print('GoalsNotifier: Failed to initialize goals stream - $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load goals: $e',
      );
    }
  }

  void _stopListeningToGoals() {
    if (kDebugMode) print('GoalsNotifier: Stopping to listen for goals');
    _goalsSubscription?.cancel();
    _goalsSubscription = null;
    state = state.copyWith(goals: [], isLoading: false, error: null);
  }

  // Public method to stop listening (called from screens)
  void stopListening() {
    _stopListeningToGoals();
    _authSubscription?.cancel();
    _authSubscription = null;
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  Future<void> addGoal(String title, String description, double target, String action) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _goalService.addGoal(
        title: title,
        description: description,
        targetProgress: target,
        action: action,
      );
      
      if (kDebugMode) print('GoalsNotifier: Goal added successfully');
      // The stream will automatically update the state
    } catch (e) {
      if (kDebugMode) print('GoalsNotifier: Failed to add goal - $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add goal: $e',
      );
    }
  }

  Future<void> updateGoal(String id, String title, String description, double target, String action) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _goalService.updateGoal(
        id: id,
        title: title,
        description: description,
        targetProgress: target,
        action: action,
      );
      
      if (kDebugMode) print('GoalsNotifier: Goal $id updated successfully');
      // The stream will automatically update the state
    } catch (e) {
      if (kDebugMode) print('GoalsNotifier: Failed to update goal - $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update goal: $e',
      );
    }
  }

  Future<void> deleteGoal(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _goalService.deleteGoal(id);
      
      if (kDebugMode) print('GoalsNotifier: Goal $id deleted successfully');
      // The stream will automatically update the state
    } catch (e) {
      if (kDebugMode) print('GoalsNotifier: Failed to delete goal - $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete goal: $e',
      );
    }
  }

  Future<void> updateGoalProgress(String id, double currentProgress) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _goalService.updateGoalProgress(
        id: id,
        currentProgress: currentProgress,
      );
      
      if (kDebugMode) print('GoalsNotifier: Goal progress updated for $id');
      // The stream will automatically update the state
    } catch (e) {
      if (kDebugMode) print('GoalsNotifier: Failed to update goal progress - $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update goal progress: $e',
      );
    }
  }

  // Refresh goals manually
  Future<void> refreshGoals() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final goals = await _goalService.getGoals();
      state = state.copyWith(
        goals: goals,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      if (kDebugMode) print('GoalsNotifier: Failed to refresh goals - $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to refresh goals: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final goalsProvider = StateNotifierProvider<GoalsNotifier, GoalsState>((ref) {
  return GoalsNotifier();
});

final filteredGoalsProvider = Provider<List<Goal>>((ref) {
  final goalsState = ref.watch(goalsProvider);
  return goalsState.filteredGoals;
});
