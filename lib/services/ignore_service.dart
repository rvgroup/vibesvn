import 'package:glob/glob.dart';
import '../services/storage_service.dart';

class IgnoreService {
  static Future<List<String>> filterIgnoredFiles({
    required List<String> files,
    required String repositoryPath,
  }) async {
    final settings = await StorageService.getUserSettings();
    final ignoredPatterns = settings.ignoredPatterns;
    
    final filteredFiles = <String>[];
    
    for (final file in files) {
      if (!_isIgnored(file, ignoredPatterns)) {
        filteredFiles.add(file);
      }
    }
    
    return filteredFiles;
  }

  static bool _isIgnored(String filePath, List<String> patterns) {
    for (final pattern in patterns) {
      if (_matchesPattern(filePath, pattern)) {
        return true;
      }
    }
    return false;
  }

  static bool _matchesPattern(String filePath, String pattern) {
    try {
      final glob = Glob(pattern);
      return glob.matches(filePath);
    } catch (e) {
      // Fallback to simple string matching if glob fails
      return _simpleMatch(filePath, pattern);
    }
  }

  static bool _simpleMatch(String filePath, String pattern) {
    // Simple wildcard matching
    if (pattern.contains('*')) {
      final regexPattern = pattern
          .replaceAll('.', r'\.')
          .replaceAll('*', '.*')
          .replaceAll('?', '.');
      return RegExp(regexPattern).hasMatch(filePath);
    }
    
    return filePath.contains(pattern);
  }

  static Future<void> addIgnorePattern(String pattern) async {
    final settings = await StorageService.getUserSettings();
    final patterns = List<String>.from(settings.ignoredPatterns);
    
    if (!patterns.contains(pattern)) {
      patterns.add(pattern);
      final updatedSettings = settings.copyWith(ignoredPatterns: patterns);
      await StorageService.saveUserSettings(updatedSettings);
    }
  }

  static Future<void> removeIgnorePattern(String pattern) async {
    final settings = await StorageService.getUserSettings();
    final patterns = List<String>.from(settings.ignoredPatterns);
    
    patterns.remove(pattern);
    final updatedSettings = settings.copyWith(ignoredPatterns: patterns);
    await StorageService.saveUserSettings(updatedSettings);
  }

  static Future<void> updateIgnorePatterns(List<String> patterns) async {
    final settings = await StorageService.getUserSettings();
    final updatedSettings = settings.copyWith(ignoredPatterns: patterns);
    await StorageService.saveUserSettings(updatedSettings);
  }

  static List<String> getDefaultPatterns() {
    return [
      '*.tmp',
      '*.log',
      '*.bak',
      '.DS_Store',
      'Thumbs.db',
      'node_modules/',
      '.git/',
      '*.swp',
      '*.swo',
      '*.pyc',
      '__pycache__/',
      '.vscode/',
      '.idea/',
      '*.class',
      '*.jar',
      'target/',
      'build/',
      'dist/',
      '*.orig',
      '*.rej',
    ];
  }

  static List<String> getCommonPatterns() {
    return [
      '*.tmp',
      '*.log',
      '*.bak',
      '.DS_Store',
      'Thumbs.db',
      'node_modules/',
      '.git/',
      '*.swp',
      '*.swo',
      '*.pyc',
      '__pycache__/',
      '.vscode/',
      '.idea/',
      '*.class',
      '*.jar',
      'target/',
      'build/',
      'dist/',
      '*.orig',
      '*.rej',
      '*.exe',
      '*.dll',
      '*.so',
      '*.dylib',
      '*.zip',
      '*.tar.gz',
      '*.rar',
      '*.7z',
      '*.pdf',
      '*.doc',
      '*.docx',
      '*.xls',
      '*.xlsx',
      '*.ppt',
      '*.pptx',
    ];
  }
}
