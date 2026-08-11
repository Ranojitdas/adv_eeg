import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LanguageController extends GetxController {
  final _box = GetStorage();
  final _key = 'language';

  final currentLocale = const Locale('en').obs;
  final supportedLocales = [
    const Locale('en'),
    const Locale('hi'),
  ];

  @override
  void onInit() {
    super.onInit();
    final savedLanguage = _box.read(_key) ?? 'en';
    currentLocale.value = Locale(savedLanguage);
    Get.updateLocale(Locale(savedLanguage));
  }

  String get language => _box.read(_key) ?? 'en';

  String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिंदी';
      default:
        return 'English';
    }
  }

  void changeLanguage(String langCode) {
    Get.updateLocale(Locale(langCode));
    _box.write(_key, langCode);
    currentLocale.value = Locale(langCode);
  }
}
