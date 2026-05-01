import 'package:flutter/material.dart';

import 'package:unii_app/modules/home/tabs/_placeholder_widget.dart';

class ChatPlaceholder extends StatelessWidget {
  const ChatPlaceholder({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderTab(titleKey: 'tab_chat', wave: 6);
}
