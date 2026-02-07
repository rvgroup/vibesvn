import 'dart:io';
import 'package:flutter/material.dart';
import '../models/repository.dart';
import '../models/svn_file.dart';
import '../models/svn_result.dart';
import '../models/user_settings.dart';
import '../services/storage_service.dart';
import '../services/svn_service.dart';
import '../services/commit_template_service.dart';
import '../helpers/error_helper.dart';
import '../helpers/link_helper.dart';
import '../widgets/clickable_text.dart';

class CommitScreen extends StatefulWidget {
  final SvnRepository repository;

  const CommitScreen({
    super.key,
    required this.repository,
  });

  @override
  State<CommitScreen> createState() => _CommitScreenState();
}

class _CommitScreenState extends State<CommitScreen> {
  final _messageController = TextEditingController();
  List<SvnFile> _files = [];
  List<String> _commitHistory = [];
  List<String> _commitTemplates = [];
  List<String> _recentCommitMessages = [];
  bool _isLoading = false;
  bool _isCommitting = false;
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final files = await SvnService.getStatus(widget.repository.localPath);
      final history = await StorageService.getCommitHistory();
      final templates = await CommitTemplateService.getTemplates();
      
      setState(() {
        _files = files;
        _commitHistory = history;
        _commitTemplates = templates;
        _isLoading = false;
      });
      
      // Load recent commit messages separately
      _loadRecentCommitMessages();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRecentCommitMessages() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final log = await SvnService.getLog(widget.repository.localPath, limit: 20);
      if (log != null) {
        final messages = _parseCommitMessages(log);
        if (mounted) {
          setState(() {
            _recentCommitMessages = messages;
            _isLoadingHistory = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingHistory = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
        print('Error loading commit history: $e');
      }
    }
  }

  List<String> _parseCommitMessages(String log) {
    final messages = <String>[];
    
    // Parse XML format from SVN log
    try {
      // Simple XML parsing without external libraries
      final logEntryPattern = RegExp(r'<logentry[^>]*>.*?</logentry>', dotAll: true);
      final msgPattern = RegExp(r'<msg>(.*?)</msg>', dotAll: true);
      
      final logEntries = logEntryPattern.allMatches(log).map((match) => match.group(0)!).toList();
      
      for (final entry in logEntries) {
        final msgMatch = msgPattern.firstMatch(entry);
        if (msgMatch != null) {
          var message = msgMatch.group(1) ?? '';
          
          // Clean up XML entities and whitespace
          message = message
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>')
              .replaceAll('&amp;', '&')
              .replaceAll('&quot;', '"')
              .replaceAll('&#39;', "'")
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          
          if (message.isNotEmpty) {
            messages.add(message);
          }
        }
      }
    } catch (e) {
      // Fallback to simple line parsing
      final lines = log.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.length > 5 && !trimmed.startsWith('<') && !trimmed.startsWith('r')) {
          messages.add(trimmed);
        }
      }
    }
    
