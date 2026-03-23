import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/habits_provider.dart';
import '../../providers/auth_provider_provider.dart';
import '../../theme/app_theme.dart';

class HabitScreen extends ConsumerStatefulWidget {
  const HabitScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends ConsumerState<HabitScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All', 'Active', 'Completed', 'Paused'];
  HabitsNotifier? _habitsNotifier;

  @override
  void initState() {
    super.initState();
    // Start listening to habits when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (kDebugMode) print('HabitScreen: Auth state user: ${authState.user}');
      if (authState.user != null) {
        if (kDebugMode) print('HabitScreen: Starting to listen for habits for user: ${authState.user!.uid}');
        _habitsNotifier = ref.read(habitsProvider.notifier);
        _habitsNotifier?.startListening(authState.user!.uid);
      } else {
        if (kDebugMode) print('HabitScreen: No user found, not starting habits listener');
      }
    });
  }

  @override
  void dispose() {
    // Stop listening when the screen is disposed using the cached notifier
    _habitsNotifier?.stopListening();
    _habitsNotifier = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habitsState = ref.watch(habitsProvider);
    final authState = ref.watch(authProvider);
    final habitsNotifier = ref.read(habitsProvider.notifier);
    
    if (kDebugMode) print('HabitScreen: Building - authState.user: ${authState.user}, habitsState.error: ${habitsState.error}');
    
    // Update filter when index changes
    if (habitsState.selectedFilter != _filters[_selectedFilterIndex]) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        habitsNotifier.setFilter(_filters[_selectedFilterIndex]);
      });
    }
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          if (authState.user != null) {
            habitsNotifier.stopListening();
            habitsNotifier.startListening(authState.user!.uid);
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    _filters.length,
                    (index) => _buildFilterChip(_filters[index], index == _selectedFilterIndex, index),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Loading indicator
              if (habitsState.isLoading)
                const Center(child: CircularProgressIndicator())
              
              // Error message
              else if (habitsState.error != null)
                _buildErrorMessage(habitsState.error!, habitsNotifier)
              
              // Empty state
              else if (habitsState.habits.isEmpty)
                _buildEmptyState()
              
              // Habits List
              else
                ...habitsState.filteredHabits.map((habit) => _buildHabitCard(habit)).toList(),
            ],
          ),
        ),
      ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'habit_screen_fab',
        onPressed: () {
          if (authState.user != null) {
            _showCreateHabitDialog();
          }
        },
        backgroundColor: AppTheme.primaryColor,
        child: habitsState.isLoading 
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilterIndex = index;
          });
        },
        selectedColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    final color = _getColorFromString(habit.color);
    final icon = _getIconFromString(habit.icon);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      habit.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Edit'),
                    onTap: () => _editHabit(habit),
                  ),
                  PopupMenuItem(
                    child: const Text('Delete'),
                    onTap: () => _deleteHabit(habit.id),
                  ),
                  PopupMenuItem(
                    child: const Text('Mark Complete'),
                    onTap: () => _markHabitComplete(habit.id),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${habit.completedDays}/${habit.totalDays} days completed',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              Text(
                '${((habit.completedDays / habit.totalDays) * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: habit.completedDays / habit.totalDays,
              minHeight: 6,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateHabitDialog({Habit? habit}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(habit == null ? 'Create New Habit' : 'Edit Habit'),
        content: CreateHabitForm(
          habit: habit,
          onSave: (name, description, frequency) {
            if (habit == null) {
              _addHabit(name, description, frequency);
            } else {
              _updateHabit(habit.id, name, description, frequency);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _addHabit(String name, String description, String frequency) {
    final user = ref.read(authProvider);
    if (user.user != null) {
      ref.read(habitsProvider.notifier).addHabit(name, description, frequency, user.user!.uid);
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Habit created!')),
    );
  }

  void _updateHabit(String id, String name, String description, String frequency) {
    final user = ref.read(authProvider);
    if (user.user != null) {
      ref.read(habitsProvider.notifier).updateHabit(id, name, description, frequency, user.user!.uid);
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Habit updated!')),
    );
  }

  void _editHabit(Habit habit) {
    _showCreateHabitDialog(habit: habit);
  }

  void _deleteHabit(String id) {
    final user = ref.read(authProvider);
    if (user.user != null) {
      ref.read(habitsProvider.notifier).deleteHabit(id, user.user!.uid);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Habit deleted!')),
    );
  }

  void _markHabitComplete(String id) {
    final user = ref.read(authProvider);
    if (user.user != null) {
      ref.read(habitsProvider.notifier).markHabitComplete(id, user.user!.uid);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Habit progress updated!')),
    );
  }

  Widget _buildErrorMessage(String error, HabitsNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: notifier.clearError,
            color: Colors.red[700],
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.track_changes,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No habits yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first habit to start tracking your progress',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorFromString(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'cyan':
        return Colors.cyan;
      case 'skyblue':
        return const Color(0xFF42A5F5);
      default:
        return Colors.blue;
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
      default:
        return Icons.star;
    }
  }
}

class CreateHabitForm extends StatefulWidget {
  final Habit? habit;
  final Function(String name, String description, String frequency) onSave;
  
  const CreateHabitForm({Key? key, this.habit, required this.onSave}) : super(key: key);

  @override
  State<CreateHabitForm> createState() => _CreateHabitFormState();
}

class _CreateHabitFormState extends State<CreateHabitForm> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String _selectedFrequency = 'Daily';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit?.name ?? '');
    _descriptionController = TextEditingController(text: widget.habit?.description ?? '');
    _selectedFrequency = widget.habit?.frequency ?? 'Daily';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Habit Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedFrequency,
          items: ['Daily', 'Weekly', 'Monthly']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedFrequency = value!;
            });
          },
          decoration: const InputDecoration(
            labelText: 'Frequency',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty && 
                  _descriptionController.text.isNotEmpty) {
                widget.onSave(
                  _nameController.text,
                  _descriptionController.text,
                  _selectedFrequency,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(widget.habit == null ? 'Create Habit' : 'Update Habit'),
          ),
        ),
      ],
    );
  }
}
