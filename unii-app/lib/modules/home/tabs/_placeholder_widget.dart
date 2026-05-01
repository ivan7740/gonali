import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({required this.titleKey, required this.wave, super.key});

  final String titleKey;
  final int wave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titleKey.tr)),
      body: Center(
        child: Text(
          'coming_soon'.trParams({'wave': '$wave'}),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
