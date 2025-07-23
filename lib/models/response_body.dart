class MitmBody {
  final String text;
  final String viewName;
  final String syntaxHighlight;
  final String description;

  const MitmBody({
    required this.text,
    required this.viewName,
    required this.syntaxHighlight,
    required this.description,
  });

  factory MitmBody.fromJson(Map<String, dynamic> json) {
    return MitmBody(
      text: json['text'] as String,
      viewName: json['view_name'] as String,
      syntaxHighlight: json['syntax_highlight'] as String,
      description: json['description'] as String,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'view_name': viewName,
      'syntax_highlight': syntaxHighlight,
      'description': description,
    };
  }
}
