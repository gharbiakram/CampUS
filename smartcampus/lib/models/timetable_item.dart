class TimetableItem {
  final int id;
  final String subject;
  final String instructor;
  final String day; // Monday, Tuesday, etc.
  final String startTime; // HH:mm format
  final String endTime; // HH:mm format
  final String room;

  TimetableItem({
    required this.id,
    required this.subject,
    required this.instructor,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
  });

  factory TimetableItem.fromJson(Map<String, dynamic> json) {
    return TimetableItem(
      id: json['id'] as int,
      subject: json['subject'] as String,
      instructor: json['instructor'] as String,
      day: json['day'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      room: json['room'] as String,
    );
  }

  factory TimetableItem.fromMap(Map<String, dynamic> map) {
    return TimetableItem(
      id: map['id'] as int,
      subject: map['subject'] as String,
      instructor: map['instructor'] as String,
      day: map['day'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      room: map['room'] as String,
    );
  }
}
