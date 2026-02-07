class SvnFile {
  final String path;
  final String status;
  bool isSelected;

  SvnFile({
    required this.path,
    required this.status,
    this.isSelected = false,
  });

  SvnFile copyWith({
    String? path,
    String? status,
    bool? isSelected,
  }) {
    return SvnFile(
      path: path ?? this.path,
      status: status ?? this.status,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SvnFile &&
        other.path == path &&
        other.status == status &&
        other.isSelected == isSelected;
  }

  @override
  int get hashCode {
    return path.hashCode ^ status.hashCode ^ isSelected.hashCode;
  }

  @override
  String toString() {
    return 'SvnFile(path: $path, status: $status, isSelected: $isSelected)';
  }
}
