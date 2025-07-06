class Task {
  String id;
  String title;
  String description;
  DateTime dueDate;
  bool completed;
  int points;
  String size; // Add size property

  Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.completed = false,
    this.points = 0,
    this.size = 'small', // Initialize size with a default value
  });

  // Convert a Task object into a Map object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'completed': completed,
      'points': points,
      'size': size, // Include size in toJson
    };
  }

  // Convert a Map object into a Task object
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      dueDate: DateTime.parse(json['dueDate']),
      completed: json['completed'] ?? false,
      points: json['points'] ?? 0,
      size: json['size'] ?? 'small', // Include size in fromJson
    );
  }
}
