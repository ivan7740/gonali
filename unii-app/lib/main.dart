import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:unii_app/app/bindings/initial_binding.dart';
import 'package:unii_app/app/routes/app_pages.dart';
import 'package:unii_app/app/routes/app_routes.dart';
import 'package:unii_app/app/theme/app_theme.dart';
import 'package:unii_app/core/i18n/translations.dart';
import 'package:unii_app/core/storage/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  final hasToken = TokenStorage.peekHasAccess();
  final initial = hasToken ? Routes.home : Routes.login;

  // Read persisted theme/locale before first frame to avoid a flash.
  final box = GetStorage();
  final themeMode = _parseThemeMode(box.read<String>('theme_mode'));
  final locale =
      _parseLocale(box.read<String>('app_locale')) ?? Get.deviceLocale;

  runApp(
    UniiApp(
      initialRoute: initial,
      initialThemeMode: themeMode,
      initialLocale: locale,
    ),
  );
}

ThemeMode _parseThemeMode(String? s) => switch (s) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => ThemeMode.system,
};

Locale? _parseLocale(String? s) {
  if (s == null) return null;
  return Locale(s);
}

class UniiApp extends StatelessWidget {
  const UniiApp({
    required this.initialRoute,
    required this.initialThemeMode,
    required this.initialLocale,
    super.key,
  });

  final String initialRoute;
  final ThemeMode initialThemeMode;
  final Locale? initialLocale;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'UNII',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: initialThemeMode,
      initialBinding: InitialBinding(),
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: const Locale('en'),
      supportedLocales: const [Locale('zh'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
