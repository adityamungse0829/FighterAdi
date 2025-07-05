import 'package:flutter/material.dart';
import 'dart:math';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();

  // Mock completion data: day -> percent (0.0 to 1.0)
  final Map<int, double> _completion = {
    1: 0.0,
    2: 0.2,
    3: 0.5,
    4: 0.8,
    5: 1.0,
    6: 0.3,
    7: 0.7,
    8: 0.0,
    9: 0.4,
    10: 0.9,
    11: 0.6,
    12: 0.1,
    13: 0.0,
    14: 0.5,
    15: 0.75,
    16: 0.25,
    17: 0.0,
    18: 0.6,
    19: 0.8,
    20: 0.2,
    21: 0.0,
    22: 0.5,
    23: 0.7,
    24: 0.0,
    25: 0.3,
    26: 0.9,
    27: 0.0,
    28: 0.1,
    29: 0.0,
    30: 1.0,
    31: 0.0,
  };

  // Add mock tasks per day
  final Map<int, List<Map<String, dynamic>>> _tasksPerDay = {
    3: [
      {'title': 'Run', 'points': 1, 'size': 'small', 'completed': false},
      {'title': 'Read', 'points': 3, 'size': 'medium', 'completed': true},
    ],
    5: [
      {'title': 'Make', 'points': 5, 'size': 'large', 'completed': false},
    ],
    10: [
      {'title': 'Cook', 'points': 3, 'size': 'medium', 'completed': true},
      {'title': 'Write', 'points': 1, 'size': 'small', 'completed': false},
    ],
    30: [
      {'title': 'Yoga', 'points': 1, 'size': 'small', 'completed': true},
      {'title': 'Code', 'points': 5, 'size': 'large', 'completed': false},
    ],
  };

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

  Color _getDayColor(double percent) {
    if (percent == 0.0) return Colors.grey.shade300;
    if (percent < 0.25) return Colors.orange.shade100;
    if (percent < 0.5) return Colors.yellow.shade300;
    if (percent < 0.75) return Colors.yellow.shade600;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
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
                final percent = isCurrentMonth ? (_completion[dayNum] ?? 0.0) : 0.0;
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

  void _showTasksForDay(BuildContext context, int dayNum) {
    final tasks = _tasksPerDay[dayNum] ?? [];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Tasks for ${_monthName(_focusedMonth.month)} $dayNum',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (tasks.isEmpty)
                const Text(
                  'No tasks for this day.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                )
              else
                ...tasks.map((t) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _getDayColor(_completion[dayNum] ?? 0.0).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: Icon(
                      t['completed'] ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: t['completed'] ? Colors.green : Colors.white,
                    ),
                    title: Text(
                      t['title'],
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        decoration: t['completed'] ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    trailing: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${t['points']}',
                          style: TextStyle(
                            color: t['size'] == 'small'
                                ? Colors.green
                                : t['size'] == 'medium'
                                    ? Colors.orange
                                    : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                )),
            ],
          ),
        );
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String label;
  const _DayHeader(this.label, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.grey,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
