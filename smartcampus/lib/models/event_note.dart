class EventNote {
  final int id;
  final int eventId;
  final String note;
  final String? imageData;
  final DateTime createdAt;

  EventNote({
    required this.id,
    required this.eventId,
    required this.note,
    required this.createdAt,
    this.imageData,
  });

  factory EventNote.fromMap(Map<String, dynamic> map) {
    return EventNote(
      id: map['id'] as int,
      eventId: map['event_id'] as int,
      note: map['note'] as String,
      imageData: map['image_data'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'note': note,
      'image_data': imageData,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
