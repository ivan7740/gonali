import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;

import 'package:unii_app/app/routes/app_routes.dart';
import 'package:unii_app/data/repositories/team_repo.dart';
import 'package:unii_app/modules/team/team_controller.dart';

class TeamJoinView extends StatefulWidget {
  const TeamJoinView({super.key});

  @override
  State<TeamJoinView> createState() => _TeamJoinViewState();
}

class _TeamJoinViewState extends State<TeamJoinView> {
  final _code = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _code.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'invite_code_invalid'.tr);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final team = await Get.find<TeamRepo>().joinByCode(code);
      if (Get.isRegistered<TeamController>()) {
        await Get.find<TeamController>().reload();
      }
      if (!mounted) return;
      Get.back<void>();
      unawaited(Get.toNamed<void>(Routes.teamDetail, arguments: team.id));
    } on DioException catch (e) {
      final raw = e.response?.data;
      setState(() {
        _error = raw is Map<String, dynamic>
            ? (raw['msg']?.toString() ?? 'network_error'.tr)
            : 'network_error'.tr;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('team_join'.tr)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'team_join_help'.tr,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'invite_code'.tr,
                  hintText: 'AB23XY',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('submit'.tr),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
