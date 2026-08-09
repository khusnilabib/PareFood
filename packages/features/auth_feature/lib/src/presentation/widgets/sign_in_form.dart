/// Sign-in form widget (PF-DOC-11 §3.1 presentation layer).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../application/auth_providers.dart';

/// Email/password form bound to [signInUseCaseProvider].
class SignInForm extends ConsumerStatefulWidget {
  const SignInForm({super.key});

  @override
  ConsumerState<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(signInUseCaseProvider)
          .call(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Berhasil masuk.')));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal masuk. Coba lagi.')));
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
            validator: emailValidator,
          ),
          const SizedBox(height: PfSpacing.md),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Kata sandi'),
            obscureText: true,
            validator: (value) => minLengthValidator(value, minLength: 8),
          ),
          const SizedBox(height: PfSpacing.lg),
          PfButton(
            label: 'Masuk',
            onPressed: _submitting ? null : _submit,
            isLoading: _submitting,
          ),
        ],
      ),
    );
  }
}
