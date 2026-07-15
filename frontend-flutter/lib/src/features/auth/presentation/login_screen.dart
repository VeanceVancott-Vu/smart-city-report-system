import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/language_menu_button.dart';
import '../../../core/routing/app_routes.dart';
import '../data/auth_api_service.dart';
import '../domain/current_user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authApiService});

  final AuthApiService authApiService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isCheckingSession = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSession());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _restoreSession() async {
    try {
      final user = await widget.authApiService.getCurrentUser();
      if (!mounted) {
        return;
      }
      if (user != null) {
        _navigateForRole(user.role);
        return;
      }
    } catch (_) {
      // A failed restore should leave the user on the login form.
    }

    if (mounted) {
      setState(() => _isCheckingSession = false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    try {
      final session = await widget.authApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      _navigateForRole(session.user.role);
    } on AuthException {
      if (mounted) {
        _showError(context.l10n.authLoginFailed);
      }
    } catch (_) {
      if (mounted) {
        _showError(context.l10n.authLoginFailed);
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
      appBar: AppBar(actions: const [LanguageMenuButton()]),
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
                    Icon(
                      Icons.location_city,
                      size: 56,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.appTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 28),
                    if (_isCheckingSession)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: context.l10n.commonEmail,
                          prefixIcon: const Icon(Icons.mail_outline),
                        ),
                        keyboardType: TextInputType.emailAddress,
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
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _login(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.l10n.authPasswordRequired;
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
                        onPressed: _isSubmitting ? null : _login,
                        icon: _isSubmitting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login),
                        label: Text(context.l10n.authLoginButton),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.register),
                        child: Text(context.l10n.authCreateAccountButton),
                      ),
                    ],
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
