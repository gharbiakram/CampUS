class Announcement {
  final int id;
  final String title;
  final String content;
  final String author;
  final String priority;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.priority,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      author: json['author'] as String,
      priority: json['priority'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Create from database map
  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'] as int,
      title: map['title'] as String,
      content: map['content'] as String,
      author: map['author'] as String,
      priority: map['priority'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
