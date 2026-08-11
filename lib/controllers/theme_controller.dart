import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../theme/app_theme.dart';

class ThemeController extends GetxController {
  final _box = GetStorage();
  final _key = 'isDarkMode';

  final isDarkMode = true.obs;

  @override
  void onInit() {
    super.onInit();
    final savedTheme = _loadThemeFromBox();
    isDarkMode.value = savedTheme;
    Get.changeThemeMode(savedTheme ? ThemeMode.dark : ThemeMode.light);
  }

  ThemeMode get theme => isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  bool _loadThemeFromBox() => _box.read(_key) ?? true;

  void saveTheme(bool isDarkMode) => _box.write(_key, isDarkMode);

  void changeTheme(bool isDarkMode) {
    Get.changeThemeMode(isDarkMode ? ThemeMode.dark : ThemeMode.light);
    saveTheme(isDarkMode);
    this.isDarkMode.value = isDarkMode;
  }

  void toggleTheme() {
    changeTheme(!isDarkMode.value);
  }
}
