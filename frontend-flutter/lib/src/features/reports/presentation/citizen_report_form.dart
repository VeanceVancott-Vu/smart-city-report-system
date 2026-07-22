import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/files/upload_file_picker.dart';
import '../../../core/files/uploaded_photo_view.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: _formKey,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            FocusScope.of(context).unfocus();
          }
          return false;
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 680;

            return ListView(
              key: const Key('report_form_list'),
              primary: false,
              controller: _scrollController,
              cacheExtent: 1000,
              padding: EdgeInsets.all(isWide ? 28 : 18),
              children: [
                Text(
                  widget.initialReport == null
                      ? context.l10n.reportFormCreateHeading
                      : context.l10n.reportFormEditHeading,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.reportFormDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),

                _FormSection(
                  step: '1',
                  title: context.l10n.reportFormCategoryTitle,
                  description: context.l10n.reportFormCategoryDescription,
                  child: LayoutBuilder(
                    builder: (context, sectionConstraints) {
                      final columns = sectionConstraints.maxWidth >= 620
                          ? 4
                          : 2;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 104,
                        ),
                        itemCount: ReportCategory.values.length,
                        itemBuilder: (context, index) {
                          final currentCat = ReportCategory.values[index];
                          final isSelected = _category == currentCat;

                          return InkWell(
                            onTap: _isSaving
                                ? null
                                : () => setState(() => _category = currentCat),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primaryContainer
                                    : colorScheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.outlineVariant,
                                  width: isSelected ? 1.6 : 1,
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getCategoryIconLocal(currentCat),
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                    size: 26,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currentCat.localizedLabel(context),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: isSelected
                                              ? colorScheme.onPrimaryContainer
                                              : colorScheme.onSurface,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),

                _FormSection(
                  step: '2',
                  title: context.l10n.reportFormPhotoTitle,
                  description: context.l10n.reportFormPhotoDescription,
                  trailing: Text(
                    _beforePhotoUrl != null
                        ? context.l10n.reportPhotoAddedCount(1, 1)
                        : context.l10n.commonRequired,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: _beforePhotoUrl != null
                          ? colorScheme.primary
                          : colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: _PhotoUploadField(
                    label: context.l10n.reportBeforePhotoHelp,
                    fileUrl: _beforePhotoUrl,
                    errorText: _beforePhotoError,
                    isUploading: _isUploadingPhoto,
                    onUpload: _pickAndUploadBeforePhoto,
                    onRemove: () => setState(() => _beforePhotoUrl = null),
                  ),
                ),
                const SizedBox(height: 18),

                _FormSection(
                  step: '3',
                  title: context.l10n.commonLocation,
                  description: context.l10n.reportFormLocationDescription,
                  child: Column(
                    children: [
                      if (!isTestMode) ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: _isSaving ? null : _openMapPicker,
                            icon: const Icon(Icons.map_outlined),
                            label: Text(context.l10n.reportSelectLocationMap),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: context.l10n.reportStreetAddress,
                          hintText: context.l10n.reportStreetAddressHint,
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, fieldConstraints) {
                          final horizontal = fieldConstraints.maxWidth >= 520;
                          final latitudeField = TextFormField(
                            controller: _latitudeController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: context.l10n.commonLatitude,
                              prefixIcon: const Icon(
                                Icons.my_location_outlined,
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          );
                          final longitudeField = TextFormField(
                            controller: _longitudeController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: context.l10n.commonLongitude,
                              prefixIcon: const Icon(Icons.explore_outlined),
                              border: const OutlineInputBorder(),
                            ),
                          );

                          return horizontal
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
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                _FormSection(
                  step: '4',
                  title: context.l10n.reportDetailsTitle,
                  description: context.l10n.reportFormDetailsDescription,
                  child: Column(
                    children: [
                      TextFormField(
                        key: const Key('report_title_field'),
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: context.l10n.reportFormTitleLabel,
                          hintText: context.l10n.reportFormTitleHint,
                          prefixIcon: const Icon(Icons.title_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: _required,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('report_description_field'),
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: context.l10n.commonDescription,
                          alignLabelWithHint: true,
                          hintText: context.l10n.reportFormDescriptionHint,
                          border: const OutlineInputBorder(),
                        ),
                        minLines: 5,
                        maxLines: 7,
                        validator: _required,
                      ),
                    ],
                  ),
                ),

                if (widget.initialReport == null) ...[
                  const SizedBox(height: 18),
                  _FormSection(
                    step: '5',
                    title: context.l10n.reportPrivacyTitle,
                    description: context.l10n.reportPrivacyDescription,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: SwitchListTile(
                        value: _anonymous,
                        onChanged: _isSaving
                            ? null
                            : (value) => setState(() => _anonymous = value),
                        secondary: Icon(
                          _anonymous
                              ? Icons.visibility_off_outlined
                              : Icons.account_circle_outlined,
                        ),
                        title: Text(context.l10n.reportSubmitAnonymously),
                        subtitle: Text(context.l10n.reportAnonymousHelp),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const Key('report_submit_button'),
                          onPressed: _isSaving || _isUploadingPhoto
                              ? null
                              : _submit,
                          icon: _isSaving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_outlined),
                          label: Text(widget.submitLabel),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.l10n.reportReviewBeforeSubmit,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
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

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.step,
    required this.title,
    required this.description,
    required this.child,
    this.trailing,
  });

  final String step;
  final String title;
  final String description;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  step,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasFile)
          Container(
            width: double.infinity,
            height: 230,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                UploadedPhotoImage(
                  fileUrl: fileUrl!,
                  fit: BoxFit.cover,
                  errorWidget: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: colorScheme.error,
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Material(
                    color: colorScheme.surface.withOpacity(0.94),
                    borderRadius: BorderRadius.circular(12),
                    child: IconButton(
                      tooltip: context.l10n.photoRemove,
                      onPressed: onRemove,
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Material(
                    color: colorScheme.surface.withOpacity(0.94),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: isUploading ? null : onUpload,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.refresh, size: 17),
                            const SizedBox(width: 6),
                            Text(context.l10n.photoReplace),
                          ],
                        ),
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
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: errorText != null
                      ? colorScheme.error
                      : colorScheme.outlineVariant,
                  width: 1.4,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: isUploading
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.add_a_photo_outlined,
                            color: colorScheme.onPrimaryContainer,
                            size: 27,
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isUploading
                        ? context.l10n.photoUploading
                        : context.l10n.photoAdd,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
