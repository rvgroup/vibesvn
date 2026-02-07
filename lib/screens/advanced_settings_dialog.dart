import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/user_settings.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import '../services/ignore_service.dart';
import '../services/commit_template_service.dart';

class AdvancedSettingsDialog extends StatefulWidget {
  const AdvancedSettingsDialog({super.key});

  @override
  State<AdvancedSettingsDialog> createState() => _AdvancedSettingsDialogState();
}

class _AdvancedSettingsDialogState extends State<AdvancedSettingsDialog> {
  late UserSettings _settings;
  late ThemeService _themeService;
  
  final _defaultPathController = TextEditingController();
  final _diffToolController = TextEditingController();
  final _proxyHostController = TextEditingController();
  final _proxyPortController = TextEditingController();
  final _proxyUsernameController = TextEditingController();
  final _proxyPasswordController = TextEditingController();
  final _commitHistoryLimitController = TextEditingController();
  
  List<String> _ignoredPatterns = [];
  List<String> _commitTemplates = [];
  bool _autoUpdateRepositories = false;
  bool _autoSaveCredentials = true;
  bool _proxyEnabled = false;
  int _commitHistoryLimit = 50;
  AppTheme _selectedTheme = AppTheme.system;
  bool _obscureDefaultPassword = true;
  bool _obscureProxyPassword = true;
  
  // Store diff tool value separately to ensure it's preserved
  String _diffToolValue = '';
  
  // Predefined diff tools
  static const Map<String, String> _diffTools = {
    'Meld': '/opt/homebrew/bin/meld',
    'VS Code': '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code',
    'FileMerge': '/usr/bin/opendiff',
  };

