import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/domain_localizations.dart';
import '../../auth/domain/current_user.dart';
import '../data/user_api_service.dart';
import '../domain/app_user.dart';

class OverseerCreateUserScreen extends StatefulWidget {
  const OverseerCreateUserScreen({super.key, required this.userApiService});

  final UserApiService userApiService;

  @override
  State<OverseerCreateUserScreen> createState() =>
      _OverseerCreateUserScreenState();
}

class _OverseerCreateUserScreenState extends State<OverseerCreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  UserRole _role = UserRole.staff;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final user = await widget.userApiService.createUser(
        UserDraft(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _role,
        ),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.userCreated(user.fullName))),
      );
      Navigator.of(context).pop(true);
    } on UserApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = context.l10n.userCreateFailed;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.commonRequired;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.userCreateTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      labelText: context.l10n.commonFullName,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: context.l10n.commonEmail,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final message = _required(value);
                      if (message != null) {
                        return message;
                      }
                      if (!value!.contains('@')) {
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
                    ),
                    obscureText: true,
                    validator: (value) {
                      final message = _required(value);
                      if (message != null) {
                        return message;
                      }
                      if (value!.length < 6) {
                        return context.l10n.userPasswordMinLength(6);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    value: _role,
                    decoration: InputDecoration(
                      labelText: context.l10n.commonRole,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: UserRole.staff,
                        child: Text(UserRole.staff.localizedLabel(context)),
                      ),
                      DropdownMenuItem(
                        value: UserRole.overseer,
                        child: Text(UserRole.overseer.localizedLabel(context)),
                      ),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _role = value;
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.l10n.userCreateTitle),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
