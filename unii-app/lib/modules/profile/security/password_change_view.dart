import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;

import 'package:unii_app/data/repositories/user_repo.dart';

class PasswordChangeView extends StatefulWidget {
  const PasswordChangeView({super.key});

  @override
  State<PasswordChangeView> createState() => _PasswordChangeViewState();
}

class _PasswordChangeViewState extends State<PasswordChangeView> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool _validateNew(String s) {
    if (s.length < 8 || s.length > 64) return false;
    return s.contains(RegExp(r'[A-Za-z]')) && s.contains(RegExp(r'\d'));
  }

  Future<void> _submit() async {
    if (!_validateNew(_new.text)) {
      setState(() => _error = 'invalid_password'.tr);
      return;
    }
    if (_new.text != _confirm.text) {
      setState(() => _error = 'passwords_dont_match'.tr);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await Get.find<UserRepo>().changePassword(
        oldPassword: _old.text,
        newPassword: _new.text,
      );
      if (!mounted) return;
      Get.back<void>();
      Get.snackbar('account_security'.tr, 'password_changed'.tr);
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
      appBar: AppBar(title: Text('change_password'.tr)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              TextField(
                controller: _old,
                obscureText: true,
                decoration: InputDecoration(labelText: 'old_password'.tr),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _new,
                obscureText: true,
                decoration: InputDecoration(labelText: 'new_password'.tr),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirm,
                obscureText: true,
                decoration: InputDecoration(labelText: 'confirm_password'.tr),
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
                    : Text('save'.tr),
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
