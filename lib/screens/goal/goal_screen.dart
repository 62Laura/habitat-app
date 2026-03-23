// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/goals_provider.dart';
import '../../theme/app_theme.dart';

class GoalScreen extends ConsumerStatefulWidget {
  const GoalScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends ConsumerState<GoalScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All', 'In Progress', 'Completed'];

  @override
  Widget build(BuildContext context) {
    final goalsState = ref.watch(goalsProvider);
    final goalsNotifier = ref.read(goalsProvider.notifier);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await goalsNotifier.refreshGoals();
        },
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// FILTERS
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(
                      _filters.length,
                      (index) => _buildFilterChip(
                        _filters[index],
                        index == _selectedFilterIndex,
                        index,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// ERROR
                if (goalsState.error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            goalsState.error!,
                            style: TextStyle(color: Colors.red.shade600),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: goalsNotifier.clearError,
                        ),
                      ],
                    ),
                  ),

                /// CONTENT
                if (goalsState.isLoading && goalsState.goals.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (goalsState.goals.isEmpty)
                  _buildEmptyState()
                else
                  ..._getFilteredGoals(goalsState.goals)
                      .map(_buildGoalCard)
                      .toList(),
              ],
            ),
          ),
        ),
      ),

      /// ✅ FIXED FAB POSITION
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGoalDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedFilterIndex = index);
          ref.read(goalsProvider.notifier).setFilter(label);
        },
      ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final color = _getColorFromString(goal.color);
    final icon = _getIconFromString(goal.icon);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
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
                child: Text(
                  goal.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              PopupMenuButton(
                itemBuilder: (_) => [
                  PopupMenuItem(
                    child: const Text('Edit'),
                    onTap: () => _editGoal(goal),
                  ),
                  PopupMenuItem(
                    child: const Text('Delete'),
                    onTap: () => _deleteGoal(goal.id),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text('Action: ${goal.action}'),

          const SizedBox(height: 8),

          LinearProgressIndicator(
            value: goal.currentProgress / goal.targetProgress,
            color: color,
          ),
        ],
      ),
    );
  }

  void _showCreateGoalDialog({Goal? goal}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(goal == null ? 'Create Goal' : 'Edit Goal'),
        content: CreateGoalForm(
          goal: goal,
          onSave: (title, desc, target, action) {
            if (goal == null) {
              ref.read(goalsProvider.notifier).addGoal(
                    title,
                    desc,
                    target,
                    action,
                  );
            } else {
              ref.read(goalsProvider.notifier).updateGoal(
                    goal.id,
                    title,
                    desc,
                    target,
                    action,
                  );
            }
          },
        ),
      ),
    );
  }

  void _editGoal(Goal goal) => _showCreateGoalDialog(goal: goal);

  void _deleteGoal(String id) {
    ref.read(goalsProvider.notifier).deleteGoal(id);
  }

  List<Goal> _getFilteredGoals(List<Goal> goals) {
    if (_selectedFilterIndex == 1) {
      return goals.where((g) => g.percentage < 100).toList();
    } else if (_selectedFilterIndex == 2) {
      return goals.where((g) => g.percentage >= 100).toList();
    }
    return goals;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.flag, size: 60, color: AppTheme.primaryColor),
          const SizedBox(height: 10),
          const Text('No goals yet'),
          const SizedBox(height: 10),

          /// ✅ FIXED BUTTON (label issue)
          ElevatedButton.icon(
            onPressed: _showCreateGoalDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Goal'),
          ),
        ],
      ),
    );
  }

  Color _getColorFromString(String color) {
    switch (color) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _getIconFromString(String icon) {
    switch (icon) {
      case 'fitness_center':
        return Icons.fitness_center;
      default:
        return Icons.star;
    }
  }
}

class CreateGoalForm extends StatefulWidget {
  final Goal? goal;
  final Function(String, String, double, String) onSave;

  const CreateGoalForm({
    Key? key,
    this.goal,
    required this.onSave,
  }) : super(key: key);

  @override
  State<CreateGoalForm> createState() => _CreateGoalFormState();
}

class _CreateGoalFormState extends State<CreateGoalForm> {
  late TextEditingController title;
  late TextEditingController desc;
  late TextEditingController target;
  late TextEditingController action;

  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.goal?.title ?? '');
    desc = TextEditingController(text: widget.goal?.description ?? '');
    target =
        TextEditingController(text: widget.goal?.targetProgress.toString() ?? '');
    action = TextEditingController(text: widget.goal?.action ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(controller: title),
        const SizedBox(height: 10),
        TextField(controller: desc),
        const SizedBox(height: 10),
        TextField(controller: target),
        const SizedBox(height: 10),
        TextField(controller: action),
        const SizedBox(height: 10),

        ElevatedButton(
          onPressed: () {
            final t = double.tryParse(target.text) ?? 0;
            if (t > 0) {
              widget.onSave(title.text, desc.text, t, action.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        )
      ],
    );
  }
}