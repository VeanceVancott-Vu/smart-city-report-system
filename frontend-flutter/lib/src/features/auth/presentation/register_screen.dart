import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/language_menu_button.dart';
import '../../../core/routing/app_routes.dart';
import '../data/auth_api_service.dart';
import '../domain/current_user.dart';

final logger = Logger();

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.authApiService});

  final AuthApiService authApiService;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    try {
      final session = await widget.authApiService.register(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }

      debugPrint('Full Session details: ${session.toString()}');

      _navigateForRole(session.user.role);
    } on AuthException catch (error) {
      debugPrint('❌ AuthException: ${error.message}');
      if (mounted) {
        _showError(context.l10n.authRegistrationFailed);
      }
    } catch (e, stackTrace) {
      // Capture the generic error 'e' instead of using '_'
      logger.e('Failed to register user', error: e, stackTrace: stackTrace);
      if (mounted) {
        _showError(context.l10n.authRegistrationFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _errorMessage = message);
  }

  void _navigateForRole(UserRole role) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(_routeForRole(role), (_) => false);
  }

  String _routeForRole(UserRole role) {
    return switch (role) {
      UserRole.citizen => AppRoutes.citizenHome,
      UserRole.staff => AppRoutes.staffHome,
      UserRole.overseer => AppRoutes.overseerHome,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.authCreateAccountTitle),
        actions: const [LanguageMenuButton()],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: context.l10n.commonFullName,
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      validator: (value) {
                        if ((value?.trim() ?? '').isEmpty) {
                          return context.l10n.authFullNameRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: context.l10n.commonEmail,
                        prefixIcon: const Icon(Icons.mail_outline),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) {
                          return context.l10n.authEmailRequired;
                        }
                        if (!email.contains('@')) {
                          return context.l10n.authEmailInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: context.l10n.commonPassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (value) {
                        final password = value ?? '';
                        if (password.isEmpty) {
                          return context.l10n.authPasswordRequired;
                        }
                        if (password.length < 8) {
                          return context.l10n.authPasswordMinLength(8);
                        }
                        return null;
                      },
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _register,
                      icon: _isSubmitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_add_alt_1),
                      label: Text(context.l10n.authCreateAccountButton),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(context.l10n.authBackToLogin),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
