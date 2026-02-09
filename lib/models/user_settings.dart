class UserSettings {
  final String username;
  final String password;
  final String defaultClonePath;
  final bool autoSaveCredentials;
  final int commitMessageHistoryLimit;
  final AppTheme appTheme;
  final List<String> ignoredPatterns;
  final List<String> commitTemplates;
  final bool autoUpdateRepositories;
  final String externalDiffTool;
  final String externalFileViewer;
  final ProxySettings? proxySettings;

  UserSettings({
    required this.username,
    required this.password,
    required this.defaultClonePath,
    this.autoSaveCredentials = true,
    this.commitMessageHistoryLimit = 50,
    this.appTheme = AppTheme.system,
    this.ignoredPatterns = const [
      '*.tmp',
      '*.log',
      '*.bak',
      '.DS_Store',
      'Thumbs.db',
      'node_modules/',
      '.git/',
      '*.swp',
      '*.swo',
    ],
    this.commitTemplates = const [
      'feat: {description}',
      'fix: {description}',
      'docs: {description}',
      'style: {description}',
      'refactor: {description}',
      'test: {description}',
      'chore: {description}',
      'hotfix: {description}',
      'revert: {description}',
    ],
    this.autoUpdateRepositories = false,
    this.externalDiffTool = '',
    this.externalFileViewer = '',
    this.proxySettings,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'defaultClonePath': defaultClonePath,
      'autoSaveCredentials': autoSaveCredentials,
      'commitMessageHistoryLimit': commitMessageHistoryLimit,
      'appTheme': appTheme.name,
      'ignoredPatterns': ignoredPatterns,
      'commitTemplates': commitTemplates,
      'autoUpdateRepositories': autoUpdateRepositories,
      'externalDiffTool': externalDiffTool,
      'externalFileViewer': externalFileViewer,
      'proxySettings': proxySettings?.toJson(),
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      defaultClonePath: json['defaultClonePath'] ?? '',
      autoSaveCredentials: json['autoSaveCredentials'] ?? true,
      commitMessageHistoryLimit: json['commitMessageHistoryLimit'] ?? 50,
      appTheme: AppTheme.values.firstWhere(
        (theme) => theme.name == json['appTheme'],
        orElse: () => AppTheme.system,
      ),
      ignoredPatterns: List<String>.from(json['ignoredPatterns'] ?? [
        '*.tmp',
        '*.log',
        '*.bak',
        '.DS_Store',
        'Thumbs.db',
        'node_modules/',
        '.git/',
        '*.swp',
        '*.swo',
      ]),
      commitTemplates: List<String>.from(json['commitTemplates'] ?? [
        'feat: {description}',
        'fix: {description}',
        'docs: {description}',
        'style: {description}',
        'refactor: {description}',
        'test: {description}',
        'chore: {description}',
        'hotfix: {description}',
        'revert: {description}',
      ]),
      autoUpdateRepositories: json['autoUpdateRepositories'] ?? false,
      externalDiffTool: json['externalDiffTool'] ?? '',
      externalFileViewer: json['externalFileViewer'] ?? '',
      proxySettings: json['proxySettings'] != null 
          ? ProxySettings.fromJson(json['proxySettings'])
          : null,
    );
  }

  UserSettings copyWith({
    String? username,
    String? password,
    String? defaultClonePath,
    bool? autoSaveCredentials,
    int? commitMessageHistoryLimit,
    AppTheme? appTheme,
    List<String>? ignoredPatterns,
    List<String>? commitTemplates,
    bool? autoUpdateRepositories,
    String? externalDiffTool,
    String? externalFileViewer,
    ProxySettings? proxySettings,
  }) {
    return UserSettings(
      username: username ?? this.username,
      password: password ?? this.password,
      defaultClonePath: defaultClonePath ?? this.defaultClonePath,
      autoSaveCredentials: autoSaveCredentials ?? this.autoSaveCredentials,
      commitMessageHistoryLimit: commitMessageHistoryLimit ?? this.commitMessageHistoryLimit,
      appTheme: appTheme ?? this.appTheme,
      ignoredPatterns: ignoredPatterns ?? this.ignoredPatterns,
      commitTemplates: commitTemplates ?? this.commitTemplates,
      autoUpdateRepositories: autoUpdateRepositories ?? this.autoUpdateRepositories,
      externalDiffTool: externalDiffTool ?? this.externalDiffTool,
      externalFileViewer: externalFileViewer ?? this.externalFileViewer,
      proxySettings: proxySettings ?? this.proxySettings,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSettings &&
        other.username == username &&
        other.password == password &&
        other.defaultClonePath == defaultClonePath &&
        other.autoSaveCredentials == autoSaveCredentials &&
        other.commitMessageHistoryLimit == commitMessageHistoryLimit &&
        other.appTheme == appTheme &&
        other.ignoredPatterns == ignoredPatterns &&
        other.commitTemplates == commitTemplates &&
        other.autoUpdateRepositories == autoUpdateRepositories &&
        other.externalDiffTool == externalDiffTool &&
        other.externalFileViewer == externalFileViewer &&
        other.proxySettings == proxySettings;
  }

  @override
  int get hashCode {
    return username.hashCode ^
        password.hashCode ^
        defaultClonePath.hashCode ^
        autoSaveCredentials.hashCode ^
        commitMessageHistoryLimit.hashCode ^
        appTheme.hashCode ^
        ignoredPatterns.hashCode ^
        commitTemplates.hashCode ^
        autoUpdateRepositories.hashCode ^
        externalDiffTool.hashCode ^
        externalFileViewer.hashCode ^
        proxySettings.hashCode;
  }

  @override
  String toString() {
    return 'UserSettings(username: $username, defaultClonePath: $defaultClonePath, autoSaveCredentials: $autoSaveCredentials, appTheme: $appTheme)';
  }
}

enum AppTheme {
  light,
  dark,
  system,
}

class ProxySettings {
  final bool enabled;
  final String host;
  final int port;
  final String? username;
  final String? password;

  ProxySettings({
    required this.enabled,
    required this.host,
    required this.port,
    this.username,
    this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'host': host,
      'port': port,
      'username': username,
      'password': password,
    };
  }

  factory ProxySettings.fromJson(Map<String, dynamic> json) {
    return ProxySettings(
      enabled: json['enabled'] ?? false,
      host: json['host'] ?? '',
      port: json['port'] ?? 8080,
      username: json['username'],
      password: json['password'],
    );
  }
}
