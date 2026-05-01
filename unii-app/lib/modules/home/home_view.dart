import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:unii_app/modules/home/home_controller.dart';
import 'package:unii_app/modules/home/tabs/chat_placeholder.dart';
import 'package:unii_app/modules/home/tabs/discover_placeholder.dart';
import 'package:unii_app/modules/home/tabs/team_placeholder.dart';
import 'package:unii_app/modules/profile/profile_view.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  static const _tabs = <Widget>[
    DiscoverPlaceholder(),
    TeamPlaceholder(),
    ChatPlaceholder(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          return IndexedStack(
            index: controller.tabIndex.value,
            children: _tabs,
          );
        }),
      ),
      bottomNavigationBar: Obx(() {
        return NavigationBar(
          selectedIndex: controller.tabIndex.value,
          onDestinationSelected: (i) => controller.tabIndex.value = i,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.explore_outlined),
              selectedIcon: const Icon(Icons.explore),
              label: 'tab_discover'.tr,
            ),
            NavigationDestination(
              icon: const Icon(Icons.groups_outlined),
              selectedIcon: const Icon(Icons.groups),
              label: 'tab_team'.tr,
            ),
            NavigationDestination(
              icon: const Icon(Icons.chat_bubble_outline),
              selectedIcon: const Icon(Icons.chat_bubble),
              label: 'tab_chat'.tr,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: 'tab_profile'.tr,
            ),
          ],
        );
      }),
    );
  }
}
