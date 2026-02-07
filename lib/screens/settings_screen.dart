import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import '../models/user_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ThemeService _themeService = ThemeService();
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
        title: Text('Settings'.tr()),
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
                          'General'.tr(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Language Selection
                        ListTile(
                          leading: const Icon(Icons.language),
                          title: Text('Language'.tr()),
                          subtitle: Text(context.locale.languageCode == 'en' ? 'English' : 'Русский'),
                          trailing: DropdownButton<String>(
                            value: context.locale.languageCode,
                            items: const [
                              DropdownMenuItem(value: 'en', child: Text('English')),
                              DropdownMenuItem(value: 'ru', child: Text('Русский')),
                            ],
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                context.setLocale(Locale(newValue));
                              }
                            },
                          ),
                        ),

                        const Divider(),

                        // Theme Selection
                        ListTile(
                          leading: const Icon(Icons.palette),
                          title: Text('Theme'.tr()),
                          subtitle: Text(_settings?.appTheme.name
                            ?? 'System'),
                          trailing: DropdownButton<AppTheme>(
                            value: _settings?.appTheme ?? AppTheme.system,
                            items: AppTheme.values.map((theme) {
                              return DropdownMenuItem<AppTheme>(
                                value: theme,
                                child: Text(theme.name),
                              );
                            }).toList(),
                            onChanged: (AppTheme? newValue) {
                              if (newValue != null) {
                                _themeService.setTheme(newValue);
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
                          'About'.tr(),
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
