import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/domain_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/ui/app_feedback.dart';
import '../../reports/data/report_api_service.dart';
import '../../reports/domain/report.dart';
import '../../tasks/data/task_api_service.dart';
import '../../tasks/domain/task.dart';
import '../../users/data/user_api_service.dart';
import '../../users/domain/app_user.dart';
import 'overseer_report_dashboard_screen.dart';

class OverseerCreateTaskScreen extends StatefulWidget {
  const OverseerCreateTaskScreen({
    super.key,
    required this.taskApiService,
    required this.reportApiService,
    required this.userApiService,
  });

  final TaskApiService taskApiService;
  final ReportApiService reportApiService;
  final UserApiService userApiService;

  @override
  State<OverseerCreateTaskScreen> createState() =>
      _OverseerCreateTaskScreenState();
}

class _OverseerCreateTaskScreenState extends State<OverseerCreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController(text: '10.7769');
  final _longitudeController = TextEditingController(text: '106.7009');
  final _addressController = TextEditingController();
  final _priorityController = TextEditingController(text: '0');
  final _reportIdsController = TextEditingController();

  ReportCategory _category = ReportCategory.roadDamage;
  Future<List<AppUser>> _staffFuture = Future<List<AppUser>>.value(
    const <AppUser>[],
  );
  OverseerTaskFormArgs? _args;
  Task? _loadedTask;
  List<Report> _linkedReports = const <Report>[];
  String? _selectedStaffId;
  String? _linkedReportsError;
  bool _didReadArgs = false;
  bool _isLoading = false;
  bool _isLoadingReports = false;
  bool _isSaving = false;

  bool get _isEditing => (_args?.taskId ?? '').isNotEmpty;

  bool get _isReportLinkedCreate =>
      !_isEditing && (_args?.reportIds.isNotEmpty ?? false);

  void _loadStaff() {
    _staffFuture = widget.userApiService.fetchStaffUsers();
  }

  Future<void> _retryLoadStaff() async {
    setState(_loadStaff);
    await _staffFuture;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArgs) {
      return;
    }
    _didReadArgs = true;
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    _args = rawArgs is OverseerTaskFormArgs
        ? rawArgs
        : rawArgs is List<String>
        ? OverseerTaskFormArgs(reportIds: rawArgs)
        : const OverseerTaskFormArgs();

    _reportIdsController.text = _args!.reportIds.join('\n');
    if (_isEditing) {
      _loadStaff();
      _loadTask(_args!.taskId!);
    } else if (_isReportLinkedCreate) {
      _loadStaff();
      _loadLinkedReports(_args!.reportIds);
    } else {
      _loadStaff();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _addressController.dispose();
    _priorityController.dispose();
    _reportIdsController.dispose();
    super.dispose();
  }

  Future<void> _loadTask(String taskId) async {
    setState(() => _isLoading = true);
    try {
      final task = await widget.taskApiService.fetchTask(taskId);
      if (!mounted) {
        return;
      }
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _category = task.category;
      _latitudeController.text = task.latitude.toString();
      _longitudeController.text = task.longitude.toString();
      _addressController.text = task.addressText ?? '';
      _priorityController.text = task.priorityScore.toString();
      _reportIdsController.text = task.reportIds.join('\n');
      _loadedTask = task;
      _selectedStaffId = task.assignedStaff?.id;
    } on TaskApiException catch (_) {
      _showError(context.l10n.taskLoadFailed);
    } catch (_) {
      _showError(context.l10n.taskLoadFailed);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLinkedReports(Iterable<String> rawReportIds) async {
    final reportIds = _cleanReportIds(rawReportIds);
    if (reportIds.isEmpty) {
      setState(() {
        _linkedReports = const <Report>[];
        _linkedReportsError = context.l10n.taskNoReportsSelected;
      });
      return;
    }

    setState(() {
      _isLoadingReports = true;
      _linkedReportsError = null;
    });

    try {
      final reports = await Future.wait(
        reportIds.map(widget.reportApiService.fetchReport),
      );
      final unavailableReports = reports
          .where((report) => report.status != ReportStatus.submitted)
          .toList(growable: false);
      if (!mounted) {
        return;
      }
      setState(() {
        _linkedReports = reports;
        if (unavailableReports.isNotEmpty) {
          _linkedReportsError = _unavailableReportsMessage(unavailableReports);
        } else {
          _linkedReportsError = null;
          _applyReportDefaults(reports);
        }
      });
    } on ReportApiException catch (_) {
      if (mounted) {
        setState(
          () => _linkedReportsError = context.l10n.taskLinkedReportsLoadFailed,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _linkedReportsError = context.l10n.taskLinkedReportsLoadFailed,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingReports = false);
      }
    }
  }

  Future<void> _retryLoadLinkedReports() async {
    await _loadLinkedReports(_args?.reportIds ?? const <String>[]);
  }

  Future<void> _openLinkedReport(Report report) async {
    FocusScope.of(context).unfocus();
    final changed = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.overseerReportDetail, arguments: report.id);
    if (!mounted) {
      return;
    }
    if (changed == true) {
      await _loadLinkedReports(_linkedReports.map((report) => report.id));
    }
  }

  void _applyReportDefaults(List<Report> reports) {
    if (reports.isEmpty) {
      return;
    }

    final anchor = _anchorReport(reports);
    _category = anchor.category;
    _latitudeController.text = anchor.latitude.toString();
    _longitudeController.text = anchor.longitude.toString();
    _addressController.text = anchor.addressText?.trim() ?? '';
    _priorityController.text = _priorityScoreForReports(reports).toString();
    _reportIdsController.text = reports.map((report) => report.id).join('\n');
  }

  Future<void> _save() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final draft = _isReportLinkedCreate && _linkedReports.isNotEmpty
        ? _draftFromLinkedReports()
        : TaskDraft(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _category,
            latitude: double.parse(_latitudeController.text.trim()),
            longitude: double.parse(_longitudeController.text.trim()),
            addressText: _nullableText(_addressController),
            priorityScore: int.parse(_priorityController.text.trim()),
            assignedStaffId: _selectedStaffId,
            staffNote: _loadedTask?.staffNote,
            reportIds: _reportIds(),
          );

    try {
      final task = _isEditing
          ? await widget.taskApiService.updateTask(_args!.taskId!, draft)
          : await widget.taskApiService.createTask(draft);
      if (!mounted) {
        return;
      }
      AppFeedback.showSuccess(
        context,
        title: _isEditing
            ? context.l10n.taskUpdatedTitle
            : context.l10n.taskCreatedTitle,
        message: task.title,
      );
      Navigator.of(context).pop(true);
    } on TaskApiException catch (_) {
      await AppFeedback.showErrorDialog(
        context,
        title: _isEditing
            ? context.l10n.taskUpdateFailedTitle
            : context.l10n.taskCreateFailedTitle,
        message: context.l10n.taskSaveFailed,
      );
    } catch (_) {
      await AppFeedback.showErrorDialog(
        context,
        title: _isEditing
            ? context.l10n.taskUpdateFailedTitle
            : context.l10n.taskCreateFailedTitle,
        message: context.l10n.taskSaveFailed,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  TaskDraft _draftFromLinkedReports() {
    final anchor = _anchorReport(_linkedReports);
    return TaskDraft(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: anchor.category,
      latitude: anchor.latitude,
      longitude: anchor.longitude,
      addressText: _nullableAddress(anchor.addressText),
      priorityScore: _priorityScoreForReports(_linkedReports),
      assignedStaffId: _selectedStaffId,
      staffNote: null,
      reportIds: _linkedReports
          .map((report) => report.id)
          .toList(growable: false),
    );
  }

  String _unavailableReportsMessage(List<Report> reports) {
    final labels = reports
        .map(
          (report) =>
              '${report.title} (${report.status.localizedLabel(context)})',
        )
        .join(', ');
    return context.l10n.taskUnavailableReports(labels);
  }

  String? _nullableText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  String? _nullableAddress(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  List<String> _reportIds() {
    return _reportIdsController.text
        .split(RegExp(r'[\s,]+'))
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  List<String> _cleanReportIds(Iterable<String> rawIds) {
    final seen = <String>{};
    final reportIds = <String>[];
    for (final rawId in rawIds) {
      final id = rawId.trim();
      if (id.isEmpty || seen.contains(id)) {
        continue;
      }
      seen.add(id);
      reportIds.add(id);
    }
    return reportIds;
  }

  Report _anchorReport(List<Report> reports) {
    return reports.reduce((best, report) {
      if (report.priorityScore != best.priorityScore) {
        return report.priorityScore > best.priorityScore ? report : best;
      }
      if (report.upvoteCount != best.upvoteCount) {
        return report.upvoteCount > best.upvoteCount ? report : best;
      }
      return report.createdAt.isAfter(best.createdAt) ? report : best;
    });
  }

  int _priorityScoreForReports(List<Report> reports) {
    return reports.fold<int>(
      0,
      (highest, report) => math.max(highest, report.priorityScore),
    );
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    AppFeedback.showError(
      context,
      title: context.l10n.commonUnexpectedErrorTitle,
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isLoading || _isLoadingReports;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          _isEditing
              ? context.l10n.taskEditTitle
              : context.l10n.taskCreateTitle,
        ),
      ),
      body: SafeArea(
        child: isBusy
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isReportLinkedCreate) {
      if (_linkedReportsError != null) {
        return _ErrorState(
          message: _linkedReportsError!,
          onRetry: _retryLoadLinkedReports,
        );
      }
      if (_linkedReports.isEmpty) {
        return _ErrorState(
          message: context.l10n.taskNoReportsSelected,
          onRetry: _retryLoadLinkedReports,
        );
      }
      return FutureBuilder<List<AppUser>>(
        future: _staffFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: context.l10n.staffUsersLoadFailed,
              onRetry: _retryLoadStaff,
            );
          }

          final staffUsers = snapshot.data ?? const <AppUser>[];
          if (staffUsers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(context.l10n.taskNoActiveStaff),
              ),
            );
          }

          final selectedStaffId =
              staffUsers.any((staff) => staff.id == _selectedStaffId)
              ? _selectedStaffId
              : null;

          return _buildLinkedReportTaskForm(
            staffUsers: staffUsers,
            selectedStaffId: selectedStaffId,
          );
        },
      );
    }

    return FutureBuilder<List<AppUser>>(
      future: _staffFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _ErrorState(
            message: context.l10n.staffUsersLoadFailed,
            onRetry: _retryLoadStaff,
          );
        }

        final staffUsers = snapshot.data ?? const <AppUser>[];
        if (staffUsers.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(context.l10n.taskNoActiveStaff),
            ),
          );
        }

        final selectedStaffId =
            staffUsers.any((staff) => staff.id == _selectedStaffId)
            ? _selectedStaffId
            : null;

        return _buildFullTaskForm(
          staffUsers: staffUsers,
          selectedStaffId: selectedStaffId,
        );
      },
    );
  }

  Widget _buildLinkedReportTaskForm({
    required List<AppUser> staffUsers,
    required String? selectedStaffId,
  }) {
    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final taskBrief = _buildLinkedTaskBrief(
            context,
            staffUsers: staffUsers,
            selectedStaffId: selectedStaffId,
          );
          final linkedReports = _buildLinkedReportsList(context);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
            children: [
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: taskBrief),
                    const SizedBox(width: 24),
                    Expanded(flex: 4, child: linkedReports),
                  ],
                )
              else ...[
                taskBrief,
                const SizedBox(height: 24),
                linkedReports,
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildLinkedTaskBrief(
    BuildContext context, {
    required List<AppUser> staffUsers,
    required String? selectedStaffId,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.taskBrief,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: context.l10n.commonTitle,
            prefixIcon: const Icon(Icons.title),
          ),
          validator: _required,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: context.l10n.commonDescription,
            prefixIcon: const Icon(Icons.notes_outlined),
          ),
          minLines: 5,
          maxLines: 8,
          validator: _required,
        ),
        const SizedBox(height: 12),
        _buildStaffPicker(
          staffUsers: staffUsers,
          selectedStaffId: selectedStaffId,
        ),
        const SizedBox(height: 16),
        _buildDerivedTaskDetails(context),
        const SizedBox(height: 20),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildDerivedTaskDetails(BuildContext context) {
    final theme = Theme.of(context);
    final anchor = _anchorReport(_linkedReports);
    final priorityScore = _priorityScoreForReports(_linkedReports);
    final hasPhoto = _linkedReports.any(
      (report) => (report.beforePhotoUrl ?? '').trim().isNotEmpty,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.taskData,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoPill(
              icon: Icons.category_outlined,
              label: anchor.category.localizedLabel(context),
              color: _categoryColor(anchor.category),
            ),
            _InfoPill(
              icon: Icons.place_outlined,
              label: _reportLocationLabel(anchor),
              color: const Color(0xFF0F766E),
            ),
            _InfoPill(
              icon: Icons.trending_up,
              label: context.l10n.priorityValue(priorityScore),
              color: const Color(0xFFE67E22),
            ),
            _InfoPill(
              icon: Icons.photo_outlined,
              label: hasPhoto
                  ? context.l10n.taskReportPhoto
                  : context.l10n.taskNoPhoto,
              color: const Color(0xFF2563EB),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLinkedReportsList(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.link_outlined, color: Color(0xFF0F766E)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.taskLinkedReports,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _CountBadge(count: _linkedReports.length),
          ],
        ),
        const SizedBox(height: 12),
        for (final report in _linkedReports) ...[
          _LinkedReportTile(
            report: report,
            onOpen: () => _openLinkedReport(report),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildStaffPicker({
    required List<AppUser> staffUsers,
    required String? selectedStaffId,
  }) {
    return DropdownButtonFormField<String>(
      value: selectedStaffId,
      decoration: InputDecoration(
        labelText: context.l10n.taskAssignedStaff,
        prefixIcon: const Icon(Icons.person_outline),
      ),
      items: staffUsers
          .map(
            (staff) => DropdownMenuItem<String>(
              value: staff.id,
              child: Text(
                '${staff.fullName} (${staff.email})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(growable: false),
      onChanged: _isSaving
          ? null
          : (staffId) {
              setState(() => _selectedStaffId = staffId);
            },
      validator: (value) {
        if ((value ?? '').isEmpty) {
          return context.l10n.commonRequired;
        }
        return null;
      },
    );
  }

  Widget _buildFullTaskForm({
    required List<AppUser> staffUsers,
    required String? selectedStaffId,
  }) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF123B38),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      _isEditing
                          ? context.l10n.commonEdit
                          : context.l10n.taskCreateTitle,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFDCE6E3)),
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: context.l10n.commonTitle,
                            prefixIcon: const Icon(Icons.title),
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: context.l10n.commonDescription,
                            prefixIcon: const Icon(Icons.notes_outlined),
                          ),
                          minLines: 3,
                          maxLines: 5,
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ReportCategory>(
                          value: _category,
                          decoration: InputDecoration(
                            labelText: context.l10n.commonCategory,
                            prefixIcon: const Icon(Icons.category_outlined),
                          ),
                          items: ReportCategory.values
                              .map(
                                (category) => DropdownMenuItem<ReportCategory>(
                                  value: category,
                                  child: Text(category.localizedLabel(context)),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFDCE6E3)),
                    ),
                    child: Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 560;
                            final latitude = TextFormField(
                              controller: _latitudeController,
                              decoration: InputDecoration(
                                labelText: context.l10n.commonLatitude,
                                prefixIcon: const Icon(
                                  Icons.my_location_outlined,
                                ),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: true,
                                    decimal: true,
                                  ),
                              validator: _latitude,
                            );
                            final longitude = TextFormField(
                              controller: _longitudeController,
                              decoration: InputDecoration(
                                labelText: context.l10n.commonLongitude,
                                prefixIcon: const Icon(Icons.explore_outlined),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: true,
                                    decimal: true,
                                  ),
                              validator: _longitude,
                            );

                            return isWide
                                ? Row(
                                    children: [
                                      Expanded(child: latitude),
                                      const SizedBox(width: 12),
                                      Expanded(child: longitude),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      latitude,
                                      const SizedBox(height: 12),
                                      longitude,
                                    ],
                                  );
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: context.l10n.commonAddress,
                            prefixIcon: const Icon(Icons.place_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _priorityController,
                          decoration: InputDecoration(
                            labelText: context.l10n.taskPriorityScore,
                            prefixIcon: const Icon(Icons.trending_up),
                          ),
                          keyboardType: TextInputType.number,
                          validator: _nonNegativeInt,
                        ),
                        const SizedBox(height: 12),
                        _buildStaffPicker(
                          staffUsers: staffUsers,
                          selectedStaffId: selectedStaffId,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _reportIdsController,
                          decoration: InputDecoration(
                            labelText: context.l10n.taskReportIds,
                            prefixIcon: const Icon(Icons.link_outlined),
                          ),
                          minLines: 2,
                          maxLines: 5,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        key: const Key('overseerTaskSubmitButton'),
        onPressed: _isSaving ? null : _save,
        icon: _isSaving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_outlined),
        label: Text(
          _isEditing ? context.l10n.commonSave : context.l10n.taskCreateTitle,
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 17),
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
    return _boundedNumber(value, min: -90, max: 90);
  }

  String? _longitude(String? value) {
    return _boundedNumber(value, min: -180, max: 180);
  }

  String? _boundedNumber(
    String? value, {
    required double min,
    required double max,
  }) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return context.l10n.commonRequired;
    }
    final parsed = double.tryParse(raw);
    if (parsed == null) {
      return context.l10n.validationNumber;
    }
    if (parsed < min || parsed > max) {
      return context.l10n.validationOutOfRange;
    }
    return null;
  }

  String? _nonNegativeInt(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return context.l10n.commonRequired;
    }
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      return context.l10n.validationWholeNumber;
    }
    if (parsed < 0) {
      return context.l10n.validationNonnegative;
    }
    return null;
  }
}

