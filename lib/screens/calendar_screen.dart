import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'task_provider.dart';
import '../models/task.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();

  Color _getDayColor(double percent) {
    if (percent == 0.0) return Colors.grey.shade300;
    if (percent < 0.25) return Colors.orange.shade100;
    if (percent < 0.5) return Colors.yellow.shade300;
    if (percent < 0.75) return Colors.yellow.shade600;
    return Colors.green;
  }

  double _getCompletionForDay(DateTime day, List<Task> allTasks) {
    final tasks = allTasks.where((t) {
      if (t.dueDate != null) {
        try {
          final taskDate = t.dueDate;
          return taskDate.year == day.year && 
                 taskDate.month == day.month && 
                 taskDate.day == day.day;
        } catch (e) {
          // If date parsing fails, skip this task
          return false;
        }
      }
      return false;
    }).toList();
    
    if (tasks.isEmpty) return 0.0;
    final total = tasks.fold(0, (sum, t) => sum + t.points);
    if (total == 0) return 0.0;
    final completed = tasks.fold(0, (sum, t) => sum + (t.completed ? t.points : 0));
    return completed / total;
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  void _showTasksForDay(BuildContext context, int dayNum) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final allTasks = taskProvider.tasks;
    final dayDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
    
    final tasksForDay = allTasks.where((t) {
      if (t.dueDate != null) {
        try {
          final taskDate = t.dueDate;
          return taskDate.year == dayDate.year && 
                 taskDate.month == dayDate.month && 
                 taskDate.day == dayDate.day;
        } catch (e) {
          // If date parsing fails, skip this task
          return false;
        }
      }
      return false;
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the modal to take full screen height
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.7, // Take 70% of the screen height
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_monthName(_focusedMonth.month)} $dayNum, ${_focusedMonth.year}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (tasksForDay.isEmpty)
                  const Text('No tasks for this day.')
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: tasksForDay.length,
                      itemBuilder: (context, idx) {
                        final task = tasksForDay[idx];
                        return ListTile(
                          leading: Icon(
                            task.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: task.completed ? Colors.green : Colors.grey,
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.completed ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          trailing: Text(
                            '${task.points} pts',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final allTasks = taskProvider.tasks;
        
        final now = DateTime.now();
        final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
        final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
        final daysInMonth = lastDayOfMonth.day;
        final firstWeekday = firstDayOfMonth.weekday % 7; // Sunday=0
        final totalCells = daysInMonth + firstWeekday;
        final rows = (totalCells / 7).ceil();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 32),
                    onPressed: _previousMonth,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "${_monthName(_focusedMonth.month)} ${_focusedMonth.year}",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 32),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _DayHeader('SUN'),
                  _DayHeader('MON'),
                  _DayHeader('TUE'),
                  _DayHeader('WED'),
                  _DayHeader('THU'),
                  _DayHeader('FRI'),
                  _DayHeader('SAT'),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: rows * 7,
                  itemBuilder: (context, i) {
                    final dayNum = i - firstWeekday + 1;
                    final isCurrentMonth = dayNum > 0 && dayNum <= daysInMonth;
                    final isToday = isCurrentMonth &&
                        _focusedMonth.month == now.month &&
                        _focusedMonth.year == now.year &&
                        dayNum == now.day;
                    final dayDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                    final percent = isCurrentMonth ? _getCompletionForDay(dayDate, allTasks) : 0.0;
                    return GestureDetector(
                      onTap: isCurrentMonth
                          ? () {
                              _showTasksForDay(context, dayNum);
                            }
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrentMonth ? _getDayColor(percent) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: isToday
                              ? Border.all(color: Colors.deepPurple, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            isCurrentMonth ? '$dayNum' : '',
                            style: TextStyle(
                              color: isCurrentMonth
                                  ? (isToday ? Colors.deepPurple : Colors.black)
                                  : Colors.grey.shade400,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
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

class _DayHeader extends StatelessWidget {
  final String text;
  const _DayHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
      ),
    );
  }
}