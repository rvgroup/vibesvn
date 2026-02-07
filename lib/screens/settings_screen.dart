import 'package:flutter/material.dart';
import '../services/locale_service.dart';
import '../services/storage_service.dart';
import '../models/user_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocaleService _localeService = LocaleService();
  UserSettings? _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await StorageService.getUserSettings();
    setState(() {
      _settings = settings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings_screen.title'.tr(context)),
      ),
      body: _settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Language Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'settings_screen.general'.tr(context),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Language Selection
                        ListTile(
                          leading: const Icon(Icons.language),
                          title: Text('settings_screen.language'.tr(context)),
                          subtitle: Text(
                            LocaleService.localeNames[_localeService.getCurrentLocaleCode()] ?? 'Unknown',
                          ),
                          trailing: DropdownButton<String>(
                            value: _localeService.getCurrentLocaleCode(),
                            items: LocaleService.supportedLocales.map((locale) {
                              return DropdownMenuItem<String>(
                                value: locale.languageCode,
                                child: Text(LocaleService.localeNames[locale.languageCode] ?? locale.languageCode),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                _localeService.setLocale(newValue);
                              }
                            },
                          ),
                        ),
                        
                        const Divider(),
                        
                        // Theme Selection
                        ListTile(
                          leading: const Icon(Icons.palette),
                          title: Text('settings_screen.theme'.tr(context)),
                          subtitle: Text(_settings?.themeMode == 'dark' 
                            ? 'Dark' 
                            : _settings?.themeMode == 'light' 
                              ? 'Light' 
                              : 'System'),
                          trailing: DropdownButton<String>(
                            value: _settings?.themeMode ?? 'system',
                            items: const [
                              DropdownMenuItem(value: 'system', child: Text('System')),
                              DropdownMenuItem(value: 'light', child: Text('Light')),
                              DropdownMenuItem(value: 'dark', child: Text('Dark')),
                            ],
                            onChanged: (String? newValue) {
                              if (newValue != null && _settings != null) {
                                final updatedSettings = _settings!.copyWith(themeMode: newValue);
                                StorageService.saveUserSettings(updatedSettings);
                                _loadSettings();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // About Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'settings_screen.about'.tr(context),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.info),
                          title: const Text('VibeSVN'),
                          subtitle: const Text('Modern SVN Client'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
