import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/files/upload_file_picker.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/domain_localizations.dart';
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
      setState(() => _beforePhotoError = context.l10n.beforePhotoRequiredError);
      AppFeedback.showError(
        context,
        title: context.l10n.beforePhotoRequiredTitle,
        message: context.l10n.beforePhotoRequiredMessage,
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
      AppFeedback.showSuccess(context, title: context.l10n.beforePhotoUploaded);
    } on FilePickerException catch (error) {
      _setPhotoError(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error.toString();
      _setPhotoError(
        message.isEmpty ? context.l10n.beforePhotoUploadFailed : message,
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
      title: context.l10n.photoUploadFailedTitle,
      message: message,
    );
  }

  String? _nullableText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  IconData _getCategoryIconLocal(ReportCategory cat) {
    switch (cat) {
      case ReportCategory.roadDamage:
        return Icons.warning_amber_rounded;
      case ReportCategory.streetLight:
        return Icons.lightbulb_outline;
      case ReportCategory.garbage:
        return Icons.delete_outline;
      case ReportCategory.waterLeak:
        return Icons.water_drop_outlined;
      case ReportCategory.drainage:
        return Icons.waves_outlined;
      case ReportCategory.trafficSign:
        return Icons.traffic_outlined;
      case ReportCategory.treeBlockage:
        return Icons.park_outlined;
      case ReportCategory.other:
        return Icons.help_outline_rounded;
    }
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
          key: const Key('report_form_list'),
          controller: _scrollController,
          cacheExtent: 1000,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            // SECTION 1: INCIDENT CATEGORY SELECTOR (GRID CARD STATEFUL VIEW)
            Text(
              'Incident Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111C2D),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 100,
              ),
              itemCount: ReportCategory.values.length,
              itemBuilder: (context, index) {
                final currentCat = ReportCategory.values[index];
                final isSelected = _category == currentCat;

                return InkWell(
                  onTap: _isSaving
                      ? null
                      : () {
                          setState(() => _category = currentCat);
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFBDECE2)
                          : const Color(0xFFF9F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0F766E)
                            : const Color(0xFFBDC9C6).withOpacity(0.5),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getCategoryIconLocal(currentCat),
                                size: 36,
                                color: isSelected
                                    ? const Color(0xFF0F766E)
                                    : const Color(0xFF3E4947),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                currentCat.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF0F766E)
                                      : const Color(0xFF111C2D),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F766E),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // SECTION 2: VISUAL PROOF & IMAGE PREVIEW PANEL
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Visual Proof',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111C2D),
                  ),
                ),
                Text(
                  _beforePhotoUrl != null ? '1/1 Photo' : '0/1 Photo',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3E4947),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PhotoUploadField(
              label: 'Upload a picture before any actions are taken',
              fileUrl: _beforePhotoUrl,
              errorText: _beforePhotoError,
              isUploading: _isUploadingPhoto,
              onUpload: _pickAndUploadBeforePhoto,
              onRemove: () {
                setState(() => _beforePhotoUrl = null);
              },
            ),
            const SizedBox(height: 28),

            // SECTION 3: GEOLOCATION AND MAPPING
            if (!isTestMode) ...[
              Text(
                'Location Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111C2D),
                ),
              ),
              const SizedBox(height: 12),
              // Map Action Button
              FilledButton.icon(
                onPressed: _isSaving ? null : _openMapPicker,
                icon: const Icon(Icons.map, size: 20),
                label: const Text(
                  'Select Location on Map',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFBDECE2),
                  foregroundColor: const Color(0xFF416C65),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Latitude and Longitude Metadata Chips
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 560;
                final latitudeField = TextFormField(
                  controller: _latitudeController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    prefixIcon: Icon(
                      Icons.my_location,
                      color: Color(0xFF005C55),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                );
                final longitudeField = TextFormField(
                  controller: _longitudeController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    prefixIcon: Icon(Icons.explore, color: Color(0xFF005C55)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                );

                return isWide
                    ? Row(
                        children: [
                          Expanded(child: latitudeField),
                          const SizedBox(width: 16),
                          Expanded(child: longitudeField),
                        ],
                      )
                    : Column(
                        children: [
                          latitudeField,
                          const SizedBox(height: 16),
                          longitudeField,
                        ],
                      );
              },
            ),
            const SizedBox(height: 16),

            // Street Address Input
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Street Address',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 28),

            // SECTION 4: INCIDENT INFORMATION (TEXT FIELDS)
            Text(
              'Incident Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111C2D),
              ),
            ),
            const SizedBox(height: 12),

            // Report Title Field
            TextFormField(
              key: const Key('report_title_field'),
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Report Title',
                prefixIcon: Icon(Icons.edit_note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              textInputAction: TextInputAction.next,
              validator: _required,
            ),
            const SizedBox(height: 16),

            // Detailed Description Textarea
            TextFormField(
              key: const Key('report_description_field'),
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Detailed Description',
                alignLabelWithHint: true,
                hintText: 'Please describe the issue in detail...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              minLines: 4,
              maxLines: 6,
              validator: _required,
            ),
            const SizedBox(height: 28),

            // SECTION 5: PROFILE & ANONYMOUS SWITCH CARD
            if (widget.initialReport == null) ...[
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F3FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFBDC9C6).withOpacity(0.4),
                  ),
                ),
                child: SwitchListTile(
                  value: _anonymous,
                  activeColor: const Color(0xFF005C55),
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _anonymous = value),
                  title: const Text(
                    'Submit Anonymously',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111C2D),
                    ),
                  ),
                  subtitle: const Text(
                    'Your personal information will be hidden from the public timeline.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF3E4947)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // SECTION 6: ACTION FOOTER SUBMIT BUTTON
            FilledButton.icon(
              onPressed: _isSaving || _isUploadingPhoto ? null : _submit,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              label: Text(
                widget.submitLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "By submitting, you agree to the City's terms of service.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF3E4947)),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.commonRequired;
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
      return context.l10n.validationLatitudeRange;
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
      return context.l10n.validationLongitudeRange;
    }
    return null;
  }

  String? _coordinate(String? value) {
    if (_required(value) != null) {
      return context.l10n.commonRequired;
    }

    final parsed = double.tryParse(value!.trim());
    if (parsed == null) {
      return context.l10n.validationNumber;
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
    required this.onRemove,
  });

  final String label;
  final String? fileUrl;
  final String? errorText;
  final bool isUploading;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasFile = (fileUrl ?? '').trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasFile)
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFBDC9C6).withOpacity(0.5),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  fileUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Color(0xFFBA1A1A),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFFBA1A1A),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          InkWell(
            key: const Key('report_photo_upload'),
            onTap: isUploading ? null : onUpload,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBDC9C6), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isUploading
                      ? const SizedBox.square(
                          dimension: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0F766E),
                          ),
                        )
                      : const Icon(
                          Icons.add_a_photo,
                          size: 36,
                          color: Color(0xFF3E4947),
                        ),
                  const SizedBox(height: 8),
                  Text(
                    isUploading
                        ? 'Uploading proof image...'
                        : 'Add Environmental Photo',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111C2D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: const TextStyle(
              color: Color(0xFFBA1A1A),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
