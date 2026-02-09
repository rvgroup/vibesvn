import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import '../models/user_settings.dart';
import '../services/storage_service.dart';
import '../services/ignore_service.dart';
import '../services/commit_template_service.dart';

class AdvancedSettingsDialog extends StatefulWidget {
  const AdvancedSettingsDialog({super.key});

  @override
  State<AdvancedSettingsDialog> createState() => _AdvancedSettingsDialogState();
}

class _AdvancedSettingsDialogState extends State<AdvancedSettingsDialog> {
  late UserSettings _settings;
  
  final _defaultPathController = TextEditingController();
  final _diffToolController = TextEditingController();
  final _fileViewerController = TextEditingController();
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
  bool _obscureDefaultPassword = true;
  bool _obscureProxyPassword = true;
  
  // Store diff tool value separately to ensure it's preserved
  String _diffToolValue = '';
  String _fileViewerValue = '';
  
  // Predefined diff tools
  static const Map<String, String> _diffTools = {
    'Meld': '/opt/homebrew/bin/meld',
    'VS Code': '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code',
    'FileMerge': '/usr/bin/opendiff',
  };
  
  // Predefined file viewers
  static const Map<String, String> _fileViewers = {
    'VS Code': '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code',
    'Sublime Text': '/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl',
    'TextMate': '/usr/local/bin/mate',
    'Vim': '/usr/bin/vim',
    'Nano': '/usr/bin/nano',
  };

  @override
  void initState() {
    super.initState();
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
          _fileViewerValue = settings.externalFileViewer;
          _fileViewerController.text = settings.externalFileViewer;
          print('DEBUG: Set diff tool controller to: "${_diffToolController.text}"');
          print('DEBUG: Set diff tool value to: "$_diffToolValue"');
          print('DEBUG: Set file viewer controller to: "${_fileViewerController.text}"');
          print('DEBUG: Set file viewer value to: "$_fileViewerValue"');
          _ignoredPatterns = List.from(settings.ignoredPatterns);
          _commitTemplates = List.from(settings.commitTemplates);
          _autoUpdateRepositories = settings.autoUpdateRepositories;
          _autoSaveCredentials = settings.autoSaveCredentials;
          _commitHistoryLimit = settings.commitMessageHistoryLimit;
          _commitHistoryLimitController.text = _commitHistoryLimit.toString();
          
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
          SnackBar(content: Text('Error loading settings: {error}'.tr().replaceAll('{error}', e.toString()))),
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
        title: Text('Select comparison tool'.tr()),
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
            child: Text('Cancel'.tr()),
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

  Future<void> _selectFileViewer() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select file viewer'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _fileViewers.entries.map((entry) {
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
            child: Text('Cancel'.tr()),
          ),
        ],
      ),
    );
    
    if (result != null) {
      setState(() {
        _fileViewerController.text = result;
        _fileViewerValue = result;
      });
    }
  }

  Future<void> _browseFileViewer() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['exe', 'app', 'sh', 'py', ''],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _fileViewerController.text = result.files.single.path!;
        _fileViewerValue = result.files.single.path!;
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
      final currentFileViewerValue = _fileViewerController.text.trim();
      print('DEBUG: Final diff tool value to save: "$currentDiffToolValue"');
      print('DEBUG: Final file viewer value to save: "$currentFileViewerValue"');
      
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
        externalFileViewer: currentFileViewerValue,
        ignoredPatterns: _ignoredPatterns,
        commitTemplates: _commitTemplates,
        autoUpdateRepositories: _autoUpdateRepositories,
        autoSaveCredentials: _autoSaveCredentials,
        commitMessageHistoryLimit: int.tryParse(_commitHistoryLimitController.text) ?? 50,
        proxySettings: proxySettings,
      );

      print('DEBUG: Updated settings externalDiffTool: "${updatedSettings.externalDiffTool}"');
      print('DEBUG: Updated settings externalFileViewer: "${updatedSettings.externalFileViewer}"');
      
      await StorageService.saveUserSettings(updatedSettings);
      
      print('DEBUG: Settings saved successfully!');
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: {error}'.tr().replaceAll('{error}', e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Advanced Settings'.tr()),
      content: SizedBox(
        width: 600,
        height: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('General Settings'.tr()),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _defaultPathController,
                      decoration: InputDecoration(
                        labelText: 'Default clone folder'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selectDefaultPath,
                    child: Text('Browse'.tr()),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _diffToolController,
                      decoration: InputDecoration(
                        labelText: 'External diff tool'.tr(),
                        hintText: 'e.g.: /usr/bin/bcompare'.tr(),
                        border: const OutlineInputBorder(),
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
                    label: Text('Select'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    onPressed: _browseDiffTool,
                    icon: const Icon(Icons.folder_open),
                    label: Text('Browse'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // External file viewer
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fileViewerController,
                      decoration: InputDecoration(
                        labelText: 'External file viewer'.tr(),
                        hintText: 'e.g.: /usr/bin/code'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _fileViewerValue = value;
                        print('DEBUG: File viewer changed to: "$value"');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _selectFileViewer,
                    icon: const Icon(Icons.list),
                    label: Text('Select'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    onPressed: _browseFileViewer,
                    icon: const Icon(Icons.folder_open),
                    label: Text('Browse'.tr()),
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
                  Text('Save credentials'.tr()),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _autoUpdateRepositories,
                    onChanged: (value) => setState(() => _autoUpdateRepositories = value ?? false),
                  ),
                  Text('Auto update repositories'.tr()),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Commit history limit: '.tr()),
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
              _buildSectionTitle('Ignored Files'.tr()),
              TextButton(
                onPressed: () {
                  setState(() {
                    _ignoredPatterns.addAll(IgnoreService.getCommonPatterns());
                    _ignoredPatterns = _ignoredPatterns.toSet().toList();
                  });
                },
                child: Text('Add common patterns'.tr()),
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
                decoration: InputDecoration(
                  labelText: 'Proxy username'.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _proxyPasswordController,
                decoration: InputDecoration(
                  labelText: 'Proxy password'.tr(),
                  border: const OutlineInputBorder(),
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
              _buildSectionTitle('Commit Templates'.tr()),
              TextButton(
                onPressed: () {
                  setState(() {
                    _commitTemplates.addAll(CommitTemplateService.getExtendedTemplates());
                    _commitTemplates = _commitTemplates.toSet().toList();
                  });
                },
                child: Text('Add advanced templates'.tr()),
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
          child: Text('Cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          child: Text('Save'.tr()),
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
    _fileViewerController.dispose();
    _proxyHostController.dispose();
    _proxyPortController.dispose();
    _proxyUsernameController.dispose();
    _proxyPasswordController.dispose();
    _commitHistoryLimitController.dispose();
    super.dispose();
  }
}
