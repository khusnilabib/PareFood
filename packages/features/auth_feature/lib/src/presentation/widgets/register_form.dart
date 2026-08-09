/// Registration form widget (PF-DOC-11 §3.1 presentation layer).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../application/auth_providers.dart';
import '../../data/auth_repository.dart';

/// Email/password registration bound to [signUpUseCaseProvider]
/// (FR-AUTH-001).
class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final useCase = ref.read(signUpUseCaseProvider);

    final error = useCase.validate(
      email: email,
      password: password,
      confirmPassword: _confirmController.text,
    );
    if (error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _submitting = true);
    try {
      final outcome = await useCase.call(email: email, password: password);
      if (!mounted) return;
      final message = switch (outcome) {
        AuthOutcome.success =>
          'Pendaftaran berhasil. Cek email Anda untuk verifikasi.',
        AuthOutcome.emailInUse => 'Email sudah terdaftar.',
        _ => 'Pendaftaran gagal. Coba lagi.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendaftaran gagal. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            validator: (value) =>
                requiredValidator(value) ?? emailValidator(value),
          ),
          const SizedBox(height: PfSpacing.md),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Kata sandi'),
            obscureText: true,
            validator: (value) =>
                requiredValidator(value) ??
                minLengthValidator(value, minLength: 8),
          ),
          const SizedBox(height: PfSpacing.md),
          TextFormField(
            controller: _confirmController,
            decoration: const InputDecoration(
              labelText: 'Konfirmasi kata sandi',
            ),
            obscureText: true,
            validator: requiredValidator,
          ),
          const SizedBox(height: PfSpacing.lg),
          PfButton(
            label: 'Daftar',
            onPressed: _submitting ? null : _submit,
            isLoading: _submitting,
          ),
        ],
      ),
    );
  }
}
