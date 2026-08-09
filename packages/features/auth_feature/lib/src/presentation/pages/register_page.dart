/// Registration page (PF-DOC-11 §3.1 presentation/pages). Routes are
/// registered in the app shell.
library;

import 'package:flutter/material.dart';
import 'package:pare_design/pare_design.dart';

import '../widgets/register_form.dart';

/// Scoped registration entry point (FR-AUTH-001).
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PfSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Buat akun PareFood',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: PfSpacing.md),
              const RegisterForm(),
            ],
          ),
        ),
      ),
    );
  }
}
