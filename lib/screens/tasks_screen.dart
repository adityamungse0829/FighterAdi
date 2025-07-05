import 'package:flutter/material.dart';
import 'dart:math';

class TasksScreen extends StatefulWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int currentPoints = 3;
  int targetPoints = 12;

  final List<Map<String, dynamic>> tasks = [
    {'title': 'Run', 'points': 1, 'size': 'small', 'completed': false},
    {'title': 'Make', 'points': 5, 'size': 'large', 'completed': false},
    {'title': 'Cook', 'points': 3, 'size': 'medium', 'completed': true},
  ];

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
      if (tasks[index]['completed']) {
        currentPoints += tasks[index]['points'] as int;
      } else {
        currentPoints -= tasks[index]['points'] as int;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString =
        "Today, ${['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'][now.weekday % 7]},\n${_monthName(now.month)} ${now.day}";
    final progress = min(currentPoints / targetPoints, 1.0);
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
                            '$currentPoints',
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
                      currentPoints < targetPoints
                          ? 'Complete ${targetPoints - currentPoints} more points to finish today'
                          : 'Great job! You\'ve completed today\'s goal!',
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
            // Task list
            ...List.generate(tasks.length, (i) {
              final t = tasks[i];
              return Container(
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
            onPressed: () {
              // Share logic placeholder
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon!')),
              );
            },
          ),
        ),
        // Add task button (bottom right)
        Positioned(
          bottom: 30,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: Colors.black,
            onPressed: () {
              // Add task logic placeholder
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add Task feature coming soon!')),
              );
            },
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
}
