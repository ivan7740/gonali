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

  runApp(UniiApp(initialRoute: initial));
}

class UniiApp extends StatelessWidget {
  const UniiApp({required this.initialRoute, super.key});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'UNII',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(),
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      translations: AppTranslations(),
      locale: Get.deviceLocale,
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
