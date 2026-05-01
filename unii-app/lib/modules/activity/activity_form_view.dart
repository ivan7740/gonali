import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;

import 'package:unii_app/data/models/activity.dart';
import 'package:unii_app/data/repositories/activity_repo.dart';

/// Reusable create/edit form for activities.
///
/// Arguments (Get.arguments) is a Map:
/// - `teamId`: int — required when creating
/// - `activity`: [Activity] — pre-filled when editing
class ActivityFormView extends StatefulWidget {
  const ActivityFormView({super.key});

  @override
  State<ActivityFormView> createState() => _ActivityFormViewState();
}

class _ActivityFormViewState extends State<ActivityFormView> {
  late final Map<String, dynamic> _args;
  Activity? _existing;
  int? _teamId;

  final _title = TextEditingController();
  final _lng = TextEditingController();
  final _lat = TextEditingController();
  final _locationName = TextEditingController();
  final _content = TextEditingController();
  final _notice = TextEditingController();
  String _visibility = 'private';

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _args = Get.arguments as Map<String, dynamic>;
    _existing = _args['activity'] as Activity?;
    _teamId = _args['teamId'] as int? ?? _existing?.teamId;
    if (_existing != null) {
      _title.text = _existing!.title;
      _lng.text = _existing!.location.lng.toString();
      _lat.text = _existing!.location.lat.toString();
      _locationName.text = _existing!.locationName ?? '';
      _content.text = _existing!.content ?? '';
      _notice.text = _existing!.notice ?? '';
      _visibility = _existing!.visibility;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _lng.dispose();
    _lat.dispose();
    _locationName.dispose();
    _content.dispose();
    _notice.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    if (title.isEmpty || title.characters.length > 100) {
      setState(() => _error = 'activity_title_invalid'.tr);
      return;
    }
    final lng = double.tryParse(_lng.text.trim());
    final lat = double.tryParse(_lat.text.trim());
    if (lng == null ||
        lat == null ||
        lng < -180 ||
        lng > 180 ||
        lat < -90 ||
        lat > 90) {
      setState(() => _error = 'activity_location_invalid'.tr);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = Get.find<ActivityRepo>();
      if (_existing == null) {
        await repo.create(
          teamId: _teamId!,
          title: title,
          location: LngLat(lng: lng, lat: lat),
          visibility: _visibility,
          locationName: _locationName.text.trim().isEmpty
              ? null
              : _locationName.text.trim(),
          content: _content.text.trim().isEmpty ? null : _content.text.trim(),
          notice: _notice.text.trim().isEmpty ? null : _notice.text.trim(),
        );
      } else {
        await repo.update(
          id: _existing!.id,
          title: title,
          location: LngLat(lng: lng, lat: lat),
          visibility: _visibility,
          locationName: _locationName.text.trim(),
          content: _content.text.trim(),
          notice: _notice.text.trim(),
        );
      }
      if (!mounted) return;
      Get.back<void>();
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
      appBar: AppBar(
        title: Text(
          _existing == null ? 'activity_create'.tr : 'activity_edit'.tr,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              TextField(
                controller: _title,
                decoration: InputDecoration(labelText: 'activity_title'.tr),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _lng,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'longitude'.tr,
                        hintText: '121.4737',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _lat,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'latitude'.tr,
                        hintText: '31.2304',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'activity_map_picker_hint'.tr,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _locationName,
                decoration: InputDecoration(
                  labelText: 'activity_location_name'.tr,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _visibility,
                decoration: InputDecoration(labelText: 'visibility'.tr),
                items: [
                  DropdownMenuItem(
                    value: 'private',
                    child: Text('visibility_private'.tr),
                  ),
                  DropdownMenuItem(
                    value: 'public',
                    child: Text('visibility_public'.tr),
                  ),
                ],
                onChanged: (v) => setState(() => _visibility = v ?? 'private'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _content,
                maxLines: 4,
                decoration: InputDecoration(labelText: 'activity_content'.tr),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notice,
                maxLines: 3,
                decoration: InputDecoration(labelText: 'activity_notice'.tr),
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
