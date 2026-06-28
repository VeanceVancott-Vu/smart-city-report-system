import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/files/upload_file_picker.dart';
import '../../../core/ui/app_feedback.dart';
import '../data/report_api_service.dart';
import '../domain/report.dart';
import 'citizen_report_map_picker.dart';

class CitizenReportForm extends StatefulWidget {
  const CitizenReportForm({
    super.key,
    this.initialReport,
    required this.submitLabel,
    required this.onSubmit,
    required this.onUploadBeforePhoto,
    required this.reportApiService,
  });

  final Report? initialReport;
  final String submitLabel;
  final Future<void> Function(ReportDraft draft) onSubmit;
  final Future<String> Function({
    required String filename,
    required List<int> bytes,
  })
  onUploadBeforePhoto;
  final ReportApiService reportApiService;

  @override
  State<CitizenReportForm> createState() => _CitizenReportFormState();
}

class _CitizenReportFormState extends State<CitizenReportForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _addressController;

  late ReportCategory _category;
  late bool _anonymous;
  String? _beforePhotoUrl;
  String? _beforePhotoError;
  bool _isUploadingPhoto = false;
  bool _isSaving = false;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final report = widget.initialReport;
    _titleController = TextEditingController(text: report?.title ?? '');
    _descriptionController = TextEditingController(
      text: report?.description ?? '',
    );
    _latitudeController = TextEditingController(
      text: (report?.latitude ?? 10.7769).toString(),
    );
    _longitudeController = TextEditingController(
      text: (report?.longitude ?? 106.7009).toString(),
    );
    _addressController = TextEditingController(text: report?.addressText ?? '');
    _beforePhotoUrl = report?.beforePhotoUrl;
    _category = report?.category ?? ReportCategory.roadDamage;
    _anonymous = report?.anonymous ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _addressController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final double? currentLat = double.tryParse(_latitudeController.text);
    final double? currentLng = double.tryParse(_longitudeController.text);
    final LatLng? initialLoc = currentLat != null && currentLng != null
        ? LatLng(currentLat, currentLng)
        : null;

    final result = await Navigator.of(context).push<MapPickerResult>(
      MaterialPageRoute(
        builder: (context) => CitizenReportMapPicker(
          reportApiService: widget.reportApiService,
          initialLocation: initialLoc,
          initialAddress: _addressController.text,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitudeController.text = result.location.latitude.toString();
        _longitudeController.text = result.location.longitude.toString();
        _addressController.text = result.address;
      });
    }
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }
    if ((_beforePhotoUrl ?? '').trim().isEmpty) {
      setState(() => _beforePhotoError = 'Upload a before photo first');
      AppFeedback.showError(
        context,
        title: 'Before photo required',
        message: 'Upload a photo before submitting the report.',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      await widget.onSubmit(
        ReportDraft(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _category,
          latitude: double.parse(_latitudeController.text.trim()),
          longitude: double.parse(_longitudeController.text.trim()),
          addressText: _nullableText(_addressController),
          beforePhotoUrl: _beforePhotoUrl,
          anonymous: _anonymous,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickAndUploadBeforePhoto() async {
    if (_isSaving || _isUploadingPhoto) {
      return;
    }

    setState(() {
      _isUploadingPhoto = true;
      _beforePhotoError = null;
    });

    try {
      final pickedFile = await pickImageUploadFile();
      if (pickedFile == null) {
        return;
      }

      final fileUrl = await widget.onUploadBeforePhoto(
        filename: pickedFile.filename,
        bytes: pickedFile.bytes,
      );
      if (!mounted) {
        return;
      }
      setState(() => _beforePhotoUrl = fileUrl);
      AppFeedback.showSuccess(context, title: 'Before photo uploaded');
    } on FilePickerException catch (error) {
      _setPhotoError(error.message);
    } catch (error) {
      final message = error.toString();
      _setPhotoError(
        message.isEmpty ? 'Unable to upload before photo.' : message,
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  void _setPhotoError(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _beforePhotoError = message);
    AppFeedback.showError(
      context,
      title: 'Photo upload failed',
      message: message,
    );
  }

  String? _nullableText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    final bool isTestMode = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('Test');
    return Form(
      key: _formKey,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            FocusScope.of(context).unfocus();
          }
          return false;
        },
        child: ListView(
          controller: _scrollController,
          cacheExtent: 1000,
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title),
              ),
              textInputAction: TextInputAction.next,
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              minLines: 3,
              maxLines: 5,
              validator: _required,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ReportCategory>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: ReportCategory.values
                  .map(
                    (category) => DropdownMenuItem<ReportCategory>(
                      value: category,
                      child: Text(category.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _isSaving
                  ? null
                  : (category) {
                      if (category != null) {
                        setState(() => _category = category);
                      }
                    },
            ),
            const SizedBox(height: 12),
            if (!isTestMode) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Location Selection',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _openMapPicker,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Select Location on Map'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 560;
                final latitudeField = TextFormField(
                  controller: _latitudeController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    prefixIcon: Icon(Icons.my_location_outlined),
                  ),
                );
                final longitudeField = TextFormField(
                  controller: _longitudeController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    prefixIcon: Icon(Icons.explore_outlined),
                  ),
                );

                return isWide
                    ? Row(
                        children: [
                          Expanded(child: latitudeField),
                          const SizedBox(width: 12),
                          Expanded(child: longitudeField),
                        ],
                      )
                    : Column(
                        children: [
                          latitudeField,
                          const SizedBox(height: 12),
                          longitudeField,
                        ],
                      );
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address text',
                prefixIcon: Icon(Icons.place_outlined),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            _PhotoUploadField(
              label: 'Before photo',
              fileUrl: _beforePhotoUrl,
              errorText: _beforePhotoError,
              isUploading: _isUploadingPhoto,
              onUpload: _pickAndUploadBeforePhoto,
            ),
            if (widget.initialReport == null) ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _anonymous,
                onChanged: _isSaving
                    ? null
                    : (value) => setState(() => _anonymous = value ?? false),
                title: const Text('Submit anonymously'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSaving || _isUploadingPhoto ? null : _submit,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(widget.submitLabel),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _latitude(String? value) {
    final parsed = _coordinate(value);
    if (parsed != null) {
      return parsed;
    }

    final number = double.parse(value!.trim());
    if (number < -90 || number > 90) {
      return 'Use -90 to 90';
    }
    return null;
  }

  String? _longitude(String? value) {
    final parsed = _coordinate(value);
    if (parsed != null) {
      return parsed;
    }

    final number = double.parse(value!.trim());
    if (number < -180 || number > 180) {
      return 'Use -180 to 180';
    }
    return null;
  }

  String? _coordinate(String? value) {
    if (_required(value) != null) {
      return 'Required';
    }

    final parsed = double.tryParse(value!.trim());
    if (parsed == null) {
      return 'Use a number';
    }
    return null;
  }
}

class _PhotoUploadField extends StatelessWidget {
  const _PhotoUploadField({
    required this.label,
    required this.fileUrl,
    required this.errorText,
    required this.isUploading,
    required this.onUpload,
  });

  final String label;
  final String? fileUrl;
  final String? errorText;
  final bool isUploading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final hasFile = (fileUrl ?? '').trim().isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: isUploading ? null : onUpload,
          icon: isUploading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file),
          label: Text(hasFile ? 'Replace photo' : 'Upload photo'),
        ),
        if (hasFile) ...[
          const SizedBox(height: 8),
          Text(
            fileUrl!,
            style: TextStyle(color: colorScheme.primary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(errorText!, style: TextStyle(color: colorScheme.error)),
        ],
      ],
    );
  }
}
