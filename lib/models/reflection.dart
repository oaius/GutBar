class Reflection {
  final DateTime date;
  final String text;

  Reflection({required this.date, required this.text});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'text': text,
      };

  static Reflection fromJson(Map<String, dynamic> json) => Reflection(
        date: DateTime.parse(json['date'] as String),
        text: json['text'] as String,
      );
}
