import 'package:flutter/material.dart';

import 'package:unii_app/modules/home/tabs/_placeholder_widget.dart';

class TeamPlaceholder extends StatelessWidget {
  const TeamPlaceholder({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderTab(titleKey: 'tab_team', wave: 3);
}
