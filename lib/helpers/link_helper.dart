import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class LinkHelper {
  static bool isUrl(String text) {
    return text.startsWith('http://') || 
           text.startsWith('https://') || 
           text.startsWith('svn://') ||
           text.startsWith('svn+ssh://');
  }
  
  static bool isFilePath(String text) {
    return text.startsWith('/') || text.startsWith('~');
  }
  
  static Future<void> openLink(String text) async {
    try {
      if (isUrl(text)) {
        // Open URL in browser
        final uri = Uri.parse(text);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else if (isFilePath(text)) {
        // Open file/folder in Finder
        final path = text.startsWith('~') ? text.replaceFirst('~', Platform.environment['HOME'] ?? '') : text;
        
        if (await Directory(path).exists()) {
          // It's a directory - open in Finder
          await Process.run('open', [path]);
        } else if (await File(path).exists()) {
          // It's a file - show in Finder
          await Process.run('open', ['-R', path]);
        }
      }
    } catch (e) {
      print('Error opening link: $e');
    }
  }
  
  static String getDisplayText(String text) {
    if (isUrl(text)) {
      return text;
    } else if (isFilePath(text)) {
      // For file paths, show just the last part if it's too long
      final parts = text.split('/');
      if (parts.length > 3) {
        return '.../${parts.sublist(parts.length - 2).join('/')}';
      }
      return text;
    }
    return text;
  }
}
