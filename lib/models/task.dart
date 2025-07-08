class Task {
  String id;
  String title;
  DateTime dueDate;
  bool completed;
  int points;
  String size; // Add size property
  bool isRecurring; // Add isRecurring property

  Task({
    required this.id,
    required this.title,
    required this.dueDate,
    this.completed = false,
    this.points = 0,
    this.size = 'small', // Initialize size with a default value
    this.isRecurring = false, // Initialize isRecurring with a default value
  });

  // Convert a Task object into a Map object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dueDate': dueDate.toIso8601String(),
      'completed': completed,
      'points': points,
      'size': size, // Include size in toJson
      'isRecurring': isRecurring, // Include isRecurring in toJson
    };
  }

  // Convert a Map object into a Task object
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      dueDate: DateTime.parse(json['dueDate']),
      completed: json['completed'] ?? false,
      points: json['points'] ?? 0,
      size: json['size'] ?? 'small', // Include size in fromJson
      isRecurring: json['isRecurring'] ?? false, // Include isRecurring in fromJson
    );
  }
}