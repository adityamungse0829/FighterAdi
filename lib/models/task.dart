class Task {
  String id;
  String title;
  DateTime dueDate;
  bool completed;
  int points;
  String size; // Add size property
  bool isRecurring; // Add isRecurring property
  String section; // Add section property for 4-pillar system
  DateTime? completionDate; // Track when task was actually completed
  bool archived; // Track if task is archived (removed from main list but preserved for history)

  Task({
    required this.id,
    required this.title,
    required this.dueDate,
    this.completed = false,
    this.points = 0,
    this.size = 'small', // Initialize size with a default value
    this.isRecurring = false, // Initialize isRecurring with a default value
    this.section = 'Physical', // Initialize section with a default value
    this.completionDate, // Initialize completionDate as null
    this.archived = false, // Initialize archived as false
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
      'section': section, // Include section in toJson
      'completionDate': completionDate?.toIso8601String(), // Include completionDate in toJson
      'archived': archived, // Include archived in toJson
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
      section: json['section'] ?? 'Physical', // Include section in fromJson
      completionDate: json['completionDate'] != null ? DateTime.parse(json['completionDate']) : null, // Include completionDate in fromJson
      archived: json['archived'] ?? false, // Include archived in fromJson
    );
  }
}