import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/repository.dart';
import '../models/svn_file.dart';
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
  Set<String> _selectedStatuses = {}; // Выбранные статусы для фильтрации
  String _fileFilter = ''; // Фильтр файлов по маске

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
            content: Text('Error loading data: {error}'.tr().replaceAll('{error}', e.toString())),
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
      for (final file in _files) {
        file.isSelected = true;
      }
    });
  }

  void _deselectAllFiles() {
    setState(() {
      for (final file in _files) {
        file.isSelected = false;
      }
    });
  }

  void _toggleFileSelection(int filteredIndex) {
    // Находим индекс файла в оригинальном списке
    final filteredFile = _filteredFiles[filteredIndex];
    final originalIndex = _files.indexWhere((file) => file.path == filteredFile.path);
    
    if (originalIndex != -1) {
      setState(() {
        _files[originalIndex].isSelected = !_files[originalIndex].isSelected;
      });
    }
  }

  List<SvnFile> get _filteredFiles {
    if (_fileFilter.isEmpty) return _files;
    
    final filterPattern = _fileFilter.replaceAll('*', '.*').replaceAll('?', '.');
    try {
      final regex = RegExp(filterPattern, caseSensitive: false);
      return _files.where((file) => regex.hasMatch(file.path)).toList();
    } catch (e) {
      // Если regex некорректный, возвращаем пустой список
      return [];
    }
  }

  void _showCommitHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text('Commit History'.tr()),
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
                tooltip: 'Refresh'.tr(),
              ),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 400,
          child: _recentCommitMessages.isEmpty
              ? Center(
                  child: Text('No commit history'.tr()),
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
                      subtitle: Text('Commit #{number}'.tr().replaceAll('{number}', (index + 1).toString())),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          _messageController.text = message;
                          Navigator.pop(context);
                        },
                        tooltip: 'Use this message'.tr(),
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
            child: Text('Close'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _commit() async {
    final selectedFiles = _files.where((file) => file.isSelected).toList();
    
    if (selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Select at least one file to commit'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter commit message'.tr()),
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
          // Используем workingDirectory для выполнения команды в папке репозитория
          final addResult = await SvnService.add(file.path, workingDirectory: widget.repository.localPath);
          if (!addResult.success) {
            ErrorHelper.showSvnError(context, addResult, 'Error adding file {path}'.tr().replaceAll('{path}', file.path));
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
        
        ErrorHelper.showSuccess(context, 'Commit successful (revision {revision})'.tr().replaceAll('{revision}', cleanRevision));
        Navigator.pop(context);
      } else {
        ErrorHelper.showSvnError(context, commitResult, 'Error during commit'.tr());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: {error}'.tr().replaceAll('{error}', e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCommitting = false;
      });
    }
  }

  void _toggleStatusSelection(String status) {
    setState(() {
      if (_selectedStatuses.contains(status)) {
        _selectedStatuses.remove(status);
      } else {
        _selectedStatuses.add(status);
      }
    });
  }

  void _selectFilesByStatus(String status, bool select) {
    setState(() {
      for (final file in _files) {
        if (file.status == status) {
          file.isSelected = select;
        }
      }
    });
  }

  void _toggleFilesByStatus(String status) {
    final filesWithStatus = _files.where((file) => file.status == status).toList();
    if (filesWithStatus.isEmpty) return;
    
    final allSelected = filesWithStatus.every((file) => file.isSelected);
    _selectFilesByStatus(status, !allSelected);
  }

  int _getFilesCountByStatus(String status) {
    return _files.where((file) => file.status == status).length;
  }

  int _getSelectedFilesCountByStatus(String status) {
    return _files.where((file) => file.status == status && file.isSelected).length;
  }

  List<SvnFile> _getRevertableFiles() {
    // Файлы, которые можно восстановить: измененные (M), удаленные/отсутствующие (!), замененные (R)
    return _files.where((file) =>
        file.isSelected && 
        (file.status == 'M' || file.status == '!' || file.status == 'R')
    ).toList();
  }

  bool _hasRevertableFiles() {
    return _getRevertableFiles().isNotEmpty;
  }

  Future<void> _revertSelectedFiles() async {
    final revertableFiles = _getRevertableFiles();
    
    if (revertableFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('revertNoFilesMessage'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Показываем диалог подтверждения
    final confirmed = await _showRevertConfirmationDialog(revertableFiles);
    if (!confirmed) return;

    setState(() {
      _isCommitting = true; // Используем тот же индикатор загрузки
    });

    try {
      final filePaths = revertableFiles.map((file) => file.path).toList();
      
      final revertResult = await SvnService.revert(
        filePaths, 
        workingDirectory: widget.repository.localPath,
      );

      if (revertResult.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reverted files: {count}'.tr().replaceAll('{count}', '${filePaths.length}')),
            backgroundColor: Colors.green,
          ),
        );
        
        // Обновляем список файлов
        await _loadData();
      } else {
        ErrorHelper.showSvnError(context, revertResult, 'Revert failed'.tr());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reverting files: {error}'.tr().replaceAll('{error}', e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCommitting = false;
      });
    }
  }

  Future<bool> _showRevertConfirmationDialog(List<SvnFile> files) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Revert'.tr()),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to revert {count} files?'.tr().replaceAll('{count}', '${files.length}')),
              const SizedBox(height: 12),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getStatusColor(file.status),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                file.status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              file.path,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'All changes will be lost!'.tr(),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Revert'.tr()),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'M':  // Modified - измененные файлы
        return Colors.blue;
      case 'A':  // Added - новые файлы
        return Colors.green;
      case 'D':  // Deleted - удаленные файлы
        return Colors.red;
      case '?':  // Untracked - неотслеживаемые файлы
        return Colors.grey;
      case '!':  // Missing - отсутствующие файлы
        return Colors.deepOrange;
      case 'C':  // Conflicted - конфликтующие файлы
        return Colors.purple;
      case 'R':  // Replaced - замененные файлы
        return Colors.teal;
      case 'I':  // Ignored - игнорируемые файлы
        return Colors.brown;
      case 'X':  // External - внешние файлы
        return Colors.indigo;
      case '~':  // Obstructed - заблокированные файлы
        return Colors.amber;
      default:
        return Colors.black87;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'M':  // Modified - измененные файлы
        return const Color(0xFF1976D2); // blue.shade700
      case 'A':  // Added - новые файлы
        return const Color(0xFF388E3C); // green.shade700
      case 'D':  // Deleted - удаленные файлы
        return const Color(0xFFD32F2F); // red.shade700
      case '?':  // Untracked - неотслеживаемые файлы
        return const Color(0xFF616161); // grey.shade700
      case '!':  // Missing - отсутствующие файлы
        return const Color(0xFFE64A19); // deepOrange.shade700
      case 'C':  // Conflicted - конфликтующие файлы
        return const Color(0xFF7B1FA2); // purple.shade700
      case 'R':  // Replaced - замененные файлы
        return const Color(0xFF00796B); // teal.shade700
      case 'I':  // Ignored - игнорируемые файлы
        return const Color(0xFF5D4037); // brown.shade700
      case 'X':  // External - внешние файлы
        return const Color(0xFF303F9F); // indigo.shade700
      case '~':  // Obstructed - заблокированные файлы
        return const Color(0xFFFF8F00); // amber.shade700
      default:
        return const Color(0xFF212121); // black87
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'M':
        return 'Modified'.tr();
      case 'A':
        return 'Added'.tr();
      case 'D':
        return 'Deleted'.tr();
      case '?':
        return 'Untracked'.tr();
      case '!':
        return 'Missing'.tr();
      case 'C':
        return 'Conflicted'.tr();
      case 'R':
        return 'Replaced'.tr();
      case 'I':
        return 'Ignored'.tr();
      case 'X':
        return 'External'.tr();
      case '~':
        return 'Obstructed'.tr();
      default:
        return 'Unknown'.tr();
    }
  }

  Widget _buildStatusLegendItem(String status, String description, Color color) {
    final totalCount = _getFilesCountByStatus(status);
    final selectedCount = _getSelectedFilesCountByStatus(status);
    final isStatusSelected = _selectedStatuses.contains(status);
    
    if (totalCount == 0) return const SizedBox.shrink();
    
    return GestureDetector(
      onTap: () {
        _toggleFilesByStatus(status);
        _toggleStatusSelection(status);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isStatusSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isStatusSelected 
              ? Border.all(color: color, width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$status: $description',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color == Colors.blue ? const Color(0xFF1976D2) :
                      color == Colors.green ? const Color(0xFF388E3C) :
                      color == Colors.red ? const Color(0xFFD32F2F) :
                      color == Colors.grey ? const Color(0xFF616161) :
                      color == Colors.deepOrange ? const Color(0xFFE64A19) :
                      color == Colors.purple ? const Color(0xFF7B1FA2) :
                      color == Colors.teal ? const Color(0xFF00796B) :
                      color == Colors.brown ? const Color(0xFF5D4037) :
                      color == Colors.indigo ? const Color(0xFF303F9F) :
                      color == Colors.amber ? const Color(0xFFFF8F00) :
                      const Color(0xFF212121),
                fontSize: 11,
                fontWeight: isStatusSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '($selectedCount/$totalCount)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusLegend() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('File Status Color Scheme'.tr()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailedStatusItem('M', 'Modified', 'Modified'.tr(), Colors.blue, 'File was modified'.tr()),
              _buildDetailedStatusItem('A', 'Added', 'Added'.tr(), Colors.green, 'New file added to repository'.tr()),
              _buildDetailedStatusItem('D', 'Deleted', 'Deleted'.tr(), Colors.red, 'File deleted from repository'.tr()),
              _buildDetailedStatusItem('?', 'Untracked', 'Untracked'.tr(), Colors.grey, 'File not tracked by SVN'.tr()),
              _buildDetailedStatusItem('!', 'Missing', 'Missing'.tr(), Colors.deepOrange, 'File tracked but missing'.tr()),
              _buildDetailedStatusItem('C', 'Conflicted', 'Conflicted'.tr(), Colors.purple, 'File has merge conflicts'.tr()),
              _buildDetailedStatusItem('R', 'Replaced', 'Replaced'.tr(), Colors.teal, 'File was replaced'.tr()),
              _buildDetailedStatusItem('I', 'Ignored', 'Ignored'.tr(), Colors.brown, 'File ignored by SVN'.tr()),
              _buildDetailedStatusItem('X', 'External', 'External'.tr(), Colors.indigo, 'External definition'.tr()),
              _buildDetailedStatusItem('~', 'Obstructed', 'Obstructed'.tr(), Colors.amber, 'Resource obstructed'.tr()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStatusItem(String status, String statusEn, String statusRu, Color color, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 12, top: 2),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$statusEn ($status)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color == Colors.blue ? const Color(0xFF1976D2) :
                              color == Colors.green ? const Color(0xFF388E3C) :
                              color == Colors.red ? const Color(0xFFD32F2F) :
                              color == Colors.grey ? const Color(0xFF616161) :
                              color == Colors.deepOrange ? const Color(0xFFE64A19) :
                              color == Colors.purple ? const Color(0xFF7B1FA2) :
                              color == Colors.teal ? const Color(0xFF00796B) :
                              color == Colors.brown ? const Color(0xFF5D4037) :
                              color == Colors.indigo ? const Color(0xFF303F9F) :
                              color == Colors.amber ? const Color(0xFFFF8F00) :
                              const Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusRu,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color == Colors.blue ? const Color(0xFF1976D2) :
                              color == Colors.green ? const Color(0xFF388E3C) :
                              color == Colors.red ? const Color(0xFFD32F2F) :
                              color == Colors.grey ? const Color(0xFF616161) :
                              color == Colors.deepOrange ? const Color(0xFFE64A19) :
                              color == Colors.purple ? const Color(0xFF7B1FA2) :
                              color == Colors.teal ? const Color(0xFF00796B) :
                              color == Colors.brown ? const Color(0xFF5D4037) :
                              color == Colors.indigo ? const Color(0xFF303F9F) :
                              color == Colors.amber ? const Color(0xFFFF8F00) :
                              const Color(0xFF212121),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Commit'.tr()),
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
                          'Commit to:'.tr(),
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
                    'Commit message:'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _messageController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Enter description of changes...'.tr(),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _showCommitHistoryDialog,
                        icon: const Icon(Icons.history),
                        tooltip: 'Commit History'.tr(),
                      ),
                      IconButton(
                        onPressed: _loadRecentCommitMessages,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh History'.tr(),
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
                      'Templates:'.tr(),
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
                  
                  // Легенда статусов
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _buildStatusLegendItem('M', 'Modified'.tr(), Colors.blue),
                        _buildStatusLegendItem('A', 'Added'.tr(), Colors.green),
                        _buildStatusLegendItem('D', 'Deleted'.tr(), Colors.red),
                        _buildStatusLegendItem('?', 'Untracked'.tr(), Colors.grey),
                        _buildStatusLegendItem('!', 'Missing'.tr(), Colors.deepOrange),
                        _buildStatusLegendItem('C', 'Conflicted'.tr(), Colors.purple),
                        _buildStatusLegendItem('R', 'Replaced'.tr(), Colors.teal),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Кнопки действий с файлами
                  Row(
                    children: [
                      // Кнопки выбора слева
                      TextButton(
                        onPressed: _selectAllFiles,
                        child: Text('Select All'.tr()),
                      ),
                      TextButton(
                        onPressed: _deselectAllFiles,
                        child: Text('Deselect All'.tr()),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Поле фильтрации в центре
                      Icon(Icons.filter_list, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: _fileFilter,
                          decoration: InputDecoration(
                            hintText: 'Filter files (e.g., *.dart, src/*)'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _fileFilter = value;
                            });
                          },
                        ),
                      ),
                      if (_fileFilter.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _fileFilter = '';
                            });
                          },
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear filter'.tr(),
                          visualDensity: VisualDensity.compact,
                        ),
                      
                      const Spacer(),
                      
                      // Счетчики и информация справа
                      Text(
                        'Selected: {count}'.tr().replaceAll('{count}', _files.where((f) => f.isSelected).length.toString()),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (_fileFilter.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Filtered: {count}'.tr().replaceAll('{count}', _filteredFiles.length.toString()),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      IconButton(
                        onPressed: _showStatusLegend,
                        icon: const Icon(Icons.info_outline),
                        tooltip: 'File Status Color Scheme'.tr(),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Список файлов
                  Expanded(
                    child: _filteredFiles.isEmpty
                        ? Center(
                            child: Text(
                              _fileFilter.isEmpty ? 'No files'.tr() : 'No files match filter'.tr(),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredFiles.length,
                            itemBuilder: (context, index) {
                              final file = _filteredFiles[index];
                              return GestureDetector(
                                  onTap: () {
                                    // Single tap - toggle file selection
                                    _toggleFileSelection(index);
                                  },
                                  onLongPressStart: (details) {
                                    // Long press - show context menu at tap position
                                    _showFileContextMenu(file, index, details.globalPosition);
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
                                          child: Tooltip(
                                            message: '${_getStatusDescription(file.status)} (${file.status})',
                                            child: ClickableText(
                                              text: file.path,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: _getStatusTextColor(file.status),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              enableLinkDetection: false, // Disable default link behavior
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                            },
                          ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Кнопка восстановления файлов
                  if (_hasRevertableFiles())
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.restore, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Files found for revert: {count}'.tr().replaceAll('{count}', _getRevertableFiles().length.toString()),
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isCommitting ? null : _revertSelectedFiles,
                            icon: const Icon(Icons.restore_from_trash),
                            label: Text('Revert'.tr()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Кнопки действий
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isCommitting ? null : () => Navigator.pop(context),
                          child: Text('Cancel'.tr()),
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
                              : Text('Commit'.tr()),
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
            content: Text('Error opening diff: {error}'.tr().replaceAll('{error}', e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showFileContextMenu(SvnFile file, int index, Offset position) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 16),
              SizedBox(width: 8),
              Text('View file'.tr()),
            ],
          ),
        ),
        if (_isFileModified(file.status))
          PopupMenuItem(
            value: 'diff',
            child: Row(
              children: [
                Icon(Icons.compare, size: 16),
                SizedBox(width: 8),
                Text('View diff'.tr()),
              ],
            ),
          ),
      ],
    );

    if (result != null) {
      _handleFileAction(result, file);
    }
  }

  void _handleFileAction(String action, SvnFile file) {
    switch (action) {
      case 'view':
        _viewFile(file);
        break;
      case 'diff':
        _viewDiff(file);
        break;
    }
  }

  Future<void> _viewFile(SvnFile file) async {
    try {
      // Get user settings to check for external file viewer
      final userSettings = await StorageService.getUserSettings();
      final externalFileViewer = userSettings.externalFileViewer;
      
      // Get the relative path for SVN operations
      final relativePath = file.path.startsWith('/') 
          ? file.path.substring(widget.repository.localPath.length + 1) 
          : file.path;
      
      if (externalFileViewer.isNotEmpty) {
        // Use external file viewer
        await _openExternalFileViewer(externalFileViewer, relativePath);
      } else {
        // Use built-in file viewer
        final result = await SvnService.cat(widget.repository.localPath, relativePath);
        
        if (result.success) {
          _showContentDialog(
            'View file'.tr() + ': ${file.path}',
            result.output ?? '',
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error viewing file: ${result.errorMessage}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error viewing file: $e')),
      );
    }
  }

  Future<void> _openExternalFileViewer(String viewerPath, String filePath) async {
    try {
      // Create temporary directory
      final tempDir = '/tmp/vibesvn_view_${DateTime.now().millisecondsSinceEpoch}';
      await Process.run('mkdir', ['-p', tempDir]);
      
      // Create simple file name (avoid subdirectories in temp)
      final fileName = filePath.split('/').last;
      final tempFile = '$tempDir/$fileName';
      
      // Get file content
      final result = await SvnService.cat(widget.repository.localPath, filePath);
      
      if (result.success && result.output != null) {
        // Write file content
        final fileObj = File(tempFile);
        await fileObj.writeAsString(result.output!);
        
        // Verify file exists
        if (!await File(tempFile).exists()) {
          throw Exception('Failed to create temp file: $tempFile');
        }
        
        // Launch external file viewer
        await Process.run(viewerPath, [tempFile]);
        
        // Schedule cleanup after 5 minutes
        Future.delayed(const Duration(minutes: 5), () async {
          await Process.run('rm', ['-rf', tempDir]);
        });
      } else {
        throw Exception('Failed to get file content: ${result.errorMessage}');
      }
    } catch (e) {
      throw Exception('Failed to open external file viewer: $e');
    }
  }

  Future<void> _viewDiff(SvnFile file) async {
    try {
      // Get user settings to check for external diff tool
      final userSettings = await StorageService.getUserSettings();
      final externalDiffTool = userSettings.externalDiffTool;
      
      // Get the relative path for SVN operations
      final relativePath = file.path.startsWith('/') 
          ? file.path.substring(widget.repository.localPath.length + 1) 
          : file.path;
      
      if (externalDiffTool.isNotEmpty) {
        // Use external diff tool
        await _openExternalDiffTool(externalDiffTool, relativePath);
      } else {
        // Use built-in diff viewer
        final diffResult = await SvnService.getDiff(widget.repository.localPath, filePath: relativePath);
        
        if (diffResult.success) {
          _showContentDialog(
            'View diff'.tr() + ': ${file.path}',
            diffResult.output ?? '',
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error viewing diff: ${diffResult.errorMessage}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error viewing diff: $e')),
      );
    }
  }

  void _showContentDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: SingleChildScrollView(
            child: SelectableText(
              content.isEmpty ? 'No content available' : content,
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'.tr()),
          ),
          if (content.isNotEmpty) ...[
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: content));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Content copied to clipboard')),
                );
              },
              child: Text('Copy'.tr()),
            ),
          ],
        ],
      ),
    );
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
              content: Text('Failed to get changes for file: {filePath}'.tr().replaceAll('{filePath}', filePath)),
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
            content: Text('Error opening diff: {error}'.tr().replaceAll('{error}', e.toString())),
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
                      'Changes in file: {filePath}'.tr().replaceAll('{filePath}', filePath),
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
                    child: Text('Close'.tr()),
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
