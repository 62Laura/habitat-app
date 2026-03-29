// ignore_for_file: deprecated_member_use, unnecessary_import, unused_local_variable, unused_field, prefer_const_constructors
// Note: Container with LinearGradient and BorderRadius.circular cannot be const.
// This warning is acceptable and unavoidable.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../habit/habit_screen.dart';
import '../goal/goal_screen.dart';
import '../settings_screen.dart';
import '../../providers/auth_provider_provider.dart';
import '../../providers/habits_provider.dart';
import '../../providers/goals_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  final Map<String, bool> _completedHabitsToday = {};

  final List<String> _titles = ['Home', 'Habits', 'Goals', 'Settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeContent(context),
          const HabitScreen(),
          const GoalScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authProvider);
        final habitsState = ref.watch(habitsProvider);
        final goalsState = ref.watch(goalsProvider);
        
        final user = authState.user;
        // Extract first name only from the full name
        final firstName = authState.userName?.split(' ').first ?? user?.displayName?.split(' ').first ?? user?.email?.split('@')[0] ?? 'User';
        final displayName = firstName;
        final habits = habitsState.habits;
        final goals = goalsState.goals;
        
        // Calculate statistics
        final activeHabits = habits.where((h) => h.completedDays < h.totalDays).length;
        final completedToday = _completedHabitsToday.values.where((completed) => completed).length;
        
        // Get today's habits (first 4 for display)
        final todayHabits = habits.take(4).toList();
        
        // Get recent goals (first 2 for display)
        final recentGoals = goals.take(2).toList();

        if (habitsState.isLoading || goalsState.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: context.primaryColor,
            ),
          );
        }

        if (habitsState.error != null || goalsState.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: context.errorColor,
                ),
                SizedBox(height: AppTheme.spacing16),
                Text(
                  'Something went wrong',
                  style: AppTheme.headingSmall.copyWith(
                    color: context.errorColor,
                  ),
                ),
                SizedBox(height: AppTheme.spacing8),
                Text(
                  habitsState.error ?? goalsState.error ?? 'Unknown error',
                  style: AppTheme.bodyMedium.copyWith(
                    color: context.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppTheme.spacing24),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: AppTheme.radiusLarge,
                  boxShadow: AppTheme.shadowMedium,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back!',
                                style: AppTheme.headingSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: AppTheme.spacing4),
                              Text(
                                displayName,
                                style: AppTheme.headingLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(AppTheme.spacing12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: AppTheme.radiusMedium,
                          ),
                          child: Icon(
                            Icons.waving_hand,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacing16),
                    Text(
                      'Ready to build better habits today?',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppTheme.spacing32),
              // Stats Section
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Active Habits',
                      activeHabits.toString(),
                      Icons.track_changes,
                      AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: _buildStatCard(
                      'Completed Today',
                      completedToday.toString(),
                      Icons.check_circle,
                      AppTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacing32),
              // Today's Habits Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Habits",
                    style: AppTheme.headingMedium,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 1; // Navigate to habits tab
                      });
                    },
                    icon: Icon(Icons.arrow_forward, size: 16),
                    label: Text('See all'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacing16),
              if (todayHabits.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppTheme.spacing24),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: AppTheme.radiusMedium,
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.track_changes_outlined,
                        size: 48,
                        color: context.textSecondaryColor,
                      ),
                      SizedBox(height: AppTheme.spacing16),
                      Text(
                        'No habits for today',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacing8),
                      Text(
                        'Create your first habit to start tracking',
                        style: AppTheme.bodyMedium.copyWith(
                          color: context.textSecondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppTheme.spacing16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedIndex = 1; // Navigate to habits tab
                          });
                        },
                        icon: Icon(Icons.add),
                        label: Text('Create Habit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...todayHabits.asMap().entries.map((entry) {
                  final index = entry.key;
                  final habit = entry.value;
                  final isCompleted = _completedHabitsToday[habit.id] ?? false;
                  return _buildHabitItem(
                    habit,
                    isCompleted,
                    (bool? value) {
                      setState(() {
                        _completedHabitsToday[habit.id] = value ?? false;
                      });
                      
                    },
                  );
                }).toList(),
              SizedBox(height: AppTheme.spacing32),
              // Goals Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Goals',
                    style: AppTheme.headingMedium,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 2; // Navigate to goals tab
                      });
                    },
                    icon: Icon(Icons.arrow_forward, size: 16),
                    label: Text('See all'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacing16),
              if (recentGoals.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppTheme.spacing24),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: AppTheme.radiusMedium,
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 48,
                        color: context.textSecondaryColor,
                      ),
                      SizedBox(height: AppTheme.spacing16),
                      Text(
                        'No goals yet',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacing8),
                      Text(
                        'Set your first goal to start tracking progress',
                        style: AppTheme.bodyMedium.copyWith(
                          color: context.textSecondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppTheme.spacing16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedIndex = 2; // Navigate to goals tab
                          });
                        },
                        icon: Icon(Icons.add),
                        label: Text('Create Goal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...recentGoals.map((goal) {
                  return _buildGoalItem(goal);
                }).toList(),
            ],
          ),
        ),
      );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppTheme.radiusMedium,
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(AppTheme.spacing8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppTheme.radiusSmall,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(height: AppTheme.spacing12),
          Text(
            value,
            style: AppTheme.headingLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppTheme.spacing4),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: context.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitItem(Habit habit, bool isCompleted, Function(bool?) onChanged) {
    final color = _getColorFromString(habit.color);
    
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacing12),
      padding: EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: isCompleted ? color.withValues(alpha: 0.05) : context.surfaceColor,
        border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
          width: isCompleted ? 2 : 1,
        ),
        borderRadius: AppTheme.radiusMedium,
        boxShadow: isCompleted ? AppTheme.shadowSmall : null,
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted ? color : Colors.transparent,
              border: Border.all(
                color: isCompleted ? color : AppTheme.borderMedium,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isCompleted
                ? Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  )
                : null,
          ),
          SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? context.textSecondaryColor
                        : context.textPrimaryColor,
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                if (habit.description.isNotEmpty) ...[
                  SizedBox(height: AppTheme.spacing4),
                  Text(
                    habit.description,
                    style: AppTheme.bodySmall.copyWith(
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
                SizedBox(height: AppTheme.spacing8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing8,
                        vertical: AppTheme.spacing2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: AppTheme.radiusSmall,
                      ),
                      child: Text(
                        '${habit.completedDays}/${habit.totalDays} days',
                        style: AppTheme.caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: AppTheme.spacing8),
                    Text(
                      '${((habit.completedDays / habit.totalDays) * 100).toStringAsFixed(0)}%',
                      style: AppTheme.caption.copyWith(
                        color: context.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: AppTheme.spacing8),
          GestureDetector(
            onTap: () => onChanged(!isCompleted),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted ? color : Colors.transparent,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: isCompleted
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(Goal goal) {
    final color = _getColorFromString(goal.color);
    final progress = goal.percentage / 100;
    
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacing16),
      padding: EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppTheme.radiusMedium,
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppTheme.spacing8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: AppTheme.radiusSmall,
                ),
                child: Icon(
                  _getIconFromString(goal.icon),
                  color: color,
                  size: 20,
                ),
              ),
              SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (goal.description.isNotEmpty) ...[
                      SizedBox(height: AppTheme.spacing4),
                      Text(
                        goal.description,
                        style: AppTheme.bodySmall.copyWith(
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing8,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: AppTheme.radiusSmall,
                ),
                child: Text(
                  '${goal.percentage.toStringAsFixed(0)}%',
                  style: AppTheme.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacing16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: AppTheme.bodySmall.copyWith(
                  color: context.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${goal.currentProgress.toStringAsFixed(1)} / ${goal.targetProgress.toStringAsFixed(1)} ${goal.unit}',
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacing8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorFromString(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'red':
        return AppTheme.error;
      case 'green':
        return AppTheme.secondaryColor;
      case 'blue':
        return AppTheme.primaryColor;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return AppTheme.accentColor;
      case 'cyan':
        return Colors.cyan;
      case 'skyblue':
        return const Color(0xFF42A5F5);
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getIconFromString(String iconString) {
    switch (iconString.toLowerCase()) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'menu_book':
        return Icons.menu_book;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'language':
        return Icons.language;
      case 'water_drop':
        return Icons.water_drop;
      case 'star':
        return Icons.star;
      case 'savings':
        return Icons.savings;
      default:
        return Icons.star;
    }
  }

  @override
  void dispose() {
    // Stop listening to habits and goals when the home screen is disposed
    ref.read(habitsProvider.notifier).stopListening();
    ref.read(goalsProvider.notifier).stopListening();
    super.dispose();
  }
}
