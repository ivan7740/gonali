import 'package:get/get.dart';

import 'package:unii_app/app/routes/app_routes.dart';
import 'package:unii_app/modules/activity/activity_detail_view.dart';
import 'package:unii_app/modules/activity/activity_form_view.dart';
import 'package:unii_app/modules/auth/auth_binding.dart';
import 'package:unii_app/modules/auth/login_view.dart';
import 'package:unii_app/modules/home/home_binding.dart';
import 'package:unii_app/modules/home/home_view.dart';
import 'package:unii_app/modules/onboarding/map_picker_view.dart';
import 'package:unii_app/modules/profile/about/about_view.dart';
import 'package:unii_app/modules/profile/edit/profile_edit_view.dart';
import 'package:unii_app/modules/profile/map/map_settings_view.dart';
import 'package:unii_app/modules/profile/privacy/privacy_settings_view.dart';
import 'package:unii_app/modules/profile/security/account_security_view.dart';
import 'package:unii_app/modules/profile/security/password_change_view.dart';
import 'package:unii_app/modules/team/create/team_create_view.dart';
import 'package:unii_app/modules/team/detail/team_detail_view.dart';
import 'package:unii_app/modules/team/join/team_join_view.dart';
import 'package:unii_app/modules/team/members/team_members_view.dart';

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
    GetPage<void>(name: Routes.mapPicker, page: MapPickerView.new),
    GetPage<void>(name: Routes.profileEdit, page: ProfileEditView.new),
    GetPage<void>(name: Routes.passwordChange, page: PasswordChangeView.new),
    GetPage<void>(name: Routes.accountSecurity, page: AccountSecurityView.new),
    GetPage<void>(name: Routes.privacy, page: PrivacySettingsView.new),
    GetPage<void>(name: Routes.about, page: AboutView.new),
    GetPage<void>(name: Routes.mapSettings, page: MapSettingsView.new),
    GetPage<void>(name: Routes.teamCreate, page: TeamCreateView.new),
    GetPage<void>(name: Routes.teamJoin, page: TeamJoinView.new),
    GetPage<void>(name: Routes.teamDetail, page: TeamDetailView.new),
    GetPage<void>(name: Routes.teamMembers, page: TeamMembersView.new),
    GetPage<void>(name: Routes.activityForm, page: ActivityFormView.new),
    GetPage<void>(name: Routes.activityDetail, page: ActivityDetailView.new),
  ];
}
