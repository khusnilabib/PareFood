/// Sign-in page (PF-DOC-11 §3.1 presentation/pages). Routes are registered in
/// the app shell.
library;

import 'package:flutter/material.dart';
import 'package:pare_design/pare_design.dart';

import '../widgets/phone_sign_in_form.dart';
import '../widgets/sign_in_form.dart';
import 'register_page.dart';

/// How the user signs in: email/password or phone OTP (FR-AUTH-001).
enum SignInMode { email, phone }

/// Scoped sign-in entry point.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  SignInMode _mode = SignInMode.email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Masuk')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PfSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Selamat datang di PareFood',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: PfSpacing.md),
              SegmentedButton<SignInMode>(
                segments: const [
                  ButtonSegment(value: SignInMode.email, label: Text('Email')),
                  ButtonSegment(
                    value: SignInMode.phone,
                    label: Text('Nomor HP'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) {
                  setState(() => _mode = selection.first);
                },
              ),
              const SizedBox(height: PfSpacing.md),
              if (_mode == SignInMode.email)
                const SignInForm()
              else
                const PhoneSignInForm(),
              const SizedBox(height: PfSpacing.lg),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RegisterPage(),
                    ),
                  );
                },
                child: const Text('Belum punya akun? Daftar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
