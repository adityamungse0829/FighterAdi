import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({Key? key}) : super(key: key);

  static Future<void> clearAllTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tasks');
  }

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int smallPoints = 1;
  int mediumPoints = 3;
  int largePoints = 5;

  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    _loadPoints();
    _loadTasks();
  }

  Future<void> _loadPoints() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      smallPoints = prefs.getInt('smallPoints') ?? 1;
      mediumPoints = prefs.getInt('mediumPoints') ?? 3;
      largePoints = prefs.getInt('largePoints') ?? 5;
    });
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks') ?? [];
    setState(() {
      tasks = tasksJson.map((e) => _decodeTask(e)).toList();
    });
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = tasks.map((e) => _encodeTask(e)).toList();
    await prefs.setStringList('tasks', tasksJson);
  }

  Map<String, dynamic> _decodeTask(String s) {
    final map = Map<String, dynamic>.from(Uri.splitQueryString(s));
    map['points'] = int.tryParse(map['points'] ?? '0') ?? 0;
    map['completed'] = map['completed'] == 'true';
    return map;
  }

  String _encodeTask(Map<String, dynamic> t) => t.map((k, v) => MapEntry(k, v.toString())).entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');

  Color getTaskColor(String size) {
    switch (size) {
      case 'small':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'large':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void toggleTask(int index) {
    setState(() {
      tasks[index]['completed'] = !(tasks[index]['completed'] as bool);
    });
    _saveTasks();
  }

  int get totalPoints => tasks.fold(0, (sum, t) => sum + (t['points'] as int));
  int get completedPoints => tasks.fold(0, (sum, t) => sum + ((t['completed'] ? t['points'] : 0) as int));

  void _showAddTaskModal() {
    String newTaskName = '';
    String newTaskSize = 'small';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Task',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Task Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => newTaskName = v,
                  ),
                  const SizedBox(height: 18),
                  const Text('Task Size', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Small'),
                        selected: newTaskSize == 'small',
                        onSelected: (_) => setModalState(() => newTaskSize = 'small'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Medium'),
                        selected: newTaskSize == 'medium',
                        onSelected: (_) => setModalState(() => newTaskSize = 'medium'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Large'),
                        selected: newTaskSize == 'large',
                        onSelected: (_) => setModalState(() => newTaskSize = 'large'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (newTaskName.trim().isEmpty) return;
                          int points = newTaskSize == 'small'
                              ? smallPoints
                              : newTaskSize == 'medium'
                                  ? mediumPoints
                                  : largePoints;
                          setState(() {
                            tasks.add({
                              'title': newTaskName.trim(),
                              'points': points,
                              'size': newTaskSize,
                              'completed': false,
                            });
                          });
                          _saveTasks();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _shareProgress() {
    final now = DateTime.now();
    final dateString =
        "${['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'][now.weekday % 7]}, ${_monthName(now.month)} ${now.day}, ${now.year}";
    final completedTasks = tasks.where((t) => t['completed']).toList();
    final pendingTasks = tasks.where((t) => !t['completed']).toList();
    final completedList = completedTasks.isEmpty
        ? 'None'
        : completedTasks.map((t) => '✔ ${t['title']} (${t['points']})').join('\n');
    final pendingList = pendingTasks.isEmpty
        ? 'None'
        : pendingTasks.map((t) => '❏ ${t['title']} (${t['points']})').join('\n');
    final percent = totalPoints == 0 ? 0 : ((completedPoints / totalPoints) * 100).round();
    final shareText =
        'Fighter App Progress\n\nDate: $dateString\nTotal Score: $completedPoints / $totalPoints \nPercentage: $percent%\n\nTasks Completed:\n$completedList\n\nTasks Pending:\n$pendingList\n\n#FighterApp #Productivity';
    Share.share(shareText);
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('Are you sure you want to clear all tasks and points? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('smallPoints');
      await prefs.remove('mediumPoints');
      await prefs.remove('largePoints');
      setState(() {
        smallPoints = 1;
        mediumPoints = 3;
        largePoints = 5;
        tasks.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString =
        "Today, ${['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'][now.weekday % 7]},\n${_monthName(now.month)} ${now.day}";
    final progress = totalPoints == 0 ? 0.0 : min(completedPoints / totalPoints, 1.0);
    final progressColor = progress < 0.25
        ? Colors.grey
        : progress < 0.5
            ? Colors.orange.shade200
            : progress < 0.75
                ? Colors.yellow.shade600
                : Colors.green;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 100),
          children: [
            // Date header
            Text(
              dateString,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            // Progress card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              color: Colors.deepOrange.shade400,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daily Goal Progress',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.black,
                          radius: 16,
                          child: Text(
                            '$completedPoints',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 32,
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 32,
                          backgroundColor: Colors.brown.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      totalPoints == 0
                          ? 'No tasks today.'
                          : completedPoints < totalPoints
                              ? 'Complete ${totalPoints - completedPoints} more points to finish today'
                              : 'Great job! You\'ve completed all tasks!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "Today's Tasks",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(tasks.length, (i) {
              final t = tasks[i];
              return Dismissible(
                key: ValueKey(t.hashCode.toString() + t['title']),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white, size: 28),
                ),
                onDismissed: (_) {
                  setState(() {
                    tasks.removeAt(i);
                  });
                  _saveTasks();
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: getTaskColor(t['size']).withOpacity(t['completed'] ? 0.5 : 1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: getTaskColor(t['size']).withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: GestureDetector(
                      onTap: () => toggleTask(i),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: t['completed'] ? Colors.white : Colors.transparent,
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: t['completed']
                            ? const Icon(Icons.check, color: Colors.green, size: 20)
                            : null,
                      ),
                    ),
                    title: Text(
                      t['title'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        decoration: t['completed'] ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    trailing: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${t['points']}',
                          style: TextStyle(
                            color: getTaskColor(t['size']),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 80),
          ],
        ),
        // Share button (top right)
        Positioned(
          top: 36,
          right: 20,
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.grey, size: 28),
            onPressed: _shareProgress,
          ),
        ),
        // Add task button (bottom right)
        Positioned(
          bottom: 30,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: Colors.black,
            onPressed: _showAddTaskModal,
            child: const Icon(Icons.add, size: 32),
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }

  void clearTasksInMemory() {
    setState(() {
      tasks.clear();
    });
  }
}