    // SVN log already returns messages in reverse chronological order (newest first)
    return messages;
  }

  void _selectAllFiles() {
    setState(() {
      _files = _files.map((file) => file.copyWith(isSelected: true)).toList();
    });
  }

  void _deselectAllFiles() {
    setState(() {
      _files = _files.map((file) => file.copyWith(isSelected: false)).toList();
    });
  }

  void _toggleFileSelection(int index) {
    setState(() {
      _files[index] = _files[index].copyWith(isSelected: !_files[index].isSelected);
    });
  }

  void _showCommitHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('История коммитов'),
            const Spacer(),
            if (_isLoadingHistory)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadRecentCommitMessages,
                tooltip: 'Обновить',
              ),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 400,
          child: _recentCommitMessages.isEmpty
              ? const Center(
                  child: Text('Нет истории коммитов'),
                )
              : ListView.builder(
                  itemCount: _recentCommitMessages.length,
                  itemBuilder: (context, index) {
                    final message = _recentCommitMessages[index];
                    return ListTile(
                      title: Text(
                        message.length > 100 
                            ? '${message.substring(0, 100)}...'
                            : message,
                      ),
                      subtitle: Text('Коммит #${index + 1}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          _messageController.text = message;
                          Navigator.pop(context);
                        },
                        tooltip: 'Использовать это сообщение',
                      ),
                      onTap: () {
                        _messageController.text = message;
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _commit() async {
    final selectedFiles = _files.where((file) => file.isSelected).toList();
    
    if (selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите хотя бы один файл для коммита'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите сообщение коммита'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isCommitting = true;
    });

    try {
      final settings = await StorageService.getUserSettings();
      
      // Добавляем новые файлы в SVN
      for (final file in selectedFiles) {
        if (file.status == '?') {
          final addResult = await SvnService.add('${widget.repository.localPath}/${file.path}');
          if (!addResult.success) {
            ErrorHelper.showSvnError(context, addResult, 'Ошибка добавления файла ${file.path}');
            return;
          }
        }
      }

      final filePaths = selectedFiles.map((file) => file.path).toList();
      
      final commitResult = await SvnService.commit(
        path: widget.repository.localPath,
        message: _messageController.text.trim(),
        username: settings.username,
        password: settings.password,
        files: filePaths,
      );

      if (commitResult.success) {
        await StorageService.saveCommitMessage(_messageController.text.trim());
        
        // Очищаем кэш истории коммитов и загружаем свежую
        setState(() {
          _recentCommitMessages.clear();
        });
        await _loadRecentCommitMessages();
        
        // Clean up the revision number - remove newlines and extra spaces
        final revisionText = commitResult.output?.split(' ').last ?? '';
        final cleanRevision = revisionText.replaceAll(RegExp(r'\s+'), '');
        
        ErrorHelper.showSuccess(context, 'Коммит успешно выполнен (ревизия $cleanRevision)');
        Navigator.pop(context);
      } else {
        ErrorHelper.showSvnError(context, commitResult, 'Ошибка при выполнении коммита');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCommitting = false;
      });
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'M':
        return 'Изменен';
      case 'A':
        return 'Добавлен';
      case 'D':
        return 'Удален';
      case '?':
        return 'Не отслеживается';
      case '!':
        return 'Отсутствует';
      case 'C':
        return 'Конфликт';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'M':
        return Colors.orange;
      case 'A':
        return Colors.green;
      case 'D':
        return Colors.red;
      case '?':
        return Colors.grey;
      case '!':
        return Colors.red;
      case 'C':
        return Colors.purple;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Коммит'),
            ClickableText(
              text: widget.repository.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
              onTap: () async {
                await LinkHelper.openLink(widget.repository.localPath);
              },
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Информация о репозитории
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commit to:',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        ClickableText(
                          text: widget.repository.remoteUrl,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Сообщение коммита
                  Text(
                    'Сообщение коммита:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _messageController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Введите описание изменений...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _showCommitHistoryDialog,
                        icon: const Icon(Icons.history),
                        tooltip: 'История коммитов',
                      ),
                      IconButton(
                        onPressed: _loadRecentCommitMessages,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Обновить историю',
                      ),
                    ],
                  ),
                  
                  // История коммитов
                  if (_commitHistory.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _commitHistory.length,
                        itemBuilder: (context, index) {
                          final message = _commitHistory[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(
                                message.length > 30 
                                    ? '${message.substring(0, 30)}...'
                                    : message,
                              ),
                              onPressed: () {
                                _messageController.text = message;
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  
                  // Шаблоны коммитов
                  if (_commitTemplates.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Шаблоны:',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _commitTemplates.length,
                        itemBuilder: (context, index) {
                          final template = _commitTemplates[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(
                                template.length > 25 
                                    ? '${template.substring(0, 25)}...'
                                    : template,
                              ),
                              onPressed: () {
                                _messageController.text = CommitTemplateService.formatTemplate(template);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Кнопки действий с файлами
                  Row(
                    children: [
                      TextButton(
                        onPressed: _selectAllFiles,
                        child: const Text('Выбрать все'),
                      ),
                      TextButton(
                        onPressed: _deselectAllFiles,
                        child: const Text('Убрать все'),
                      ),
                      const Spacer(),
                      Text(
                        'Выбрано: ${_files.where((f) => f.isSelected).length}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Список файлов
                  Expanded(
                    child: _files.isEmpty
                        ? const Center(
                            child: Text(
                              'Нет измененных файлов',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _files.length,
                            itemBuilder: (context, index) {
                              final file = _files[index];
                              return InkWell(
                                  onTap: () {
                                    // Single tap - toggle file selection
                                    _toggleFileSelection(index);
                                  },
                                  onDoubleTap: () {
                                    // Double tap - open folder and select file
                                    // Check if file.path is already absolute or relative
                                    final fullPath = file.path.startsWith('/') 
                                        ? file.path 
                                        : '${widget.repository.localPath}/${file.path}';
                                    LinkHelper.openLink(fullPath);
                                  },
                                  onLongPress: () {
                                    // Long press - open diff tool for modified files
                                    if (_isFileModified(file.status)) {
                                      // Use relative path for diff tool
                                      final relativePath = file.path.startsWith('/') 
                                          ? file.path.substring(widget.repository.localPath.length + 1)
                                          : file.path;
                                      _openDiffTool(relativePath);
                                    } else {
                                      // Show message for non-modified files
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Файл "${file.path}" не имеет изменений для просмотра'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: file.isSelected, 
                                          onChanged: (value) => _toggleFileSelection(index),
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(file.status),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              file.status,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ClickableText(
                                            text: file.path,
                                            style: Theme.of(context).textTheme.bodySmall,
                                            enableLinkDetection: false, // Disable default link behavior
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                            },
                          ),
                  ),
                  
                  // Кнопки действий
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isCommitting ? null : () => Navigator.pop(context),
                          child: const Text('Отмена'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isCommitting ? null : _commit,
                          child: _isCommitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('OK'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  bool _isFileModified(String status) {
    // Check if file has modifications that can be shown in diff
    return status == 'M' ||  // Modified
           status == 'A' ||  // Added  
           status == 'D' ||  // Deleted
           status == 'R';    // Replaced
  }

  Future<void> _openDiffTool(String filePath) async {
    try {
      // Get user settings to check for external diff tool
      final userSettings = await StorageService.getUserSettings();
      final externalDiffTool = userSettings.externalDiffTool;
      
      if (externalDiffTool.isNotEmpty) {
        // Use external diff tool
        await _openExternalDiffTool(externalDiffTool, filePath);
      } else {
        // Use built-in diff viewer
        await _openBuiltInDiffTool(filePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при открытии diff: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _openExternalDiffTool(String diffToolPath, String filePath) async {
    try {
      final repositoryPath = widget.repository.localPath;
      
      // Check if filePath is already absolute or relative
      final fullPath = filePath.startsWith('/') ? filePath : '$repositoryPath/$filePath';
      
      // Check if current file exists
      final currentFile = File(fullPath);
      if (!await currentFile.exists()) {
        throw Exception('Current file does not exist: $fullPath');
      }
      
      // Get the relative path for SVN operations
      final relativePath = filePath.startsWith('/') 
          ? filePath.substring(repositoryPath.length + 1) 
          : filePath;
      
      // Get the original file from SVN
      final originalResult = await SvnService.cat(repositoryPath, relativePath);
      
      if (originalResult.success && originalResult.output != null) {
        // Create temporary directory
        final tempDir = '/tmp/vibesvn_diff_${DateTime.now().millisecondsSinceEpoch}';
        await Process.run('mkdir', ['-p', tempDir]);
        
        // Create simple file names (avoid subdirectories in temp)
        final fileName = relativePath.split('/').last;
        final originalFile = '$tempDir/original_$fileName';
        final modifiedFile = '$tempDir/modified_$fileName';
        
        // Write original file content
        final originalFileObj = File(originalFile);
        await originalFileObj.writeAsString(originalResult.output!);
        
        // Copy current file content
        await Process.run('cp', [fullPath, modifiedFile]);
        
        // Verify files exist
        if (!await File(originalFile).exists()) {
          throw Exception('Failed to create original temp file: $originalFile');
        }
        if (!await File(modifiedFile).exists()) {
          throw Exception('Failed to create modified temp file: $modifiedFile');
        }
        
        // Check if it's VS Code and use --diff flag
        final isVSCode = diffToolPath.contains('Visual Studio Code') || diffToolPath.contains('code');
        final List<String> args;
        
        if (isVSCode) {
          args = ['--diff', originalFile, modifiedFile];
        } else {
          args = [originalFile, modifiedFile];
        }
        
        // Launch external diff tool
        final result = await Process.run(diffToolPath, args);
        
        // For VS Code, don't clean up immediately since it runs in background
        if (!isVSCode) {
          // Clean up temporary files
          await Process.run('rm', ['-rf', tempDir]);
        } else {
          // Schedule cleanup after 10 minutes
          Future.delayed(const Duration(minutes: 10), () async {
            await Process.run('rm', ['-rf', tempDir]);
          });
        }
        
        if (result.exitCode != 0) {
          throw Exception('External diff tool failed with exit code ${result.exitCode}');
        }
      } else {
        throw Exception('Failed to get original file content from SVN: ${originalResult.errorMessage}');
      }
    } catch (e) {
      // Fallback to built-in diff tool
      await _openBuiltInDiffTool(filePath);
    }
  }

  Future<void> _openBuiltInDiffTool(String filePath) async {
    try {
      // Get diff output from SVN
      final diffResult = await SvnService.getDiff(
        widget.repository.localPath,
        filePath: filePath,
      );
      
      if (diffResult.success && diffResult.output != null && diffResult.output!.isNotEmpty) {
        // Show diff in a dialog
        if (mounted) {
          _showDiffDialog(filePath, diffResult.output!);
        }
      } else {
        // Show error if diff failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Не удалось получить изменения для файла: $filePath'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('DEBUG: Error with built-in diff tool: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при открытии diff: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showDiffDialog(String filePath, String diffContent) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Изменения в файле: $filePath',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      diffContent,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Закрыть'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
