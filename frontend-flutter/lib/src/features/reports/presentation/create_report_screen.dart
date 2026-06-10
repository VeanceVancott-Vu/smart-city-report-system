import 'package:flutter/material.dart';

import '../data/report_api_service.dart';
import '../domain/report.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key, required this.reportApiService});

  final ReportApiService reportApiService;

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController(text: '10.7769');
  final _longitudeController = TextEditingController(text: '106.7009');

  ReportCategory _category = ReportCategory.road;
  String _photoLabel = 'photo_placeholder.jpg';
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final report = await widget.reportApiService.createReport(
      NewReportRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        latitude: double.parse(_latitudeController.text.trim()),
        longitude: double.parse(_longitudeController.text.trim()),
        photoLabel: _photoLabel,
      ),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${report.id} created')));
    Navigator.of(context).pop();
  }

  void _selectPlaceholderPhoto() {
    setState(() {
      _photoLabel = _photoLabel == 'photo_placeholder.jpg'
          ? 'selected_photo_placeholder.jpg'
          : 'photo_placeholder.jpg';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Report')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
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
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ),
                    )
                    .toList(),
                onChanged: (category) {
                  if (category != null) {
                    setState(() => _category = category);
                  }
                },
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 560;
                  final latitudeField = TextFormField(
                    controller: _latitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      prefixIcon: Icon(Icons.my_location_outlined),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: true,
                    ),
                    validator: _coordinate,
                  );
                  final longitudeField = TextFormField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      prefixIcon: Icon(Icons.explore_outlined),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: true,
                    ),
                    validator: _coordinate,
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
              OutlinedButton.icon(
                onPressed: _selectPlaceholderPhoto,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(_photoLabel),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: const Text('Submit'),
              ),
            ],
          ),
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
