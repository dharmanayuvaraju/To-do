class TeluguQuote {
  final int id;
  final String telugu;
  final String english;
  final bool isCustom;

  TeluguQuote({
    required this.id,
    required this.telugu,
    required this.english,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'telugu': telugu,
      'english': english,
      'isCustom': isCustom,
    };
  }

  factory TeluguQuote.fromJson(Map<String, dynamic> map) {
    return TeluguQuote(
      id: (map['id'] ?? 0) as int,
      telugu: (map['telugu'] ?? '') as String,
      english: (map['english'] ?? '') as String,
      isCustom: (map['isCustom'] ?? false) as bool,
    );
  }
}
