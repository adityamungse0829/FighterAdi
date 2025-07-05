import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> _tasksByDay = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks') ?? [];
    final tasks = tasksJson.map((e) => _decodeTask(e)).toList();
    final Map<DateTime, List<Map<String, dynamic>>> byDay = {};
    for (final t in tasks) {
      if (t['date'] != null) {
        final date = DateTime.parse(t['date']);
        byDay.putIfAbsent(DateTime(date.year, date.month, date.day), () => []).add(t);
      }
    }
    setState(() {
      _tasksByDay = byDay;
    });
  }

  Map<String, dynamic> _decodeTask(String s) {
    final map = Map<String, dynamic>.from(Uri.splitQueryString(s));
    map['points'] = int.tryParse(map['points'] ?? '0') ?? 0;
    map['completed'] = map['completed'] == 'true';
    if (map['date'] != null) {
      map['date'] = map['date'];
    }
    return map;
  }

  Color _getDayColor(double percent) {
    if (percent == 0.0) return Colors.grey.shade300;
    if (percent < 0.25) return Colors.orange.shade100;
    if (percent < 0.5) return Colors.yellow.shade300;
    if (percent < 0.75) return Colors.yellow.shade600;
    return Colors.green;
  }

  double _getCompletionForDay(DateTime day) {
    final tasks = _tasksByDay[DateTime(day.year, day.month, day.day)] ?? [];
    if (tasks.isEmpty) return 0.0;
    final total = tasks.fold(0, (sum, t) => sum + (t['points'] as int));
    if (total == 0) return 0.0;
    final completed = tasks.fold(0, (sum, t) => sum + ((t['completed'] ? t['points'] : 0) as int));
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
                final dayDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                final percent = isCurrentMonth ? _getCompletionForDay(dayDate) : 0.0;
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
    final tasks = _tasksByDay[DateTime(_focusedMonth.year, _focusedMonth.month, dayNum)] ?? [];
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
                    color: _getDayColor(_getCompletionForDay(DateTime(_focusedMonth.year, _focusedMonth.month, dayNum))).withOpacity(0.9),
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
