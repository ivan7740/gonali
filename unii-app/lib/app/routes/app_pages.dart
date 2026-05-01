import 'package:get/get.dart';

import 'package:unii_app/app/routes/app_routes.dart';
import 'package:unii_app/modules/auth/auth_binding.dart';
import 'package:unii_app/modules/auth/login_view.dart';
import 'package:unii_app/modules/home/home_binding.dart';
import 'package:unii_app/modules/home/home_view.dart';
import 'package:unii_app/modules/profile/about/about_view.dart';
import 'package:unii_app/modules/profile/edit/profile_edit_view.dart';
import 'package:unii_app/modules/profile/map/map_settings_view.dart';
import 'package:unii_app/modules/profile/privacy/privacy_settings_view.dart';
import 'package:unii_app/modules/profile/security/account_security_view.dart';
import 'package:unii_app/modules/profile/security/password_change_view.dart';

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
    GetPage<void>(name: Routes.profileEdit, page: ProfileEditView.new),
    GetPage<void>(name: Routes.passwordChange, page: PasswordChangeView.new),
    GetPage<void>(name: Routes.accountSecurity, page: AccountSecurityView.new),
    GetPage<void>(name: Routes.privacy, page: PrivacySettingsView.new),
    GetPage<void>(name: Routes.about, page: AboutView.new),
    GetPage<void>(name: Routes.mapSettings, page: MapSettingsView.new),
  ];
}
