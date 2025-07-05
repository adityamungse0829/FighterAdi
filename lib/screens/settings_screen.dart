import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final void Function(String)? onThemeChanged;
  final String? currentTheme;
  const SettingsScreen({Key? key, this.onThemeChanged, this.currentTheme}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController smallController;
  late TextEditingController mediumController;
  late TextEditingController largeController;
  late TextEditingController targetController;

  int smallPoints = 1;
  int mediumPoints = 3;
  int largePoints = 5;
  int dailyTarget = 12;
  String theme = 'default';

  @override
  void initState() {
    super.initState();
    smallController = TextEditingController(text: smallPoints.toString());
    mediumController = TextEditingController(text: mediumPoints.toString());
    largeController = TextEditingController(text: largePoints.toString());
    targetController = TextEditingController(text: dailyTarget.toString());
    theme = widget.currentTheme ?? 'default';
  }

  @override
  void dispose() {
    smallController.dispose();
    mediumController.dispose();
    largeController.dispose();
    targetController.dispose();
    super.dispose();
  }

  void _setTheme(String value) {
    setState(() {
      theme = value;
    });
    if (widget.onThemeChanged != null) {
      widget.onThemeChanged!(value);
    }
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('Are you sure you want to clear all data? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                smallPoints = 1;
                mediumPoints = 3;
                largePoints = 5;
                dailyTarget = 12;
                theme = 'default';
                smallController.text = '1';
                mediumController.text = '3';
                largeController.text = '5';
                targetController.text = '12';
              });
              if (widget.onThemeChanged != null) {
                widget.onThemeChanged!('default');
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared.')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        // Daily target
        const Text('Daily Target Points', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SettingsNumberField(
                label: 'Target',
                controller: targetController,
                color: Colors.deepPurple,
                onChanged: (v) {
                  setState(() {
                    dailyTarget = v;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        // Theme options
        const Text('Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: [
            _ThemeButton(
              label: 'Default',
              selected: theme == 'default',
              color: Colors.deepPurple,
              onTap: () => _setTheme('default'),
            ),
            const SizedBox(width: 10),
            _ThemeButton(
              label: 'Dark',
              selected: theme == 'dark',
              color: Colors.black,
              onTap: () => _setTheme('dark'),
            ),
            const SizedBox(width: 10),
            _ThemeButton(
              label: 'Mint',
              selected: theme == 'mint',
              color: Colors.teal,
              onTap: () => _setTheme('mint'),
            ),
          ],
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
    return Expanded(
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
