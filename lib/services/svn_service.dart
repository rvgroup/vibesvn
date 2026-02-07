import 'dart:io';
import '../models/svn_file.dart';
import '../models/svn_result.dart';

class SvnService {
  static Future<bool> isSvnInstalled() async {
    try {
      final result = await Process.run('svn', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  static Future<SvnResult> checkoutRepository({
    required String url,
    required String targetPath,
    required String username,
    required String password,
  }) async {
    try {
      final args = <String>['checkout', url, targetPath, '--non-interactive'];
      
      // Add username and password only if they are provided
      if (username.isNotEmpty) {
        args.addAll(['--username', username]);
      }
      if (password.isNotEmpty) {
        args.addAll(['--password', password]);
      }
      
      print('DEBUG: SVN checkout command: svn ${args.join(' ')}');
      
      final result = await Process.run('svn', args);
      
      print('DEBUG: SVN checkout exit code: ${result.exitCode}');
      print('DEBUG: SVN checkout stdout: ${result.stdout}');
      if (result.stderr.isNotEmpty) {
        print('DEBUG: SVN checkout stderr: ${result.stderr}');
      }
      
      if (result.exitCode != 0) {
        final errorMessage = _formatErrorMessage('SVN checkout', result.exitCode, result.stdout, result.stderr);
        print('ERROR: $errorMessage');
        return SvnResult.error(errorMessage);
      }
      
      return SvnResult.success(result.stdout);
    } catch (e) {
      final errorMessage = 'Exception during SVN checkout: $e';
      print('ERROR: $errorMessage');
      return SvnResult.error(errorMessage);
    }
  }

  static Future<bool> isWorkingCopy(String path) async {
    try {
      // First check if .svn directory exists
      final svnDir = Directory('$path/.svn');
      final exists = await svnDir.exists();
      
      if (!exists) {
        print('DEBUG: .svn directory does not exist in $path');
        return false;
      }
      
      // Additional check: try to run svn info to verify it's a valid working copy
      final result = await Process.run('svn', ['info', path]);
      print('DEBUG: svn info exit code: ${result.exitCode}');
      print('DEBUG: svn info stdout: ${result.stdout}');
      print('DEBUG: svn info stderr: ${result.stderr}');
      
      return result.exitCode == 0;
    } catch (e) {
      print('DEBUG: Error checking working copy: $e');
      return false;
    }
  }

  static Future<String?> getCurrentRevision(String path) async {
    try {
      print('DEBUG: Getting current revision for path: $path');
      final result = await Process.run('svn', ['info', '--show-item=revision', path]);
      print('DEBUG: SVN info revision exit code: ${result.exitCode}');
      print('DEBUG: SVN info revision stdout: ${result.stdout}');
      
      if (result.exitCode == 0) {
        final revision = result.stdout.toString().trim();
        print('DEBUG: Current revision: $revision');
        return revision;
      }
      return null;
    } catch (e) {
      print('DEBUG: Error getting current revision: $e');
      return null;
    }
  }

  static Future<String?> getRepositoryUrl(String path) async {
    try {
      final result = await Process.run('svn', ['info', '--show-item=url', path]);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<SvnFile>> getStatus(String path) async {
    try {
      print('DEBUG: Getting SVN status for path: $path');
      final result = await Process.run('svn', ['status', path]);
      print('DEBUG: SVN status exit code: ${result.exitCode}');
      print('DEBUG: SVN status stdout: ${result.stdout}');
      
      if (result.exitCode != 0) {
        return [];
      }

      final lines = result.stdout.toString().split('\n');
      final files = <SvnFile>[];

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        final status = line.substring(0, 1);
        final filePath = line.substring(1).trim();
        
        print('DEBUG: Parsed file - Status: $status, Path: $filePath');
        
        if (filePath.isNotEmpty) {
          files.add(SvnFile(
            path: filePath,
            status: status,
          ));
        }
      }

      print('DEBUG: Total files found: ${files.length}');
      return files;
    } catch (e) {
      print('DEBUG: Error getting SVN status: $e');
      return [];
    }
  }

  static Future<SvnResult> commit({
    required String path,
    required String message,
    required String username,
    required String password,
    List<String>? files,
  }) async {
    try {
      print('DEBUG: === SVN COMMIT START ===');
      print('DEBUG: Repository path: $path');
      print('DEBUG: Commit message: $message');
      print('DEBUG: Username: "${username}"');
      print('DEBUG: Password: "${password.isNotEmpty ? '***' : 'empty'}"');
      
      final args = <String>['commit', '-m', message, '--non-interactive'];
      
      // Add username and password only if they are provided
      if (username.isNotEmpty) {
        args.addAll(['--username', username]);
      }
      if (password.isNotEmpty) {
        args.addAll(['--password', password]);
      }
      
      if (files != null && files.isNotEmpty) {
        print('DEBUG: Files to commit: $files');
        // Check if files are already full paths or relative paths
        for (final file in files) {
          if (file.startsWith('/')) {
            // File already has full path
            print('DEBUG: Adding full path file to commit: $file');
            args.add(file);
          } else {
            // File is relative, add repository path
            final fullPath = '$path/$file';
            print('DEBUG: Adding relative file to commit: $fullPath');
            args.add(fullPath);
          }
        }
      } else {
        print('DEBUG: No files specified, committing whole path: $path');
        // If no files specified, commit the whole path
        args.add(path);
      }

      print('DEBUG: SVN commit command: svn ${args.join(' ')}');
      print('DEBUG: Working directory: $path');
      
      final result = await Process.run('svn', args, workingDirectory: path);
      
      print('DEBUG: SVN commit exit code: ${result.exitCode}');
      print('DEBUG: SVN commit stdout: ${result.stdout}');
      if (result.stderr.isNotEmpty) {
        print('DEBUG: SVN commit stderr: ${result.stderr}');
      }
      
      if (result.exitCode != 0) {
        final errorMessage = _formatErrorMessage('SVN commit', result.exitCode, result.stdout, result.stderr);
        print('ERROR: $errorMessage');
        return SvnResult.error(errorMessage);
      }
      
      print('DEBUG: SVN commit completed successfully!');
      print('DEBUG: Commit output: ${result.stdout}');
      
      // После успешного коммита обновляем рабочую копию
      print('DEBUG: Updating working copy after commit...');
      final updateResult = await Process.run('svn', ['update'], workingDirectory: path);
      print('DEBUG: SVN update exit code: ${updateResult.exitCode}');
      print('DEBUG: SVN update stdout: ${updateResult.stdout}');
      if (updateResult.stderr.isNotEmpty) {
        print('DEBUG: SVN update stderr: ${updateResult.stderr}');
      }
      
      print('DEBUG: === SVN COMMIT END ===');
      return SvnResult.success('${result.stdout}\n\nUpdate: ${updateResult.stdout}');
    } catch (e) {
      final errorMessage = 'Exception during SVN commit: $e';
      print('ERROR: $errorMessage');
      return SvnResult.error(errorMessage);
    }
  }

  static String _formatErrorMessage(String operation, int exitCode, String stdout, String stderr) {
    final buffer = StringBuffer();
    buffer.write('$operation failed (exit code: $exitCode)');
    
    if (stderr.isNotEmpty) {
      buffer.write('\nError: $stderr');
    }
    
    if (stdout.isNotEmpty) {
      buffer.write('\nOutput: $stdout');
    }
    
    return buffer.toString();
  }

  static Future<SvnResult> update({
    required String path,
    required String username,
    required String password,
  }) async {
    try {
      final args = <String>['update', path, '--non-interactive'];
      
      // Add username and password only if they are provided
      if (username.isNotEmpty) {
        args.addAll(['--username', username]);
      }
      if (password.isNotEmpty) {
        args.addAll(['--password', password]);
      }
      
      print('DEBUG: SVN update command: svn ${args.join(' ')}');
      
      final result = await Process.run('svn', args);
      
      print('DEBUG: SVN update exit code: ${result.exitCode}');
      print('DEBUG: SVN update stdout: ${result.stdout}');
      if (result.stderr.isNotEmpty) {
        print('DEBUG: SVN update stderr: ${result.stderr}');
      }
      
      if (result.exitCode != 0) {
        final errorMessage = _formatErrorMessage('SVN update', result.exitCode, result.stdout, result.stderr);
        print('ERROR: $errorMessage');
        return SvnResult.error(errorMessage);
      }
      
      return SvnResult.success(result.stdout);
    } catch (e) {
      final errorMessage = 'Exception during SVN update: $e';
      print('ERROR: $errorMessage');
      return SvnResult.error(errorMessage);
    }
  }

  static Future<SvnResult> add(String filePath, {String? workingDirectory}) async {
    try {
      final args = ['add', filePath];
      
      print('DEBUG: SVN add command: svn ${args.join(' ')}');
      if (workingDirectory != null) {
        print('DEBUG: Working directory: $workingDirectory');
      }
      
      final result = await Process.run('svn', args, workingDirectory: workingDirectory);
      
      print('DEBUG: SVN add exit code: ${result.exitCode}');
      print('DEBUG: SVN add stdout: ${result.stdout}');
      if (result.stderr.isNotEmpty) {
        print('DEBUG: SVN add stderr: ${result.stderr}');
      }
      
      if (result.exitCode != 0) {
        final errorMessage = _formatErrorMessage('SVN add', result.exitCode, result.stdout, result.stderr);
        print('ERROR: $errorMessage');
        return SvnResult.error(errorMessage);
      }
      
      return SvnResult.success(result.stdout);
    } catch (e) {
      final errorMessage = 'Exception during SVN add: $e';
      print('ERROR: $errorMessage');
      return SvnResult.error(errorMessage);
    }
  }

  static Future<SvnResult> revert(List<String> filePaths, {String? workingDirectory}) async {
    try {
      final args = ['revert', ...filePaths];
      
      print('DEBUG: SVN revert command: svn ${args.join(' ')}');
      if (workingDirectory != null) {
        print('DEBUG: Working directory: $workingDirectory');
      }
      
      final result = await Process.run('svn', args, workingDirectory: workingDirectory);
      
      print('DEBUG: SVN revert exit code: ${result.exitCode}');
      print('DEBUG: SVN revert stdout: ${result.stdout}');
      if (result.stderr.isNotEmpty) {
        print('DEBUG: SVN revert stderr: ${result.stderr}');
      }
      
      if (result.exitCode != 0) {
        final errorMessage = _formatErrorMessage('SVN revert', result.exitCode, result.stdout, result.stderr);
        print('ERROR: $errorMessage');
        return SvnResult.error(errorMessage);
      }
      
      return SvnResult.success(result.stdout);
    } catch (e) {
      final errorMessage = 'Exception during SVN revert: $e';
      print('ERROR: $errorMessage');
      return SvnResult.error(errorMessage);
    }
  }

  static Future<String?> getLog(String path, {int limit = 10}) async {
    try {
      final args = [
        'log', 
        path, 
        '--limit', limit.toString(),
        '--xml',
        '--non-interactive'
      ];
      
      print('DEBUG: SVN log command: svn ${args.join(' ')}');
      
      final result = await Process.run('svn', args);
      
      print('DEBUG: SVN log exit code: ${result.exitCode}');
      print('DEBUG: SVN log stdout: ${result.stdout}');
      if (result.stderr.isNotEmpty) {
        print('DEBUG: SVN log stderr: ${result.stderr}');
      }
      
      if (result.exitCode != 0) {
        print('ERROR: SVN log failed with exit code ${result.exitCode}');
        print('ERROR: Command output: ${result.stdout}');
        if (result.stderr.isNotEmpty) {
          print('ERROR: Error output: ${result.stderr}');
        }
        return null;
      }
      
      return result.stdout.toString();
    } catch (e) {
      print('ERROR: Exception during SVN log: $e');
      return null;
    }
  }

  static Future<SvnResult> getDiff(String repositoryPath, {String? filePath}) async {
    try {
      final args = ['diff'];
      
      // Add specific file if provided
      if (filePath != null) {
        args.add(filePath);
      }
      
      print('DEBUG: SVN diff command: svn ${args.join(' ')}');
      print('DEBUG: Working directory: $repositoryPath');
      
      final result = await Process.run('svn', args, workingDirectory: repositoryPath);
      
      print('DEBUG: SVN diff exit code: ${result.exitCode}');
      print('DEBUG: SVN diff stdout: ${result.stdout}');
      if (result.stderr.isNotEmpty) {
        print('DEBUG: SVN diff stderr: ${result.stderr}');
      }
      
      if (result.exitCode != 0) {
        final errorMessage = _formatErrorMessage('SVN diff', result.exitCode, result.stdout, result.stderr);
        print('ERROR: $errorMessage');
        return SvnResult.error(errorMessage);
      }
      
      print('DEBUG: SVN diff completed successfully!');
      return SvnResult.success(result.stdout);
    } catch (e) {
      final errorMessage = 'Exception during SVN diff: $e';
      print('ERROR: $errorMessage');
      return SvnResult.error(errorMessage);
    }
  }

  static Future<SvnResult> cleanup(String path) async {
    try {
      final args = ['cleanup', path];
      
      print('DEBUG: SVN cleanup command: svn ${args.join(' ')}');
      
      final result = await Process.run('svn', args);
      
      print('DEBUG: SVN cleanup exit code: ${result.exitCode}');
      print('DEBUG: SVN cleanup stdout: ${result.stdout}');
      if (result.stderr.isNotEmpty) {
        print('DEBUG: SVN cleanup stderr: ${result.stderr}');
      }
      
      if (result.exitCode != 0) {
        final errorMessage = _formatErrorMessage('SVN cleanup', result.exitCode, result.stdout, result.stderr);
        print('ERROR: $errorMessage');
        return SvnResult.error(errorMessage);
      }
      
      return SvnResult.success(result.stdout);
    } catch (e) {
      final errorMessage = 'Exception during SVN cleanup: $e';
      print('ERROR: $errorMessage');
      return SvnResult.error(errorMessage);
    }
  }

  static Future<SvnResult> cat(String repositoryPath, String filePath) async {
    try {
      final args = ['cat', filePath];
      
      print('DEBUG: SVN cat command: svn ${args.join(' ')}');
      print('DEBUG: Working directory: $repositoryPath');
      
      final result = await Process.run('svn', args, workingDirectory: repositoryPath);
      
      print('DEBUG: SVN cat exit code: ${result.exitCode}');
      print('DEBUG: SVN cat stdout length: ${result.stdout.length}');
      if (result.stderr.isNotEmpty) {
        print('DEBUG: SVN cat stderr: ${result.stderr}');
      }
      
      if (result.exitCode != 0) {
        final errorMessage = _formatErrorMessage('SVN cat', result.exitCode, result.stdout, result.stderr);
        print('ERROR: $errorMessage');
        return SvnResult.error(errorMessage);
      }
      
      print('DEBUG: SVN cat completed successfully!');
      return SvnResult.success(result.stdout);
    } catch (e) {
      final errorMessage = 'Exception during SVN cat: $e';
      print('ERROR: $errorMessage');
      return SvnResult.error(errorMessage);
    }
  }
}
