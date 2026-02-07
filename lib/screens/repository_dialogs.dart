import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import '../models/repository.dart';
import '../models/user_settings.dart';
import '../models/svn_result.dart';
import '../services/storage_service.dart';
import '../services/svn_service.dart';
import '../helpers/error_helper.dart';

class CreateRepositoryDialog extends StatefulWidget {
  final VoidCallback onRepositoryCreated;

  const CreateRepositoryDialog({
    super.key,
    required this.onRepositoryCreated,
  });

  @override
  State<CreateRepositoryDialog> createState() => _CreateRepositoryDialogState();
}

class _CreateRepositoryDialogState extends State<CreateRepositoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedPath = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    final settings = await StorageService.getUserSettings();
    setState(() {
      _usernameController.text = settings.username;
      _passwordController.text = settings.password;
      _selectedPath = settings.defaultClonePath;
    });
  }

  Future<void> _selectPath() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        _selectedPath = result;
      });
    }
  }

  Future<void> _createRepository() async {
    if (!_formKey.currentState!.validate() || _selectedPath.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Сохраняем настройки пользователя
      final currentSettings = await StorageService.getUserSettings();
      final updatedSettings = currentSettings.copyWith(
        username: _usernameController.text,
        password: _passwordController.text,
        defaultClonePath: _selectedPath,
      );
      await StorageService.saveUserSettings(updatedSettings);

      // Создаем репозиторий
      var repositoryName = _urlController.text.split('/').last;
      if (repositoryName.isEmpty) {
        repositoryName = 'repository_${DateTime.now().millisecondsSinceEpoch}';
      }

      final repository = SvnRepository(
        id: _generateId(),
        name: repositoryName,
        localPath: _selectedPath,
        remoteUrl: _urlController.text,
        createdAt: DateTime.now(),
        lastAccessed: DateTime.now(),
      );

      // Выполняем checkout
      final checkoutResult = await SvnService.checkoutRepository(
        url: _urlController.text,
        targetPath: _selectedPath,
        username: _usernameController.text,
        password: _passwordController.text,
      );

      if (checkoutResult.success) {
        await StorageService.addRepository(repository);
        widget.onRepositoryCreated();
        Navigator.pop(context);
      } else {
        ErrorHelper.showSvnError(context, checkoutResult, 'Error cloning repository'.tr());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create Repository'.tr()),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'Repository URL'.tr(),
                  hintText: 'https://svn.example.com/repository'.tr(),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter repository URL'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username'.tr(),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter username'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password'.tr(),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter password'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedPath.isEmpty ? 'Select folder'.tr() : _selectedPath,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _selectPath,
                    child: Text('Browse...'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('Cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createRepository,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Create'.tr()),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class OpenRepositoryDialog extends StatefulWidget {
  final VoidCallback onRepositoryOpened;

  const OpenRepositoryDialog({
    super.key,
    required this.onRepositoryOpened,
  });

  @override
  State<OpenRepositoryDialog> createState() => _OpenRepositoryDialogState();
}

class _OpenRepositoryDialogState extends State<OpenRepositoryDialog> {
  String _selectedPath = '';
  bool _isLoading = false;
  bool _isValidRepository = false;

  Future<void> _selectPath() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        _selectedPath = result;
        _isValidRepository = false;
      });
      await _validateRepository();
    }
  }

  Future<void> _validateRepository() async {
    if (_selectedPath.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('DEBUG: Validating repository at path: $_selectedPath');
      
      // First check if SVN is available
      final svnAvailable = await SvnService.isSvnInstalled();
      if (!svnAvailable) {
        print('DEBUG: SVN is not available');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('SVN is not installed or unavailable'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isValidRepository = false;
        });
        return;
      }
      
      // Check if directory exists
      final dir = Directory(_selectedPath);
      if (!await dir.exists()) {
        print('DEBUG: Directory does not exist: $_selectedPath');
        setState(() {
          _isValidRepository = false;
        });
        return;
      }
      
      // List contents to see if .svn exists
      try {
        final contents = await dir.list().toList();
        final hasSvn = contents.any((entity) => entity.path.endsWith('.svn'));
        print('DEBUG: Directory contents count: ${contents.length}');
        print('DEBUG: Has .svn directory: $hasSvn');
        
        for (final entity in contents.take(10)) {
          print('DEBUG: Found: ${entity.path}');
        }
      } catch (e) {
        print('DEBUG: Error listing directory contents: $e');
      }
      
      final isValid = await SvnService.isWorkingCopy(_selectedPath);
      print('DEBUG: Is working copy: $isValid');
      
      final url = isValid ? await SvnService.getRepositoryUrl(_selectedPath) : null;
      print('DEBUG: Repository URL: $url');
      
      setState(() {
        _isValidRepository = isValid && url != null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isValidRepository 
                ? 'Valid SVN repository'.tr() 
                : 'Not an SVN working copy'.tr()),
            backgroundColor: _isValidRepository ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Error validating repository: $e');
      setState(() {
        _isValidRepository = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Repository validation error: {error}'.tr().replaceAll('{error}', e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openRepository() async {
    if (!_isValidRepository) return;

    try {
      final url = await SvnService.getRepositoryUrl(_selectedPath);
      if (url == null) return;

      final repositoryName = _selectedPath.split('/').last;
      final repository = SvnRepository(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: repositoryName.isEmpty ? 'Local Repository' : repositoryName,
        localPath: _selectedPath,
        remoteUrl: url,
        createdAt: DateTime.now(),
        lastAccessed: DateTime.now(),
      );

      await StorageService.addRepository(repository);
      widget.onRepositoryOpened();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Open Local Repository'.tr()),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedPath.isEmpty ? 'Select folder with SVN repository'.tr() : _selectedPath,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: _selectPath,
                  child: Text('Browse...'.tr()),
                ),
              ],
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )
            else if (_selectedPath.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Icon(
                      _isValidRepository ? Icons.check_circle : Icons.error,
                      color: _isValidRepository ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isValidRepository
                          ? 'Valid SVN repository'.tr()
                          : 'Not an SVN working copy'.tr(),
                      style: TextStyle(
                        color: _isValidRepository ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _isValidRepository ? _openRepository : null,
          child: Text('Open'.tr()),
        ),
      ],
    );
  }
}

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _defaultPathController = TextEditingController();
  bool _autoSaveCredentials = true;
  int _commitHistoryLimit = 50;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await StorageService.getUserSettings();
    setState(() {
      _usernameController.text = settings.username;
      _passwordController.text = settings.password;
      _defaultPathController.text = settings.defaultClonePath;
      _autoSaveCredentials = settings.autoSaveCredentials;
      _commitHistoryLimit = settings.commitMessageHistoryLimit;
    });
  }

  Future<void> _saveSettings() async {
    final settings = UserSettings(
      username: _usernameController.text,
      password: _passwordController.text,
      defaultClonePath: _defaultPathController.text,
      autoSaveCredentials: _autoSaveCredentials,
      commitMessageHistoryLimit: _commitHistoryLimit,
    );

    await StorageService.saveUserSettings(settings);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('User Settings'.tr()),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Default Username'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Default Password'.tr(),
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _defaultPathController,
              decoration: InputDecoration(
                labelText: 'Default clone folder'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _autoSaveCredentials,
                  onChanged: (value) {
                    setState(() {
                      _autoSaveCredentials = value ?? true;
                    });
                  },
                ),
                Text('Save credentials'.tr()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Commit history limit: '.tr()),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    initialValue: _commitHistoryLimit.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _commitHistoryLimit = int.tryParse(value) ?? 50;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          child: Text('Save'.tr()),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _defaultPathController.dispose();
    super.dispose();
  }
}
