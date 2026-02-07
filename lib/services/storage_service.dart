import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/repository.dart';
import '../models/user_settings.dart';

class StorageService {
  static const String _repositoriesKey = 'svn_repositories';
  static const String _userSettingsKey = 'user_settings';
  static const String _commitHistoryKey = 'commit_history';
  static const String _windowPositionKey = 'window_position';
  static const String _windowSizeKey = 'window_size';

  static Future<void> saveRepositories(List<SvnRepository> repositories) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = repositories.map((repo) => repo.toJson()).toList();
    await prefs.setString(_repositoriesKey, jsonEncode(jsonList));
  }

  static Future<List<SvnRepository>> getRepositories() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_repositoriesKey);
    
    if (jsonString == null) return [];
    
    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => SvnRepository.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> addRepository(SvnRepository repository) async {
    final repositories = await getRepositories();
    repositories.add(repository);
    await saveRepositories(repositories);
  }

  static Future<void> removeRepository(String repositoryId) async {
    final repositories = await getRepositories();
    repositories.removeWhere((repo) => repo.id == repositoryId);
    await saveRepositories(repositories);
  }

  static Future<void> updateRepository(SvnRepository repository) async {
    final repositories = await getRepositories();
    final index = repositories.indexWhere((repo) => repo.id == repository.id);
    
    if (index != -1) {
      repositories[index] = repository;
      await saveRepositories(repositories);
    }
  }

  static Future<void> saveUserSettings(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final json = settings.toJson();
    print('DEBUG: Saving user settings JSON:');
    print(json);
    await prefs.setString(_userSettingsKey, jsonEncode(json));
  }

  static Future<UserSettings> getUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_userSettingsKey);
    
    print('DEBUG: Loading user settings JSON string:');
    print(jsonString);
    
    if (jsonString == null) {
      print('DEBUG: No settings found, returning defaults');
      return UserSettings(
        username: '',
        password: '',
        defaultClonePath: '',
      );
    }
    
    try {
      final json = jsonDecode(jsonString);
      return UserSettings.fromJson(json);
    } catch (e) {
      return UserSettings(
        username: '',
        password: '',
        defaultClonePath: '',
      );
    }
  }

  static Future<void> saveCommitMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_commitHistoryKey) ?? '[]';
    
    try {
      final history = List<String>.from(jsonDecode(historyJson));
      history.remove(message);
      history.insert(0, message);
      
      if (history.length > 50) {
        history.removeRange(50, history.length);
      }
      
      await prefs.setString(_commitHistoryKey, jsonEncode(history));
    } catch (e) {
      // Ignore errors for commit history
    }
  }

  static Future<List<String>> getCommitHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_commitHistoryKey) ?? '[]';
    
    try {
      return List<String>.from(jsonDecode(historyJson));
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_repositoriesKey);
    await prefs.remove(_userSettingsKey);
    await prefs.remove(_commitHistoryKey);
    await prefs.remove(_windowPositionKey);
    await prefs.remove(_windowSizeKey);
  }

  // Window position and size methods
  static Future<void> saveWindowPosition(double x, double y) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_windowPositionKey, jsonEncode({'x': x, 'y': y}));
  }

  static Future<Map<String, double>?> getWindowPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_windowPositionKey);
    
    if (jsonString == null) return null;
    
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return {
        'x': (json['x'] as num).toDouble(),
        'y': (json['y'] as num).toDouble(),
      };
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveWindowSize(double width, double height) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_windowSizeKey, jsonEncode({'width': width, 'height': height}));
  }

  static Future<Map<String, double>?> getWindowSize() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_windowSizeKey);
    
    if (jsonString == null) return null;
    
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return {
        'width': (json['width'] as num).toDouble(),
        'height': (json['height'] as num).toDouble(),
      };
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveWindowState({
    double? x,
    double? y,
    double? width,
    double? height,
  }) async {
    if (x != null && y != null) {
      await saveWindowPosition(x, y);
    }
    if (width != null && height != null) {
      await saveWindowSize(width, height);
    }
  }
}
