class SvnCommit {
  final String revision;
  final String author;
  final DateTime date;
  final String message;
  final List<String> paths;

  SvnCommit({
    required this.revision,
    required this.author,
    required this.date,
    required this.message,
    required this.paths,
  });

  SvnCommit copyWith({
    String? revision,
    String? author,
    DateTime? date,
    String? message,
    List<String>? paths,
  }) {
    return SvnCommit(
      revision: revision ?? this.revision,
      author: author ?? this.author,
      date: date ?? this.date,
      message: message ?? this.message,
      paths: paths ?? this.paths,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SvnCommit &&
        other.revision == revision &&
        other.author == author &&
        other.date == date &&
        other.message == message &&
        other.paths == paths;
  }

  @override
  int get hashCode {
    return revision.hashCode ^
        author.hashCode ^
        date.hashCode ^
        message.hashCode ^
        paths.hashCode;
  }

  @override
  String toString() {
    return 'SvnCommit(revision: $revision, author: $author, date: $date, message: $message, paths: $paths)';
  }
}

enum SortColumn {
  revision,
  author,
  date,
  message,
}

enum SortDirection {
  ascending,
  descending,
}
