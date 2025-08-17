import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'task_provider.dart';
import '../models/task.dart';
import 'user_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  String _viewMode = 'daily'; // 'daily', 'weekly', 'monthly'
  DateTime _lastRefreshDate = DateTime.now(); // Track when we last refreshed data

  Color _getDayColor(double percent) {
    if (percent == 0.0) return Colors.grey.shade300;
    if (percent < 0.25) return Colors.orange.shade100;
    if (percent < 0.5) return Colors.yellow.shade300;
    if (percent < 0.75) return Colors.yellow.shade600;
    return Colors.green;
  }

  double _getCompletionForDay(DateTime day, List<Task> allTasks) {
    // Use the new method from TaskProvider for better date handling
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final tasksForDay = taskProvider.getTasksForDate(day);
    
    if (tasksForDay.isEmpty) return 0.0;
    final total = tasksForDay.fold(0, (sum, t) => sum + t.points);
    if (total == 0) return 0.0;
    final completed = tasksForDay.fold(0, (sum, t) => sum + (t.completed ? t.points : 0));
    return completed / total;
  }

  double _getCompletionForWeek(DateTime weekStart, List<Task> allTasks) {
    double totalCompletion = 0.0;
    int totalDays = 7; // Always consider all 7 days of the week
    
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final dayCompletion = _getCompletionForDay(day, allTasks);
      totalCompletion += dayCompletion; // Add completion for all days, even if 0
    }
    
    return totalCompletion / totalDays; // Return average across all days
  }

  double _getCompletionForMonth(DateTime month, List<Task> allTasks) {
    double totalCompletion = 0.0;
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final totalDays = lastDay.day; // Total days in the month
    
    for (int day = 1; day <= totalDays; day++) {
      final date = DateTime(month.year, month.month, day);
      final dayCompletion = _getCompletionForDay(date, allTasks);
      totalCompletion += dayCompletion; // Add completion for all days, even if 0
    }
    
    return totalCompletion / totalDays; // Return average across all days
  }

  void _showWeeklyProgress(BuildContext context, DateTime weekStart) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final allTasks = taskProvider.allTasks; // Use allTasks to include historical data
    
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekCompletion = _getCompletionForWeek(weekStart, allTasks);
    
    void _shareWeeklyProgress() {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userName = userProvider.displayName;
      
      final weekStartStr = '${_monthName(weekStart.month)} ${weekStart.day}';
      final weekEndStr = '${_monthName(weekEnd.month)} ${weekEnd.day}, ${weekStart.year}';
      
      String dailyBreakdown = '';
      int completedDays = 0;
      int daysWithTasks = 0;
      
      for (int i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));
        final dayCompletion = _getCompletionForDay(day, allTasks);
        final dayName = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][day.weekday % 7];
        
        if (dayCompletion > 0) {
          daysWithTasks++;
          if (dayCompletion == 1.0) {
            completedDays++;
          }
          dailyBreakdown += '✅ $dayName (${(dayCompletion * 100).round()}%)\n';
        } else {
          dailyBreakdown += '❌ $dayName (No tasks)\n';
        }
      }
      
      final shareText = '''📅 Fighter App - Weekly Progress Report

👤 User: $userName
📆 Week: $weekStartStr - $weekEndStr
🎯 Overall Progress: ${(weekCompletion * 100).round()}%
✅ Completed Days: $completedDays/$daysWithTasks
📊 Days with Tasks: $daysWithTasks/7

📊 Daily Breakdown:
$dailyBreakdown

🔥 Keep up the great work! #FighterApp #Productivity''';
      
      Share.share(shareText);
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Week of ${_monthName(weekStart.month)} ${weekStart.day} - ${_monthName(weekEnd.month)} ${weekEnd.day}, ${weekStart.year}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: _shareWeeklyProgress,
                      icon: const Icon(Icons.share, color: Colors.deepPurple),
                      tooltip: 'Share Weekly Progress',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Weekly Progress',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: weekCompletion,
                          minHeight: 20,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(_getDayColor(weekCompletion)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(weekCompletion * 100).round()}% Complete',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Daily Breakdown:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final day = weekStart.add(Duration(days: index));
                      final dayCompletion = _getCompletionForDay(day, allTasks);
                      final dayName = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][day.weekday % 7];
                      
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getDayColor(dayCompletion),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        title: Text('$dayName, ${_monthName(day.month)} ${day.day}'),
                        subtitle: Text('${(dayCompletion * 100).round()}% Complete'),
                        trailing: Text(
                          '${dayCompletion > 0 ? "✓" : "—"}',
                          style: TextStyle(
                            fontSize: 20,
                            color: dayCompletion > 0 ? Colors.green : Colors.grey,
                          ),
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

  void _showMonthlyProgress(BuildContext context, DateTime month) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final allTasks = taskProvider.tasks;
    
    final monthCompletion = _getCompletionForMonth(month, allTasks);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    
    void _shareMonthlyProgress() {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userName = userProvider.displayName;
      
      String weeklyBreakdown = '';
      int completedWeeks = 0;
      int weeksWithTasks = 0;
      final totalWeeks = ((lastDay.day + DateTime(month.year, month.month, 1).weekday - 1) / 7).ceil();
      
      for (int weekIndex = 0; weekIndex < totalWeeks; weekIndex++) {
        final weekStart = DateTime(month.year, month.month, 1 + (weekIndex * 7));
        final weekCompletion = _getCompletionForWeek(weekStart, allTasks);
        
        if (weekCompletion > 0) {
          weeksWithTasks++;
          if (weekCompletion >= 0.8) { // Consider week completed if 80% or more
            completedWeeks++;
          }
          weeklyBreakdown += 'Week ${weekIndex + 1}: ${(weekCompletion * 100).round()}% ${weekCompletion >= 0.8 ? "✅" : "🔄"}\n';
        } else {
          weeklyBreakdown += 'Week ${weekIndex + 1}: No tasks 📅\n';
        }
      }
      
      final shareText = '''📅 Fighter App - Monthly Progress Report

👤 User: $userName
📆 Month: ${_monthName(month.month)} ${month.year}
🎯 Overall Progress: ${(monthCompletion * 100).round()}%
✅ Completed Weeks: $completedWeeks/$weeksWithTasks
📊 Weeks with Tasks: $weeksWithTasks/$totalWeeks

📊 Weekly Breakdown:
$weeklyBreakdown

🔥 Amazing progress this month! #FighterApp #Productivity''';
      
      Share.share(shareText);
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${_monthName(month.month)} ${month.year} Progress',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: _shareMonthlyProgress,
                      icon: const Icon(Icons.share, color: Colors.deepPurple),
                      tooltip: 'Share Monthly Progress',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Monthly Progress',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: monthCompletion,
                          minHeight: 20,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(_getDayColor(monthCompletion)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(monthCompletion * 100).round()}% Complete',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Weekly Breakdown:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: ((lastDay.day + DateTime(month.year, month.month, 1).weekday - 1) / 7).ceil(),
                    itemBuilder: (context, weekIndex) {
                      final weekStart = DateTime(month.year, month.month, 1 + (weekIndex * 7));
                      final weekCompletion = _getCompletionForWeek(weekStart, allTasks);
                      
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getDayColor(weekCompletion),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'W${weekIndex + 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                        title: Text('Week ${weekIndex + 1}'),
                        subtitle: Text('${(weekCompletion * 100).round()}% Complete'),
                        trailing: Text(
                          '${weekCompletion > 0 ? "✓" : "—"}',
                          style: TextStyle(
                            fontSize: 20,
                            color: weekCompletion > 0 ? Colors.green : Colors.grey,
                          ),
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

  // Check if we need to refresh data (e.g., new day/week/month)
  void _checkAndRefreshData() {
    final now = DateTime.now();
    final lastRefresh = _lastRefreshDate;
    
    // Check if it's a new day, week, or month
    if (now.year != lastRefresh.year || 
        now.month != lastRefresh.month || 
        now.day != lastRefresh.day) {
      
      print('🔄 New day detected, refreshing calendar data');
      setState(() {
        _lastRefreshDate = now;
        // Force refresh by updating focused month if needed
        if (_focusedMonth.year == lastRefresh.year && 
            _focusedMonth.month == lastRefresh.month) {
          _focusedMonth = DateTime(now.year, now.month, 1);
        }
      });
    }
  }

  void _showTasksForDay(BuildContext context, int dayNum) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final dayDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
    
    // Use the new method from TaskProvider
    final tasksForDay = taskProvider.getTasksForDate(dayDate);

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
                          subtitle: Text(
                            task.completed 
                              ? 'Completed on ${task.completionDate?.day}/${task.completionDate?.month}/${task.completionDate?.year}'
                              : 'Due on ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
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
    // Check if we need to refresh data
    _checkAndRefreshData();
    
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final allTasks = taskProvider.allTasks; // Use allTasks to include historical data for accurate progress
        
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
            const SizedBox(height: 16),
            // View Mode Selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ViewModeButton(
                    title: 'Daily',
                    isSelected: _viewMode == 'daily',
                    onTap: () => setState(() => _viewMode = 'daily'),
                  ),
                  _ViewModeButton(
                    title: 'Weekly',
                    isSelected: _viewMode == 'weekly',
                    onTap: () => setState(() => _viewMode = 'weekly'),
                  ),
                  _ViewModeButton(
                    title: 'Monthly',
                    isSelected: _viewMode == 'monthly',
                    onTap: () => setState(() => _viewMode = 'monthly'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Progress Summary Card
            if (_viewMode != 'daily')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  child: InkWell(
                    onTap: () {
                      if (_viewMode == 'weekly') {
                        // For weekly view, use current date to calculate week start
                        final now = DateTime.now();
                        final weekStart = now.subtract(Duration(days: now.weekday % 7));
                        _showWeeklyProgress(context, weekStart);
                      } else if (_viewMode == 'monthly') {
                        _showMonthlyProgress(context, _focusedMonth);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            _viewMode == 'weekly' ? Icons.view_week : Icons.calendar_view_month,
                            color: Colors.deepPurple,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _viewMode == 'weekly' ? 'Weekly Progress' : 'Monthly Progress',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _viewMode == 'weekly' 
                                    ? 'Tap to view this week\'s progress'
                                    : 'Tap to view this month\'s progress',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
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

class _ViewModeButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}