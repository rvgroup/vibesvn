import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'storage_service.dart';

class WindowService {
  static Timer? _saveTimer;
  static bool _isInitialized = false;
  
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
    
    // Add window event listeners
    await _setupWindowListeners();
    
    // Show the window
    await windowManager.show();
    _isInitialized = true;
  }
  
  static Future<void> _setupWindowListeners() async {
    windowManager.addListener(_WindowListener());
  }
  
  static void _scheduleSave() {
    // Cancel previous timer
    _saveTimer?.cancel();
    
    // Schedule new save with debounce (1 second delay)
    _saveTimer = Timer(const Duration(seconds: 1), () {
      _saveWindowState();
    });
  }
  
  static Future<void> _saveWindowState() async {
    try {
      if (!_isInitialized) return;
      
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
        print('Window state saved: ${rect.width}x${rect.height} at (${rect.left}, ${rect.top})');
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
  
  static void dispose() {
    _saveTimer?.cancel();
    windowManager.removeListener(_WindowListener());
  }
}

class _WindowListener extends WindowListener {
  @override
  void onWindowResize() {
    WindowService._scheduleSave();
  }
  
  @override
  void onWindowResized() {
    WindowService._scheduleSave();
  }
  
  @override
  void onWindowMove() {
    WindowService._scheduleSave();
  }
  
  @override
  void onWindowMoved() {
    WindowService._scheduleSave();
  }
  
  @override
  void onWindowMaximize() {
    // Don't save when maximized
  }
  
  @override
  void onWindowUnmaximize() {
    WindowService._scheduleSave();
  }
  
  @override
  void onWindowRestore() {
    WindowService._scheduleSave();
  }
  
  @override
  void onWindowClose() async {
    // Save state before closing
    await WindowService._saveWindowState();
  }
}
