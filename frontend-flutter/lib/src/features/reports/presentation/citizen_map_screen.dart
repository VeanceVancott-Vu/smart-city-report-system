import 'package:flutter/material.dart';

import '../data/report_api_service.dart';
import '../domain/report.dart';

class CitizenMapScreen extends StatefulWidget {
  const CitizenMapScreen({super.key, required this.reportApiService});

  final ReportApiService reportApiService;

  @override
  State<CitizenMapScreen> createState() => _CitizenMapScreenState();
}

class _CitizenMapScreenState extends State<CitizenMapScreen> {
  final _boundsFormKey = GlobalKey<FormState>();
  final _minLatController = TextEditingController(text: '10.60');
  final _minLngController = TextEditingController(text: '106.50');
  final _maxLatController = TextEditingController(text: '10.95');
  final _maxLngController = TextEditingController(text: '106.90');
  final Set<String> _upvotedReportIds = <String>{};

  late Future<List<ReportMapPin>> _pinsFuture;
  List<ReportMapPin> _pins = const <ReportMapPin>[];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pinsFuture = _loadPins();
  }

  @override
  void dispose() {
    _minLatController.dispose();
    _minLngController.dispose();
    _maxLatController.dispose();
    _maxLngController.dispose();
    super.dispose();
  }

  Future<List<ReportMapPin>> _loadPins() async {
    final pins = await widget.reportApiService.fetchMapPins(
      minLat: double.parse(_minLatController.text.trim()),
      minLng: double.parse(_minLngController.text.trim()),
      maxLat: double.parse(_maxLatController.text.trim()),
      maxLng: double.parse(_maxLngController.text.trim()),
    );
    _pins = pins;
    return pins;
  }

  Future<void> refresh() async {
    if (!_boundsFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _errorMessage = null;
      _pinsFuture = _loadPins();
    });
    await _pinsFuture;
  }

  Future<void> _toggleUpvote(ReportMapPin pin) async {
    try {
      final summary = _upvotedReportIds.contains(pin.id)
          ? await widget.reportApiService.removeUpvote(pin.id)
          : await widget.reportApiService.upvoteReport(pin.id);

      if (!mounted) {
        return;
      }

      setState(() {
        if (summary.hasUpvoted) {
          _upvotedReportIds.add(pin.id);
        } else {
          _upvotedReportIds.remove(pin.id);
        }

        _pins = _pins
            .map(
              (item) => item.id == pin.id
                  ? item.copyWith(
                      upvoteCount: summary.upvoteCount,
                      priorityScore: summary.priorityScore,
                    )
                  : item,
            )
            .toList(growable: false);
        _pinsFuture = Future<List<ReportMapPin>>.value(_pins);
      });
    } on ReportApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to update upvote.');
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _errorMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BoundsForm(
          formKey: _boundsFormKey,
          minLatController: _minLatController,
          minLngController: _minLngController,
          maxLatController: _maxLatController,
          maxLngController: _maxLngController,
          onApply: refresh,
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        Expanded(
          child: FutureBuilder<List<ReportMapPin>>(
            future: _pinsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _ErrorState(
                  message: 'Unable to load open report pins.',
                  onRetry: refresh,
                );
              }

              final pins = snapshot.data ?? const <ReportMapPin>[];
              if (pins.isEmpty) {
                return RefreshIndicator(
                  onRefresh: refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: const [
                      SizedBox(height: 96),
                      Center(child: Text('No open report pins in bounds')),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: pins.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _PinTile(
                    pin: pins[index],
                    hasUpvoted: _upvotedReportIds.contains(pins[index].id),
                    onUpvote: () => _toggleUpvote(pins[index]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BoundsForm extends StatelessWidget {
  const _BoundsForm({
    required this.formKey,
    required this.minLatController,
    required this.minLngController,
    required this.maxLatController,
    required this.maxLngController,
    required this.onApply,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController minLatController;
  final TextEditingController minLngController;
  final TextEditingController maxLatController;
  final TextEditingController maxLngController;
  final Future<void> Function() onApply;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 640;
                final fields = [
                  _BoundsField(
                    controller: minLatController,
                    label: 'Min lat',
                    validator: _latitude,
                  ),
                  _BoundsField(
                    controller: minLngController,
                    label: 'Min lng',
                    validator: _longitude,
                  ),
                  _BoundsField(
                    controller: maxLatController,
                    label: 'Max lat',
                    validator: _latitude,
                  ),
                  _BoundsField(
                    controller: maxLngController,
                    label: 'Max lng',
                    validator: _longitude,
                  ),
                ];

                if (!isWide) {
                  return Column(
                    children: fields
                        .map(
                          (field) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: field,
                          ),
                        )
                        .toList(growable: false),
                  );
                }

                return Row(
                  children: fields
                      .map(
                        (field) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: field,
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onApply,
                icon: const Icon(Icons.search),
                label: const Text('Apply bounds'),
              ),
            ),
          ],
        ),
      ),
    );
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
      return 'Required';
    }
    final parsed = double.tryParse(raw);
    if (parsed == null) {
      return 'Use a number';
    }
    if (parsed < min || parsed > max) {
      return 'Out of range';
    }
    return null;
  }
}

class _BoundsField extends StatelessWidget {
  const _BoundsField({
    required this.controller,
    required this.label,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      validator: validator,
    );
  }
}

class _PinTile extends StatelessWidget {
  const _PinTile({
    required this.pin,
    required this.hasUpvoted,
    required this.onUpvote,
  });

  final ReportMapPin pin;
  final bool hasUpvoted;
  final VoidCallback onUpvote;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFDDE5E2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    pin.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(pin.category.label),
                  side: BorderSide.none,
                  backgroundColor: const Color(0xFFE2F3EE),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                  icon: Icons.place_outlined,
                  label:
                      '${pin.latitude.toStringAsFixed(4)}, ${pin.longitude.toStringAsFixed(4)}',
                ),
                _MetaChip(
                  icon: Icons.thumb_up_alt_outlined,
                  label: '${pin.upvoteCount} upvotes',
                ),
                _MetaChip(
                  icon: Icons.trending_up,
                  label: 'Priority ${pin.priorityScore}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onUpvote,
                icon: Icon(
                  hasUpvoted
                      ? Icons.thumb_down_alt_outlined
                      : Icons.thumb_up_alt_outlined,
                ),
                label: Text(hasUpvoted ? 'Remove upvote' : 'I see this too'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16),
      label: Text(label),
      side: const BorderSide(color: Color(0xFFDDE5E2)),
      backgroundColor: Colors.white,
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
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
