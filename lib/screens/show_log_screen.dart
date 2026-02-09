import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import '../models/svn_commit.dart';
import '../models/repository.dart';
import '../services/svn_service.dart';
import '../services/storage_service.dart';

class ShowLogScreen extends StatefulWidget {
  final SvnRepository repository;

  const ShowLogScreen({
    super.key,
    required this.repository,
  });

  @override
  State<ShowLogScreen> createState() => _ShowLogScreenState();
}

class _ShowLogScreenState extends State<ShowLogScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  
  List<SvnCommit> _commits = [];
  List<SvnCommit> _filteredCommits = [];
  SvnCommit? _selectedCommit;
  List<String> _selectedCommitFiles = [];
  
  SortColumn _sortColumn = SortColumn.revision;
  SortDirection _sortDirection = SortDirection.descending;
  
  bool _isLoading = false;
  bool _showFilesTable = false;

  @override
  void initState() {
    super.initState();
    _loadCommits();
    _searchController.addListener(_applyFilters);
    _startDateController.addListener(_applyFilters);
    _endDateController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _loadCommits() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final commits = await SvnService.getDetailedLog(
        widget.repository.localPath,
        limit: 500,
      );

      setState(() {
        _commits = commits;
        _filteredCommits = List.from(_commits);
        _sortCommits();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load commits: $e'.tr())),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredCommits = _commits.where((commit) {
        // Search filter
        final searchQuery = _searchController.text.toLowerCase();
        if (searchQuery.isNotEmpty) {
          final matchesMessage = commit.message.toLowerCase().contains(searchQuery);
          final matchesPaths = commit.paths.any((path) => 
              path.toLowerCase().contains(searchQuery));
          if (!matchesMessage && !matchesPaths) return false;
        }

        // Date filters
        if (_startDateController.text.isNotEmpty) {
          final startDate = _parseDate(_startDateController.text);
          if (startDate != null && commit.date.isBefore(startDate)) {
            return false;
          }
        }

        if (_endDateController.text.isNotEmpty) {
          final endDate = _parseDate(_endDateController.text);
          if (endDate != null) {
            final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
            if (commit.date.isAfter(endOfDay)) return false;
          }
        }

        return true;
      }).toList();
      
      _sortCommits();
    });
  }

  void _sortCommits() {
    setState(() {
      switch (_sortColumn) {
        case SortColumn.revision:
          _filteredCommits.sort((a, b) {
            final aRev = int.tryParse(a.revision) ?? 0;
            final bRev = int.tryParse(b.revision) ?? 0;
            return _sortDirection == SortDirection.ascending 
                ? aRev.compareTo(bRev) 
                : bRev.compareTo(aRev);
          });
          break;
        case SortColumn.author:
          _filteredCommits.sort((a, b) {
            return _sortDirection == SortDirection.ascending 
                ? a.author.compareTo(b.author) 
                : b.author.compareTo(a.author);
          });
          break;
        case SortColumn.date:
          _filteredCommits.sort((a, b) {
            return _sortDirection == SortDirection.ascending 
                ? a.date.compareTo(b.date) 
                : b.date.compareTo(a.date);
          });
          break;
        case SortColumn.message:
          _filteredCommits.sort((a, b) {
            return _sortDirection == SortDirection.ascending 
                ? a.message.compareTo(b.message) 
                : b.message.compareTo(a.message);
          });
          break;
      }
    });
  }

  void _onSortChanged(SortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortDirection = _sortDirection == SortDirection.ascending 
            ? SortDirection.descending 
            : SortDirection.ascending;
      } else {
        _sortColumn = column;
        _sortDirection = SortDirection.ascending;
      }
      _sortCommits();
    });
  }

  void _onCommitSelected(SvnCommit commit) {
    setState(() {
      _selectedCommit = commit;
      _selectedCommitFiles = commit.paths;
      _showFilesTable = true;
    });
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      controller.text = '${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}';
    }
  }

  DateTime? _parseDate(String dateString) {
    // Try DD.MM.YYYY format first
    final ddMmYyyyRegex = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$');
    final match = ddMmYyyyRegex.firstMatch(dateString);
    
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      
      try {
        return DateTime(year, month, day);
      } catch (e) {
        return null;
      }
    }
    
    // Fallback to ISO format YYYY-MM-DD
    return DateTime.tryParse(dateString);
  }

  void _showFileContextMenu(String filePath, Offset position) async {
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
        PopupMenuItem(
          value: 'blame',
          child: Row(
            children: [
              Icon(Icons.person_search, size: 16),
              SizedBox(width: 8),
              Text('Blame'.tr()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'copy_path',
          child: Row(
            children: [
              Icon(Icons.copy, size: 16),
              SizedBox(width: 8),
              Text('Copy path'.tr()),
            ],
          ),
        ),
      ],
    );

    if (result != null) {
      _handleFileAction(result, filePath);
    }
  }

  void _handleFileAction(String action, String filePath) {
    switch (action) {
      case 'view':
        _viewFile(filePath);
        break;
      case 'diff':
        _viewDiff(filePath);
        break;
      case 'blame':
        _viewBlame(filePath);
        break;
      case 'copy_path':
        Clipboard.setData(ClipboardData(text: filePath));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Path copied to clipboard'.tr())),
        );
        break;
    }
  }

  Future<void> _viewFile(String filePath) async {
    try {
      // Get user settings to check for external file viewer
      final userSettings = await StorageService.getUserSettings();
      final externalFileViewer = userSettings.externalFileViewer;
      
      String? revision;
      
      // If a commit is selected, show file from that revision
      if (_selectedCommit != null) {
        revision = _selectedCommit!.revision;
      }
      
      // Get the relative path for SVN operations
      final relativePath = filePath.startsWith('/') 
          ? filePath.substring(1)  // Remove leading slash
          : filePath;
      
      if (externalFileViewer.isNotEmpty && revision != null) {
        // Use external file viewer for specific revision
        await _openExternalFileViewer(externalFileViewer, relativePath, revision!);
      } else {
        // Use built-in file viewer
        final result = await SvnService.cat(widget.repository.localPath, relativePath, revision: revision);
        
        if (result.success) {
          String title = 'View file'.tr() + ': $filePath';
          if (revision != null) {
            title += ' (r$revision)';
          }
          
          _showContentDialog(title, result.output ?? '');
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

  Future<void> _openExternalFileViewer(String viewerPath, String filePath, String revision) async {
    try {
      // Create temporary directory
      final tempDir = '/tmp/vibesvn_view_${DateTime.now().millisecondsSinceEpoch}';
      await Process.run('mkdir', ['-p', tempDir]);
      
      // Create simple file name (avoid subdirectories in temp)
      final fileName = filePath.split('/').last;
      final tempFile = '$tempDir/$fileName';
      
      // Get file content from specific revision
      final result = await SvnService.cat(widget.repository.localPath, filePath, revision: revision);
      
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

  Future<void> _viewDiff(String filePath) async {
    try {
      // Get user settings to check for external diff tool
      final userSettings = await StorageService.getUserSettings();
      final externalDiffTool = userSettings.externalDiffTool;
      
      if (externalDiffTool.isNotEmpty && _selectedCommit != null) {
        // Use external diff tool for revision comparison
        await _openExternalDiffTool(externalDiffTool, filePath);
      } else {
        // Use built-in diff viewer
        await _openBuiltInDiffViewer(filePath);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error viewing diff: $e')),
      );
    }
  }

  Future<void> _openExternalDiffTool(String diffToolPath, String filePath) async {
    try {
      final repositoryPath = widget.repository.localPath;
      
      // Get revision range for comparison
      String? revisionStart;
      String? revisionEnd;
      
      final currentRevision = _selectedCommit!.revision;
      final currentIndex = _filteredCommits.indexWhere((c) => c.revision == currentRevision);
      
      if (currentIndex >= 0 && currentIndex < _filteredCommits.length - 1) {
        // Compare with previous revision
        revisionStart = _filteredCommits[currentIndex + 1].revision;
        revisionEnd = currentRevision;
      } else {
        // If no previous revision, compare with current (show changes in this commit)
        revisionStart = currentRevision;
        revisionEnd = null;
      }
      
      // Get the relative path for SVN operations
      final relativePath = filePath.startsWith('/') 
          ? filePath.substring(1)  // Remove leading slash
          : filePath;
      
      // Create temporary directory
      final tempDir = '/tmp/vibesvn_diff_${DateTime.now().millisecondsSinceEpoch}';
      await Process.run('mkdir', ['-p', tempDir]);
      
      // Create simple file names (avoid subdirectories in temp)
      final fileName = relativePath.split('/').last;
      final originalFile = '$tempDir/original_$fileName';
      final modifiedFile = '$tempDir/modified_$fileName';
      
      // Get original file content from previous revision
      String? originalContent;
      if (revisionStart != null && revisionEnd != null) {
        final originalResult = await SvnService.cat(repositoryPath, relativePath, revision: revisionStart);
        if (originalResult.success && originalResult.output != null) {
          originalContent = originalResult.output;
        }
      }
      
      // Write original file content
      if (originalContent != null) {
        final originalFileObj = File(originalFile);
        await originalFileObj.writeAsString(originalContent);
      }
      
      // Get modified file content from current revision
      String? modifiedContent;
      if (revisionEnd != null) {
        final modifiedResult = await SvnService.cat(repositoryPath, relativePath, revision: revisionEnd);
        if (modifiedResult.success && modifiedResult.output != null) {
          modifiedContent = modifiedResult.output;
        }
      }
      
      // Write modified file content
      if (modifiedContent != null) {
        final modifiedFileObj = File(modifiedFile);
        await modifiedFileObj.writeAsString(modifiedContent);
      }
      
      // Verify files exist
      if (originalContent != null && !await File(originalFile).exists()) {
        throw Exception('Failed to create original temp file: $originalFile');
      }
      if (modifiedContent != null && !await File(modifiedFile).exists()) {
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
      await Process.run(diffToolPath, args);
      
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
    } catch (e) {
      throw Exception('Failed to open external diff tool: $e');
    }
  }

  Future<void> _openBuiltInDiffViewer(String filePath) async {
    try {
      String? revisionStart;
      String? revisionEnd;
      
      if (_selectedCommit != null) {
        // Get previous revision for comparison
        final currentRevision = _selectedCommit!.revision;
        final currentIndex = _filteredCommits.indexWhere((c) => c.revision == currentRevision);
        
        if (currentIndex >= 0 && currentIndex < _filteredCommits.length - 1) {
          // Compare with previous revision
          revisionStart = _filteredCommits[currentIndex + 1].revision;
          revisionEnd = currentRevision;
        } else {
          // If no previous revision, compare with current (show changes in this commit)
          revisionStart = currentRevision;
          revisionEnd = null;
        }
      }
      
      final result = await SvnService.getDiff(
        widget.repository.localPath, 
        filePath: filePath,
        revisionStart: revisionStart,
        revisionEnd: revisionEnd,
      );
      
      if (result.success) {
        String title = 'View diff'.tr() + ': $filePath';
        if (revisionStart != null && revisionEnd != null) {
          title += ' (r$revisionStart:r$revisionEnd)';
        } else if (revisionStart != null) {
          title += ' (r$revisionStart)';
        }
        
        _showContentDialog(title, result.output ?? '');
      } else {
        throw Exception(result.errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to open built-in diff viewer: $e');
    }
  }

  Future<void> _viewBlame(String filePath) async {
    try {
      // Get user settings to check for external file viewer
      final userSettings = await StorageService.getUserSettings();
      final externalFileViewer = userSettings.externalFileViewer;
      
      // Get the relative path for SVN operations
      final relativePath = filePath.startsWith('/') 
          ? filePath.substring(1)  // Remove leading slash
          : filePath;
      
      if (externalFileViewer.isNotEmpty) {
        // Use external file viewer for blame
        await _openExternalBlameViewer(externalFileViewer, relativePath, filePath);
      } else {
        // Use built-in blame viewer
        final args = ['blame', relativePath];
        final result = await Process.run('svn', args, workingDirectory: widget.repository.localPath);
        
        if (result.exitCode == 0) {
          _showContentDialog(
            'Blame'.tr() + ': $filePath',
            result.stdout.toString(),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error viewing blame: ${result.stderr}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error viewing blame: $e')),
      );
    }
  }

  Future<void> _openExternalBlameViewer(String viewerPath, String filePath, String originalFilePath) async {
    try {
      // Create temporary directory
      final tempDir = '/tmp/vibesvn_blame_${DateTime.now().millisecondsSinceEpoch}';
      await Process.run('mkdir', ['-p', tempDir]);
      
      // Create blame file name
      final fileName = '${filePath.split('/').last}_blame.txt';
      final tempFile = '$tempDir/$fileName';
      
      // Get blame output
      final args = ['blame', filePath];
      final result = await Process.run('svn', args, workingDirectory: widget.repository.localPath);
      
      if (result.exitCode == 0) {
        // Write blame output to temp file
        final fileObj = File(tempFile);
        await fileObj.writeAsString(result.stdout);
        
        // Verify file exists
        if (!await File(tempFile).exists()) {
          throw Exception('Failed to create temp blame file: $tempFile');
        }
        
        // Launch external file viewer
        await Process.run(viewerPath, [tempFile]);
        
        // Schedule cleanup after 5 minutes
        Future.delayed(const Duration(minutes: 5), () async {
          await Process.run('rm', ['-rf', tempDir]);
        });
      } else {
        throw Exception('Failed to get blame output: ${result.stderr}');
      }
    } catch (e) {
      throw Exception('Failed to open external blame viewer: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Commit Log'.tr() + ' - ${widget.repository.name}'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCommits,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter controls
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Search field
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by message or file paths'.tr(),
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                
                // Start Date
                Expanded(
                  child: TextField(
                    controller: _startDateController,
                    decoration: InputDecoration(
                      labelText: 'Start Date'.tr(),
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_month),
                        onPressed: () => _selectDate(_startDateController),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                
                // End Date
                Expanded(
                  child: TextField(
                    controller: _endDateController,
                    decoration: InputDecoration(
                      labelText: 'End Date'.tr(),
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_month),
                        onPressed: () => _selectDate(_endDateController),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main content
          Expanded(
            child: Row(
              children: [
                // Commits table
                Expanded(
                  flex: 3,
                  child: Card(
                    margin: EdgeInsets.all(8),
                    child: Column(
                      children: [
                        // Table header
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: GestureDetector(
                                  onTap: () => _onSortChanged(SortColumn.revision),
                                  child: Row(
                                    children: [
                                      Text('Revision'.tr(), style: TextStyle(fontWeight: FontWeight.bold)),
                                      if (_sortColumn == SortColumn.revision)
                                        Icon(_sortDirection == SortDirection.ascending 
                                            ? Icons.arrow_upward 
                                            : Icons.arrow_downward, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: GestureDetector(
                                  onTap: () => _onSortChanged(SortColumn.author),
                                  child: Row(
                                    children: [
                                      Text('Author'.tr(), style: TextStyle(fontWeight: FontWeight.bold)),
                                      if (_sortColumn == SortColumn.author)
                                        Icon(_sortDirection == SortDirection.ascending 
                                            ? Icons.arrow_upward 
                                            : Icons.arrow_downward, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: GestureDetector(
                                  onTap: () => _onSortChanged(SortColumn.date),
                                  child: Row(
                                    children: [
                                      Text('Date'.tr(), style: TextStyle(fontWeight: FontWeight.bold)),
                                      if (_sortColumn == SortColumn.date)
                                        Icon(_sortDirection == SortDirection.ascending 
                                            ? Icons.arrow_upward 
                                            : Icons.arrow_downward, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: GestureDetector(
                                  onTap: () => _onSortChanged(SortColumn.message),
                                  child: Row(
                                    children: [
                                      Text('Message'.tr(), style: TextStyle(fontWeight: FontWeight.bold)),
                                      if (_sortColumn == SortColumn.message)
                                        Icon(_sortDirection == SortDirection.ascending 
                                            ? Icons.arrow_upward 
                                            : Icons.arrow_downward, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Table content
                        Expanded(
                          child: _isLoading
                              ? Center(child: CircularProgressIndicator())
                              : ListView.builder(
                                  itemCount: _filteredCommits.length,
                                  itemBuilder: (context, index) {
                                    final commit = _filteredCommits[index];
                                    final isSelected = _selectedCommit?.revision == commit.revision;
                                    
                                    return GestureDetector(
                                      onTap: () => _onCommitSelected(commit),
                                      child: Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isSelected 
                                              ? Theme.of(context).primaryColor.withOpacity(0.2)
                                              : index % 2 == 0 
                                                  ? Colors.transparent
                                                  : Theme.of(context).dividerColor.withOpacity(0.1),
                                          border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3))),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(flex: 1, child: Text(commit.revision)),
                                            Expanded(flex: 2, child: Text(commit.author)),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                '${commit.date.day.toString().padLeft(2, '0')}.${commit.date.month.toString().padLeft(2, '0')}.${commit.date.year} ${commit.date.hour.toString().padLeft(2, '0')}:${commit.date.minute.toString().padLeft(2, '0')}',
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                commit.message,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Right panel
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Commit message
                      if (_selectedCommit != null)
                        Card(
                          margin: EdgeInsets.all(8),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Commit Message'.tr(),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(_selectedCommit!.message),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Files table
                      if (_showFilesTable && _selectedCommitFiles.isNotEmpty)
                        Expanded(
                          child: Card(
                            margin: EdgeInsets.all(8),
                            child: Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Files'.tr() + ' (${_selectedCommitFiles.length})',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _selectedCommitFiles.length,
                                    itemBuilder: (context, index) {
                                      final filePath = _selectedCommitFiles[index];
                                      
                                      return GestureDetector(
                                        onSecondaryTapDown: (details) {
                                          _showFileContextMenu(filePath, details.globalPosition);
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: index % 2 == 0 
                                                ? Colors.transparent
                                                : Theme.of(context).dividerColor.withOpacity(0.1),
                                            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3))),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.insert_drive_file, size: 16),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  filePath,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
