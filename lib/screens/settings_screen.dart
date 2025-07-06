import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'task_provider.dart';
import 'user_provider.dart';
import 'auth_screen.dart';
import '../main.dart';
import 'dart:convert'; // For JSON encoding/decoding
import 'dart:io'; // For File operations
import 'package:path_provider/path_provider.dart'; // For getting document directory
import '../models/task.dart'; // Import the Task model

class SettingsScreen extends StatefulWidget {
  final void Function(String)? onThemeChanged;
  final String? currentTheme;
  final void Function(int, int, int)? onPointsSaved;
  const SettingsScreen({Key? key, this.onThemeChanged, this.currentTheme, this.onPointsSaved}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController smallController;
  late TextEditingController mediumController;
  late TextEditingController largeController;

  int smallPoints = 1;
  int mediumPoints = 3;
  int largePoints = 5;

  @override
  void initState() {
    super.initState();
    _loadPoints();
    smallController = TextEditingController(text: smallPoints.toString());
    mediumController = TextEditingController(text: mediumPoints.toString());
    largeController = TextEditingController(text: largePoints.toString());
  }

  Future<void> _loadPoints() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      smallPoints = prefs.getInt('smallPoints') ?? 1;
      mediumPoints = prefs.getInt('mediumPoints') ?? 3;
      largePoints = prefs.getInt('largePoints') ?? 5;
      smallController.text = smallPoints.toString();
      mediumController.text = mediumPoints.toString();
      largeController.text = largePoints.toString();
    });
  }

  Future<void> _savePoints() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('smallPoints', smallPoints);
    await prefs.setInt('mediumPoints', mediumPoints);
    await prefs.setInt('largePoints', largePoints);
    if (widget.onPointsSaved != null) {
      widget.onPointsSaved!(smallPoints, mediumPoints, largePoints);
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Points saved.')));
  }

  @override
  void dispose() {
    smallController.dispose();
    mediumController.dispose();
    largeController.dispose();
    super.dispose();
  }

  void _setTheme(String value) {
    if (widget.onThemeChanged != null) {
      widget.onThemeChanged!(value);
    }
  }

  void _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('Are you sure you want to clear all tasks and calendar data? This cannot be undone.'),
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
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.clearAllTasks();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All tasks and calendar data cleared.')),
      );
    }
  }

  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout? You will need to authenticate again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      
      // Clear user data
      await userProvider.clearUserData();
      taskProvider.setUserContext(null);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );
      }
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const AuthScreen(),
          ),
          (route) => false,
        );
      }
    }
  }

  Future<void> _backupData() async {
    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final List<Task> tasks = taskProvider.tasks;
      final String jsonString = jsonEncode(tasks.map((task) => task.toJson()).toList());

      final directory = await getApplicationDocumentsDirectory();
      final File backupFile = File('${directory.path}/fighter_tasks_backup.json');

      await backupFile.writeAsString(jsonString);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup successful! Saved to: ${backupFile.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    }
  }

  Future<void> _restoreData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Data'),
        content: const Text('Are you sure you want to restore data? This will overwrite all your current tasks.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final File backupFile = File('${directory.path}/fighter_tasks_backup.json');

        if (!await backupFile.exists()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup file not found.')),
          );
          return;
        }

        final String jsonString = await backupFile.readAsString();
        final List<dynamic> decodedData = jsonDecode(jsonString);
        // Assuming Task has a fromJson constructor
        final List<Task> restoredTasks = decodedData.map((item) => Task.fromJson(item)).toList();

        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        taskProvider.setTasks(restoredTasks);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data restored successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          children: [
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 30),
            
            // User Information Section
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.deepPurple.shade100,
                          radius: 24,
                          child: Icon(
                            userProvider.isGuest ? Icons.person_outline : Icons.person,
                            color: Colors.deepPurple,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userProvider.displayName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                userProvider.isGuest ? 'Guest User' : 'Named User',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Task size points
            const Text('Task Size Points', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: [
                _SettingsNumberField(
                  label: 'Small',
                  controller: smallController,
                  color: Colors.green,
                  onChanged: (v) {
                    setState(() {
                      smallPoints = v;
                    });
                  },
                ),
                const SizedBox(width: 12),
                _SettingsNumberField(
                  label: 'Medium',
                  controller: mediumController,
                  color: Colors.orange,
                  onChanged: (v) {
                    setState(() {
                      mediumPoints = v;
                    });
                  },
                ),
                const SizedBox(width: 12),
                _SettingsNumberField(
                  label: 'Large',
                  controller: largeController,
                  color: Colors.red,
                  onChanged: (v) {
                    setState(() {
                      largePoints = v;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _savePoints,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
            // Theme options
            const Text('Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: [
                _ThemeButton(
                  label: 'Default',
                  selected: widget.currentTheme == 'default',
                  color: Colors.deepPurple,
                  onTap: () => _setTheme('default'),
                ),
                const SizedBox(width: 10),
                _ThemeButton(
                  label: 'Dark',
                  selected: widget.currentTheme == 'dark',
                  color: Colors.black,
                  onTap: () => _setTheme('dark'),
                ),
                const SizedBox(width: 10),
                _ThemeButton(
                  label: 'Mint',
                  selected: widget.currentTheme == 'mint',
                  color: Colors.teal,
                  onTap: () => _setTheme('mint'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Backup and Restore Buttons
            ElevatedButton(
              onPressed: _backupData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Backup Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _restoreData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Restore Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
            // Clear all data
            ElevatedButton(
              onPressed: _clearAllData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Clear All Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
            // App version
            const Center(
              child: Text(
                'App Version: 1.0.0',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Color color;
  final ValueChanged<int> onChanged;
  const _SettingsNumberField({Key? key, required this.label, required this.controller, required this.color, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
            controller: controller,
            onChanged: (v) {
              final val = int.tryParse(v) ?? 0;
              onChanged(val);
            },
          ),
        ],
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _ThemeButton({Key? key, required this.label, required this.selected, required this.color, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          border: Border.all(color: selected ? color : Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
