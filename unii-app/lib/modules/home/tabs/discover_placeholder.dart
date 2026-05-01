import 'package:flutter/material.dart';

import 'package:unii_app/modules/home/tabs/_placeholder_widget.dart';

class DiscoverPlaceholder extends StatelessWidget {
  const DiscoverPlaceholder({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderTab(titleKey: 'tab_discover', wave: 5);
}
