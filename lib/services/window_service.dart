import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'storage_service.dart';

class WindowService {
  static Future<void> initializeWindow() async {
    await windowManager.ensureInitialized();
    
    // Load saved window state
    final position = await StorageService.getWindowPosition();
    final size = await StorageService.getWindowSize();
    
    // Apply saved state or use defaults
    if (position != null) {
      await windowManager.setPosition(
        Offset(position['x']!, position['y']!),
      );
    }
    
    if (size != null) {
      final width = size['width']!;
      final height = size['height']!;
      await windowManager.setSize(Size(width, height));
    } else {
      // Default size
      await windowManager.setSize(const Size(1200, 800));
    }
    
    // Configure window properties
    await windowManager.setMinimumSize(const Size(800, 600));
    await windowManager.setTitle('VibeSVN');
    await windowManager.center();
    
    // Show the window
    await windowManager.show();
  }
  
  static Future<void> _saveWindowState() async {
    try {
      final rect = await windowManager.getBounds();
      
      // Don't save if window is maximized
      final isMaximized = await windowManager.isMaximized();
      if (!isMaximized) {
        await StorageService.saveWindowState(
          x: rect.left.toDouble(),
          y: rect.top.toDouble(),
          width: rect.width.toDouble(),
          height: rect.height.toDouble(),
        );
      }
    } catch (e) {
      print('Error saving window state: $e');
    }
  }
  
  static Future<void> resetWindowState() async {
    await windowManager.setSize(const Size(1200, 800));
    await windowManager.center();
    await _saveWindowState();
  }
  
  static Future<void> centerWindow() async {
    await windowManager.center();
  }
  
  static Future<void> toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }
  
  static Future<void> minimize() async {
    await windowManager.minimize();
  }
  
  static Future<void> close() async {
    await windowManager.close();
  }
  
  static Future<bool> isMaximized() async {
    return await windowManager.isMaximized();
  }
  
  static Future<Rect> getBounds() async {
    return await windowManager.getBounds();
  }
}
