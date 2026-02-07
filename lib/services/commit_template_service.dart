import '../services/storage_service.dart';

class CommitTemplateService {
  static Future<List<String>> getTemplates() async {
    final settings = await StorageService.getUserSettings();
    return settings.commitTemplates;
  }

  static Future<void> addTemplate(String template) async {
    final settings = await StorageService.getUserSettings();
    final templates = List<String>.from(settings.commitTemplates);
    
    if (!templates.contains(template)) {
      templates.add(template);
      final updatedSettings = settings.copyWith(commitTemplates: templates);
      await StorageService.saveUserSettings(updatedSettings);
    }
  }

  static Future<void> removeTemplate(String template) async {
    final settings = await StorageService.getUserSettings();
    final templates = List<String>.from(settings.commitTemplates);
    
    templates.remove(template);
    final updatedSettings = settings.copyWith(commitTemplates: templates);
    await StorageService.saveUserSettings(updatedSettings);
  }

  static Future<void> updateTemplates(List<String> templates) async {
    final settings = await StorageService.getUserSettings();
    final updatedSettings = settings.copyWith(commitTemplates: templates);
    await StorageService.saveUserSettings(updatedSettings);
  }

  static String formatTemplate(String template, {String description = ''}) {
    return template.replaceAll('{description}', description);
  }

  static List<String> getDefaultTemplates() {
    return [
      'feat: {description}',
      'fix: {description}',
      'docs: {description}',
      'style: {description}',
      'refactor: {description}',
      'test: {description}',
      'chore: {description}',
      'hotfix: {description}',
      'revert: {description}',
      'perf: {description}',
      'ci: {description}',
      'build: {description}',
    ];
  }

  static List<String> getExtendedTemplates() {
    return [
      'feat: {description}',
      'fix: {description}',
      'docs: {description}',
      'style: {description}',
      'refactor: {description}',
      'test: {description}',
      'chore: {description}',
      'hotfix: {description}',
      'revert: {description}',
      'perf: {description}',
      'ci: {description}',
      'build: {description}',
      'feat({scope}): {description}',
      'fix({scope}): {description}',
      'feat: {description}\n\nCloses #{issue}',
      'fix: {description}\n\nFixes #{issue}',
      'feat: {description}\n\nBREAKING CHANGE: {breaking}',
      'Merge branch {branch}',
      'Release v{version}',
      'Update {filename}',
      'Add {feature}',
      'Remove {feature}',
      'Improve {feature}',
      'Optimize {feature}',
    ];
  }

  static String getTemplateDescription(String template) {
    switch (template) {
      case 'feat: {description}':
        return 'Новая функциональность';
      case 'fix: {description}':
        return 'Исправление бага';
      case 'docs: {description}':
        return 'Изменение документации';
      case 'style: {description}':
        return 'Изменение форматирования кода';
      case 'refactor: {description}':
        return 'Рефакторинг кода';
      case 'test: {description}':
        return 'Добавление тестов';
      case 'chore: {description}':
        return 'Обслуживание, обновление зависимостей';
      case 'hotfix: {description}':
        return 'Срочное исправление';
      case 'revert: {description}':
        return 'Откат изменений';
      case 'perf: {description}':
        return 'Улучшение производительности';
      case 'ci: {description}':
        return 'Изменение CI/CD';
      case 'build: {description}':
        return 'Изменение сборки';
      default:
        return 'Пользовательский шаблон';
    }
  }

  static bool isValidTemplate(String template) {
    return template.isNotEmpty && template.contains('{description}');
  }
}
