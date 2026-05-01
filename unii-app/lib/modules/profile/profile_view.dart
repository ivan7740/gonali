import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;

import 'package:unii_app/app/routes/app_routes.dart';
import 'package:unii_app/core/i18n/locale_controller.dart';
import 'package:unii_app/core/theme/theme_controller.dart';
import 'package:unii_app/modules/home/home_controller.dart';
import 'package:unii_app/modules/profile/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('tab_profile'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'logout'.tr,
            onPressed: () => Get.find<HomeController>().signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshMe,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _Header(),
            const Divider(height: 1),
            _Tile(
              icon: Icons.person_outline,
              title: 'profile_edit'.tr,
              onTap: () => Get.toNamed<void>(Routes.profileEdit),
            ),
            _Tile(
              icon: Icons.brightness_6_outlined,
              title: 'theme_title'.tr,
              trailing: Obx(
                () => Text(_themeLabel(Get.find<ThemeController>())),
              ),
              onTap: () => unawaited(_pickTheme(context)),
            ),
            _Tile(
              icon: Icons.language_outlined,
              title: 'language_title'.tr,
              trailing: Obx(
                () => Text(_localeLabel(Get.find<LocaleController>())),
              ),
              onTap: () => unawaited(_pickLanguage(context)),
            ),
            _Tile(
              icon: Icons.map_outlined,
              title: 'map_settings'.tr,
              onTap: () => Get.toNamed<void>(Routes.mapSettings),
            ),
            _Tile(
              icon: Icons.groups_outlined,
              title: 'my_teams'.tr,
              trailing: Text('coming_soon'.trParams({'wave': '3'})),
              onTap: () => _comingSoon(context, 3),
            ),
            _Tile(
              icon: Icons.history_edu_outlined,
              title: 'my_posts'.tr,
              trailing: Text('coming_soon'.trParams({'wave': '5'})),
              onTap: () => _comingSoon(context, 5),
            ),
            _Tile(
              icon: Icons.privacy_tip_outlined,
              title: 'privacy_title'.tr,
              onTap: () => Get.toNamed<void>(Routes.privacy),
            ),
            _Tile(
              icon: Icons.security_outlined,
              title: 'account_security'.tr,
              onTap: () => Get.toNamed<void>(Routes.accountSecurity),
            ),
            _Tile(
              icon: Icons.info_outline,
              title: 'about_title'.tr,
              onTap: () => Get.toNamed<void>(Routes.about),
            ),
          ],
        ),
      ),
    );
  }

  String _themeLabel(ThemeController c) => switch (c.backendValue) {
    'light' => 'theme_light'.tr,
    'dark' => 'theme_dark'.tr,
    _ => 'theme_system'.tr,
  };

  String _localeLabel(LocaleController c) =>
      c.backendValue == 'en' ? 'lang_en'.tr : 'lang_zh'.tr;

  Future<void> _pickTheme(BuildContext context) async {
    final c = Get.find<ThemeController>();
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('theme_system'.tr),
              onTap: () => Navigator.pop(ctx, 'system'),
            ),
            ListTile(
              title: Text('theme_light'.tr),
              onTap: () => Navigator.pop(ctx, 'light'),
            ),
            ListTile(
              title: Text('theme_dark'.tr),
              onTap: () => Navigator.pop(ctx, 'dark'),
            ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await c.setBackendValue(picked);
    await controller.updateSettings(theme: picked);
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final c = Get.find<LocaleController>();
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('lang_zh'.tr),
              onTap: () => Navigator.pop(ctx, 'zh'),
            ),
            ListTile(
              title: Text('lang_en'.tr),
              onTap: () => Navigator.pop(ctx, 'en'),
            ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await c.setBackendValue(picked);
    await controller.updateSettings(language: picked);
  }

  void _comingSoon(BuildContext context, int wave) {
    Get.snackbar(
      'tab_profile'.tr,
      'coming_soon'.trParams({'wave': '$wave'}),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProfileController>();
    return Obx(() {
      final u = c.user.value;
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage:
                  (u?.avatarUrl != null && u!.avatarUrl!.isNotEmpty)
                  ? NetworkImage(u.avatarUrl!)
                  : null,
              child: (u?.avatarUrl == null || u!.avatarUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 32)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u?.nickname?.isNotEmpty == true
                        ? u!.nickname!
                        : (u?.username ?? '...'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    u?.phone ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (c.isLoading.value)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      );
    });
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
