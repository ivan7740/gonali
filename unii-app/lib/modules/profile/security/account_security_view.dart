import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;

import 'package:unii_app/app/routes/app_routes.dart';
import 'package:unii_app/data/repositories/user_repo.dart';
import 'package:unii_app/modules/home/home_controller.dart';

class AccountSecurityView extends StatelessWidget {
  const AccountSecurityView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('account_security'.tr)),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text('change_password'.tr),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.toNamed<void>(Routes.passwordChange),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'delete_account'.tr,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_account_title'.tr),
        content: Text('delete_account_warning'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'confirm'.tr,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await Get.find<UserRepo>().deleteAccount();
    } on DioException {
      // Even if it fails, treat as logout to avoid stranding the user.
    }
    await Get.find<HomeController>().signOut();
  }
}
