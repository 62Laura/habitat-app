// ignore_for_file: unused_import

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/habit_service.dart';
import 'auth_provider.dart';

// Habits state
class HabitsState {
  final List<Habit> habits;
  final String selectedFilter;
  final bool isLoading;
  final String? error;

  HabitsState({
    required this.habits,
    this.selectedFilter = 'All',
    this.isLoading = false,
    this.error,
  });

  HabitsState copyWith({
    List<Habit>? habits,
    String? selectedFilter,
    bool? isLoading,
    String? error,
  }) {
    return HabitsState(
      habits: habits ?? this.habits,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  List<Habit> get filteredHabits {
    switch (selectedFilter) {
      case 'Active':
        return habits.where((habit) => habit.completedDays < habit.totalDays).toList();
      case 'Completed':
        return habits.where((habit) => habit.completedDays >= habit.totalDays).toList();
      case 'Paused':
        return habits.where((habit) => habit.completedDays < habit.totalDays && habit.completedDays > 0).toList();
      default:
        return habits;
    }
  }
}

// Habits notifier
class HabitsNotifier extends StateNotifier<HabitsState> {
  HabitsNotifier() : super(HabitsState(habits: []));
  
  final HabitService _habitService = HabitService();
  StreamSubscription? _habitsSubscription;

  // Start listening to habits for the current user
  void startListening(String userId) {
    if (kDebugMode) print('HabitsNotifier: Starting to listen for habits for user: $userId');
    
    _habitsSubscription?.cancel();
    state = state.copyWith(isLoading: true, error: null);
    
    _habitsSubscription = _habitService.getUserHabits(userId).listen(
      (habits) {
        if (kDebugMode) print('HabitsNotifier: Received ${habits.length} habits');
        state = state.copyWith(
          habits: habits,
          isLoading: false,
          error: null,
        );
      },
      onError: (error) {
        if (kDebugMode) print('HabitsNotifier: Error loading habits - $error');
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load habits: $error',
        );
      },
    );
  }
  
  // Stop listening when user logs out
  void stopListening() {
    _habitsSubscription?.cancel();
    _habitsSubscription = null;
    state = state.copyWith(habits: [], isLoading: false, error: null);
  }
  
  @override
  void dispose() {
    _habitsSubscription?.cancel();
    super.dispose();
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  Future<void> addHabit(String name, String description, String frequency, String userId) async {
    state = state.copyWith(isLoading: true);
    
    try {
      final newHabit = Habit(
        id: '', // Will be set by Firestore
        name: name,
        description: description,
        frequency: frequency,
        completedDays: 0,
        totalDays: frequency == 'Daily' ? 30 : frequency == 'Weekly' ? 12 : 4,
        icon: 'star',
        color: 'blue',
        createdAt: DateTime.now(),
      );
      
      await _habitService.addHabit(newHabit, userId);
      // The stream listener will automatically update the state
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add habit: $e',
      );
    }
  }

  Future<void> updateHabit(String id, String name, String description, String frequency, String userId) async {
    state = state.copyWith(isLoading: true);
    
    try {
      final currentHabit = state.habits.firstWhere((habit) => habit.id == id);
      final updatedHabit = Habit(
        id: id,
        name: name,
        description: description,
        frequency: frequency,
        completedDays: currentHabit.completedDays,
        totalDays: frequency == 'Daily' ? 30 : frequency == 'Weekly' ? 12 : 4,
        icon: currentHabit.icon,
        color: currentHabit.color,
        createdAt: currentHabit.createdAt,
      );
      
      await _habitService.updateHabit(updatedHabit, userId);
      // The stream listener will automatically update the state
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update habit: $e',
      );
    }
  }

  Future<void> deleteHabit(String id, String userId) async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _habitService.deleteHabit(id, userId);
      // The stream listener will automatically update the state
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete habit: $e',
      );
    }
  }

  Future<void> markHabitComplete(String id, String userId) async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _habitService.markHabitComplete(id, userId);
      // The stream listener will automatically update the state
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update habit: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final habitsProvider = StateNotifierProvider<HabitsNotifier, HabitsState>((ref) {
  return HabitsNotifier();
});

final filteredHabitsProvider = Provider<List<Habit>>((ref) {
  final habitsState = ref.watch(habitsProvider);
  return habitsState.filteredHabits;
});