class Todo {
  final String id;
  final String text;
  final bool done;
  final DateTime createdAt;

  Todo({
    required this.id,
    required this.text,
    required this.done,
    required this.createdAt,
  });

  factory Todo.fromMap(String id, Map<String, dynamic> map) {
    return Todo(
      id: id,
      text: map['text'] ?? '',
      done: map['done'] ?? false,
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'done': done,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Todo copyWith({String? text, bool? done}) {
    return Todo(
      id: id,
      text: text ?? this.text,
      done: done ?? this.done,
      createdAt: createdAt,
    );
  }
}
