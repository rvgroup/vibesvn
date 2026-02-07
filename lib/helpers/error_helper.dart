import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/svn_result.dart';

class ErrorHelper {
  static void showSvnError(BuildContext context, SvnResult result, String operation) {
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$operation: ${result.errorMessage}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Подробнее',
            onPressed: () {
              _showDetailedError(context, result, operation);
            },
          ),
        ),
      );
    }
  }

  static void _showDetailedError(BuildContext context, SvnResult result, String operation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text('Ошибка $operation'),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () => _copyErrorToClipboard(context, result, operation),
              tooltip: 'Копировать ошибку',
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Детальная информация об ошибке:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  result.errorMessage ?? 'Неизвестная ошибка',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              if (result.output != null && result.output!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Вывод команды:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    result.output!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _copyErrorToClipboard(context, result, operation);
              Navigator.pop(context);
            },
            child: const Text('Копировать и закрыть'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  static void _copyErrorToClipboard(BuildContext context, SvnResult result, String operation) {
    final buffer = StringBuffer();
    buffer.writeln('=== Ошибка SVN операции ===');
    buffer.writeln('Операция: $operation');
    buffer.writeln('Время: ${DateTime.now()}');
    buffer.writeln('');
    
    if (result.errorMessage != null) {
      buffer.writeln('Сообщение об ошибке:');
      buffer.writeln(result.errorMessage!);
      buffer.writeln('');
    }
    
    if (result.output != null && result.output!.isNotEmpty) {
      buffer.writeln('Вывод команды:');
      buffer.writeln(result.output!);
      buffer.writeln('');
    }
    
    buffer.writeln('=== Конец информации об ошибке ===');
    
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ошибка скопирована в буфер обмена'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
