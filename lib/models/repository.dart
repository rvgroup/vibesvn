class SvnRepository {
  final String id;
  final String name;
  final String localPath;
  final String remoteUrl;
  final DateTime createdAt;
  final DateTime lastAccessed;
  final String? currentRevision;

  SvnRepository({
    required this.id,
    required this.name,
    required this.localPath,
    required this.remoteUrl,
    required this.createdAt,
    required this.lastAccessed,
    this.currentRevision,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'localPath': localPath,
      'remoteUrl': remoteUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastAccessed': lastAccessed.toIso8601String(),
      'currentRevision': currentRevision,
    };
  }

  factory SvnRepository.fromJson(Map<String, dynamic> json) {
    return SvnRepository(
      id: json['id'],
      name: json['name'],
      localPath: json['localPath'],
      remoteUrl: json['remoteUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      lastAccessed: DateTime.parse(json['lastAccessed']),
      currentRevision: json['currentRevision'],
    );
  }

  SvnRepository copyWith({
    String? id,
    String? name,
    String? localPath,
    String? remoteUrl,
    DateTime? createdAt,
    DateTime? lastAccessed,
    String? currentRevision,
  }) {
    return SvnRepository(
      id: id ?? this.id,
      name: name ?? this.name,
      localPath: localPath ?? this.localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      createdAt: createdAt ?? this.createdAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      currentRevision: currentRevision ?? this.currentRevision,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SvnRepository &&
        other.id == id &&
        other.name == name &&
        other.localPath == localPath &&
        other.remoteUrl == remoteUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        localPath.hashCode ^
        remoteUrl.hashCode;
  }

  @override
  String toString() {
    return 'SvnRepository(id: $id, name: $name, localPath: $localPath, remoteUrl: $remoteUrl)';
  }
}
