import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================
/// THEME CONTROLLER
/// Manages Dark/Light Mode with persistence
/// ============================================

class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  // Observable theme mode
  final _isDarkMode = true.obs;
  bool get isDarkMode => _isDarkMode.value;

  // Storage key
  static const String _themeKey = 'is_dark_mode';

  @override
  void onInit() {
    super.onInit();
    _loadThemeFromStorage();
  }

  /// Load saved theme preference
  Future<void> _loadThemeFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode.value = prefs.getBool(_themeKey) ?? true; // Default to dark
    _applyTheme();
  }

  /// Toggle between dark and light mode
  Future<void> toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
    await _saveThemeToStorage();
    _applyTheme();
  }

  /// Set specific theme mode
  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode.value = isDark;
    await _saveThemeToStorage();
    _applyTheme();
  }

  /// Save theme preference
  Future<void> _saveThemeToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode.value);
  }

  /// Apply theme to app
  void _applyTheme() {
    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  /// Get current theme mode
  ThemeMode get themeMode => _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
}