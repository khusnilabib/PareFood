/// Forgot-password page (PF-DOC-11 §3.1 presentation/pages). Routes are
/// registered in the app shell.
library;

import 'package:flutter/material.dart';
import 'package:pare_design/pare_design.dart';

import '../widgets/forgot_password_form.dart';

/// Entry point for requesting a password reset email (FR-AUTH-005).
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lupa kata sandi')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PfSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Masukkan email terdaftar Anda',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: PfSpacing.md),
              Text(
                'Kami akan mengirimkan tautan untuk mengatur ulang kata sandi Anda.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: PfSpacing.lg),
              const ForgotPasswordForm(),
            ],
          ),
        ),
      ),
    );
  }
}
