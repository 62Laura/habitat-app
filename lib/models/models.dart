// Data models for the refactored app (UI-focused versions without backend logic)

class Habit {
  final String id;
  final String name;
  final String description;
  final String frequency; // Daily, Weekly, Monthly
  final int completedDays;
  final int totalDays;
  final String icon;
  final String color;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.frequency,
    required this.completedDays,
    required this.totalDays,
    required this.icon,
    required this.color,
    required this.createdAt,
  });
}

class Goal {
  final String id;
  final String title;
  final String description;
  final double currentProgress;
  final double targetProgress;
  final String unit; // kg, pages, dollars, etc.
  final String icon;
  final String color;
  final String action; // Steps to achieve goal
  final DateTime createdAt;
  final DateTime? dueDate;

  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.currentProgress,
    required this.targetProgress,
    required this.unit,
    required this.icon,
    required this.color,
    required this.action,
    required this.createdAt,
    this.dueDate,
  });

  double get percentage => (currentProgress / targetProgress) * 100;
}

class User {
  final String id;
  final String email;
  final String? fullName;
  final String? profileImage;
  final DateTime createdAt;
  final bool notificationsEnabled;
  final bool darkModeEnabled;

  User({
    required this.id,
    required this.email,
    this.fullName,
    this.profileImage,
    required this.createdAt,
    this.notificationsEnabled = true,
    this.darkModeEnabled = false,
  });
}

class DailyHabitCheck {
  final String id;
  final String habitId;
  final DateTime date;
  final bool isCompleted;

  DailyHabitCheck({
    required this.id,
    required this.habitId,
    required this.date,
    required this.isCompleted,
  });
}
