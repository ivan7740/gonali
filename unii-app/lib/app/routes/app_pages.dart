import 'package:get/get.dart';

import 'package:unii_app/app/routes/app_routes.dart';
import 'package:unii_app/modules/auth/auth_binding.dart';
import 'package:unii_app/modules/auth/login_view.dart';
import 'package:unii_app/modules/home/home_binding.dart';
import 'package:unii_app/modules/home/home_view.dart';

abstract class AppPages {
  AppPages._();

  static final List<GetPage<dynamic>> routes = [
    GetPage<void>(
      name: Routes.login,
      page: LoginView.new,
      binding: AuthBinding(),
    ),
    GetPage<void>(
      name: Routes.home,
      page: HomeView.new,
      binding: HomeBinding(),
    ),
  ];
}