  @override
  void initState() {
    super.initState();
    _themeService = ThemeService();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await StorageService.getUserSettings();
      print('DEBUG: Loading settings...');
      print('DEBUG: Loaded externalDiffTool: "${settings.externalDiffTool}"');
      
      if (mounted) {
        setState(() {
          _settings = settings;
          _defaultPathController.text = settings.defaultClonePath;
          _diffToolValue = settings.externalDiffTool;
          _diffToolController.text = settings.externalDiffTool;
          print('DEBUG: Set diff tool controller to: "${_diffToolController.text}"');
          print('DEBUG: Set diff tool value to: "$_diffToolValue"');
          _ignoredPatterns = List.from(settings.ignoredPatterns);
          _commitTemplates = List.from(settings.commitTemplates);
          _autoUpdateRepositories = settings.autoUpdateRepositories;
          _autoSaveCredentials = settings.autoSaveCredentials;
          _commitHistoryLimit = settings.commitMessageHistoryLimit;
          _commitHistoryLimitController.text = _commitHistoryLimit.toString();
          _selectedTheme = settings.appTheme;
          
          if (settings.proxySettings != null) {
            _proxyEnabled = settings.proxySettings!.enabled;
            _proxyHostController.text = settings.proxySettings!.host;
            _proxyPortController.text = settings.proxySettings!.port.toString();
            _proxyUsernameController.text = settings.proxySettings!.username ?? '';
            _proxyPasswordController.text = settings.proxySettings!.password ?? '';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки настроек: $e')),
        );
      }
    }
  }

  Future<void> _selectDefaultPath() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        _defaultPathController.text = result;
      });
    }
  }

  Future<void> _selectDiffTool() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите инструмент сравнения'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _diffTools.entries.map((entry) {
            return ListTile(
              title: Text(entry.key),
              subtitle: Text(entry.value),
              onTap: () => Navigator.of(context).pop(entry.value),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      setState(() {
        _diffToolController.text = result;
        _diffToolValue = result;
      });
    }
  }

  Future<void> _browseDiffTool() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['exe', 'app', 'sh', 'py', ''],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _diffToolController.text = result.files.single.path!;
        _diffToolValue = result.files.single.path!;
      });
    }
  }

  Future<void> _saveSettings() async {
    print('=== NEW SAVE SETTINGS METHOD CALLED ===');
    try {
      print('DEBUG: Saving settings...');
      print('DEBUG: Diff tool path: "${_diffToolController.text}"');
      print('DEBUG: Diff tool value: "$_diffToolValue"');
      print('DEBUG: Default path: "${_defaultPathController.text}"');
      
      // Force update the text field value
      final currentDiffToolValue = _diffToolController.text.trim();
      print('DEBUG: Final diff tool value to save: "$currentDiffToolValue"');
      
      final proxySettings = _proxyEnabled ? ProxySettings(
        enabled: _proxyEnabled,
        host: _proxyHostController.text,
        port: int.tryParse(_proxyPortController.text) ?? 8080,
        username: _proxyUsernameController.text.isEmpty ? null : _proxyUsernameController.text,
        password: _proxyPasswordController.text.isEmpty ? null : _proxyPasswordController.text,
      ) : null;

      final updatedSettings = _settings.copyWith(
        defaultClonePath: _defaultPathController.text,
        externalDiffTool: currentDiffToolValue,
        ignoredPatterns: _ignoredPatterns,
        commitTemplates: _commitTemplates,
        autoUpdateRepositories: _autoUpdateRepositories,
        autoSaveCredentials: _autoSaveCredentials,
        commitMessageHistoryLimit: int.tryParse(_commitHistoryLimitController.text) ?? 50,
        appTheme: _selectedTheme,
        proxySettings: proxySettings,
      );

      print('DEBUG: Updated settings externalDiffTool: "${updatedSettings.externalDiffTool}"');
      
      await StorageService.saveUserSettings(updatedSettings);
      await _themeService.setTheme(_selectedTheme);
      
      print('DEBUG: Settings saved successfully!');
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения настроек: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Расширенные настройки'),
      content: SizedBox(
        width: 600,
        height: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Общие настройки'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _defaultPathController,
                      decoration: const InputDecoration(
                        labelText: 'Папка для клонирования по умолчанию',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selectDefaultPath,
                    child: const Text('Обзор'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _diffToolController,
                      decoration: const InputDecoration(
                        labelText: 'Внешний инструмент для сравнения',
                        hintText: 'например: /usr/bin/bcompare',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _diffToolValue = value;
                        print('DEBUG: Diff tool changed to: "$value"');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _selectDiffTool,
                    icon: const Icon(Icons.list),
                    label: const Text('Выбрать'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    onPressed: _browseDiffTool,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Обзор'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _autoSaveCredentials,
                    onChanged: (value) => setState(() => _autoSaveCredentials = value ?? true),
                  ),
                  const Text('Сохранять учетные данные'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _autoUpdateRepositories,
                    onChanged: (value) => setState(() => _autoUpdateRepositories = value ?? false),
                  ),
                  const Text('Автоматически обновлять репозитории'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Лимит истории коммитов: '),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      controller: _commitHistoryLimitController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Тема приложения'),
              Row(
                children: [
                  Radio<AppTheme>(
                    value: AppTheme.light,
                    groupValue: _selectedTheme,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedTheme = value);
                      }
                    },
                  ),
                  const Text('Светлая'),
                  const SizedBox(width: 16),
                  Radio<AppTheme>(
                    value: AppTheme.dark,
                    groupValue: _selectedTheme,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedTheme = value);
                      }
                    },
                  ),
                  const Text('Темная'),
                  const SizedBox(width: 16),
                  Radio<AppTheme>(
                    value: AppTheme.system,
                    groupValue: _selectedTheme,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedTheme = value);
                      }
                    },
                  ),
                  const Text('Системная'),
                ],
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Игнорируемые файлы'),
              TextButton(
                onPressed: () {
                  setState(() {
                    _ignoredPatterns.addAll(IgnoreService.getCommonPatterns());
                    _ignoredPatterns = _ignoredPatterns.toSet().toList();
                  });
                },
                child: const Text('Добавить общие паттерны'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  itemCount: _ignoredPatterns.length,
                  itemBuilder: (context, index) {
                    final pattern = _ignoredPatterns[index];
                    return ListTile(
                      title: Text(pattern),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _ignoredPatterns.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              TextFormField(
                controller: _proxyUsernameController,
                decoration: const InputDecoration(
                  labelText: 'Имя пользователя прокси',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _proxyPasswordController,
                decoration: InputDecoration(
                  labelText: 'Пароль прокси',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureProxyPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscureProxyPassword = !_obscureProxyPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureProxyPassword,
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Шаблоны коммитов'),
              TextButton(
                onPressed: () {
                  setState(() {
                    _commitTemplates.addAll(CommitTemplateService.getExtendedTemplates());
                    _commitTemplates = _commitTemplates.toSet().toList();
                  });
                },
                child: const Text('Добавить расширенные шаблоны'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  itemCount: _commitTemplates.length,
                  itemBuilder: (context, index) {
                    final template = _commitTemplates[index];
                    return ListTile(
                      title: Text(template),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _commitTemplates.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  void dispose() {
    _defaultPathController.dispose();
    _diffToolController.dispose();
    _proxyHostController.dispose();
    _proxyPortController.dispose();
    _proxyUsernameController.dispose();
    _proxyPasswordController.dispose();
    _commitHistoryLimitController.dispose();
    super.dispose();
  }
}
