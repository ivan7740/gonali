import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;

import 'package:unii_app/app/routes/app_routes.dart';
import 'package:unii_app/data/repositories/team_repo.dart';
import 'package:unii_app/modules/team/team_controller.dart';

class TeamCreateView extends StatefulWidget {
  const TeamCreateView({super.key});

  @override
  State<TeamCreateView> createState() => _TeamCreateViewState();
}

class _TeamCreateViewState extends State<TeamCreateView> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _memberLimit = TextEditingController(text: '30');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _memberLimit.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty || name.characters.length > 50) {
      setState(() => _error = 'team_name_invalid'.tr);
      return;
    }
    final limit = int.tryParse(_memberLimit.text.trim());
    if (limit == null || limit < 2 || limit > 500) {
      setState(() => _error = 'team_limit_invalid'.tr);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final team = await Get.find<TeamRepo>().create(
        name: name,
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        memberLimit: limit,
      );
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
      appBar: AppBar(title: Text('team_create'.tr)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              TextField(
                controller: _name,
                decoration: InputDecoration(labelText: 'team_name'.tr),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _description,
                maxLines: 3,
                decoration: InputDecoration(labelText: 'team_description'.tr),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _memberLimit,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'team_member_limit'.tr),
              ),
              const SizedBox(height: 24),
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
