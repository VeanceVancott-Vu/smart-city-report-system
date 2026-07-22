import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../data/user_api_service.dart';
import '../domain/app_user.dart';

class StaffPublicProfileScreen extends StatefulWidget {
  const StaffPublicProfileScreen({super.key, required this.userApiService});

  final UserApiService userApiService;

  @override
  State<StaffPublicProfileScreen> createState() =>
      _StaffPublicProfileScreenState();
}

class _StaffPublicProfileScreenState extends State<StaffPublicProfileScreen> {
  Future<StaffPublicProfile>? _profileFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileFuture ??= widget.userApiService.fetchStaffPublicProfile(
      ModalRoute.of(context)!.settings.arguments! as String,
    );
  }

  void _retry() {
    final staffId = ModalRoute.of(context)!.settings.arguments! as String;
    setState(() {
      _profileFuture = widget.userApiService.fetchStaffPublicProfile(staffId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.staffProfileTitle)),
      body: FutureBuilder<StaffPublicProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_off_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.staffProfileLoadFailed,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: Text(context.l10n.commonRetry),
                    ),
                  ],
                ),
              ),
            );
          }

          final staff = snapshot.requireData;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 42,
                            child: Text(
                              _initials(staff.fullName),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            staff.fullName,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(context.l10n.roleStaff),
                          const SizedBox(height: 24),
                          const Divider(height: 1),
                          const SizedBox(height: 18),
                          _PublicDetailRow(
                            icon: Icons.email_outlined,
                            label: context.l10n.profileEmail,
                            value: staff.email,
                          ),
                          const SizedBox(height: 16),
                          _PublicDetailRow(
                            icon: Icons.badge_outlined,
                            label: context.l10n.profileAccountStatus,
                            value: staff.active
                                ? context.l10n.profileActive
                                : context.l10n.profileInactive,
                          ),
                          const SizedBox(height: 16),
                          _PublicDetailRow(
                            icon: Icons.calendar_today_outlined,
                            label: context.l10n.profileMemberSince,
                            value: _dateLabel(staff.createdAt),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PublicDetailRow extends StatelessWidget {
  const _PublicDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

String _initials(String fullName) {
  return fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
}

String _dateLabel(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