class _LinkedReportTile extends StatelessWidget {
  const _LinkedReportTile({required this.report, required this.onOpen});

  final Report report;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final categoryColor = _categoryColor(report.category);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFDCE5E3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _categoryIcon(report.category),
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            report.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(status: report.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      report.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoPill(
                          icon: Icons.category_outlined,
                          label: report.category.localizedLabel(context),
                          color: categoryColor,
                        ),
                        _InfoPill(
                          icon: Icons.place_outlined,
                          label: _reportLocationLabel(report),
                          color: const Color(0xFF0F766E),
                        ),
                        _InfoPill(
                          icon: Icons.trending_up,
                          label: context.l10n.priorityValue(
                            report.priorityScore,
                          ),
                          color: const Color(0xFFE67E22),
                        ),
                        _InfoPill(
                          icon: Icons.thumb_up_alt_outlined,
                          label: '${report.upvoteCount}',
                          color: const Color(0xFF2563EB),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.localizedLabel(context),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F3F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count.toString(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: const Color(0xFF0F766E),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

String _reportLocationLabel(Report report) {
  final address = report.addressText?.trim();
  if (address != null && address.isNotEmpty) {
    return address;
  }
  return '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}';
}

Color _categoryColor(ReportCategory category) {
  return switch (category) {
    ReportCategory.roadDamage => const Color(0xFFFF5722),
    ReportCategory.streetLight => const Color(0xFFF59E0B),
    ReportCategory.garbage => const Color(0xFF8D6E63),
    ReportCategory.waterLeak => const Color(0xFF0284C7),
    ReportCategory.drainage => const Color(0xFF0F766E),
    ReportCategory.trafficSign => const Color(0xFFDC2626),
    ReportCategory.treeBlockage => const Color(0xFF2E7D32),
    ReportCategory.other => const Color(0xFF607D8B),
  };
}

Color _statusColor(ReportStatus status) {
  return switch (status) {
    ReportStatus.submitted => const Color(0xFFE91E63),
    ReportStatus.inProgress => const Color(0xFFB45309),
    ReportStatus.fixed => const Color(0xFF0F766E),
    ReportStatus.cancelled => const Color(0xFF78909C),
  };
}

IconData _categoryIcon(ReportCategory category) {
  return switch (category) {
    ReportCategory.roadDamage => Icons.construction,
    ReportCategory.streetLight => Icons.lightbulb_outline,
    ReportCategory.garbage => Icons.delete_outline,
    ReportCategory.waterLeak => Icons.water_drop_outlined,
    ReportCategory.drainage => Icons.waves_outlined,
    ReportCategory.trafficSign => Icons.traffic_outlined,
    ReportCategory.treeBlockage => Icons.park,
    ReportCategory.other => Icons.help_outline,
  };
}
