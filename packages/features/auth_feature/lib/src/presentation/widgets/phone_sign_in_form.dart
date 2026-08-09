/// Phone OTP sign-in form (PF-DOC-11 §3.1 presentation layer, FR-AUTH-001).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../application/auth_providers.dart';

/// Two-step phone sign-in: request an SMS code, then verify it.
class PhoneSignInForm extends ConsumerStatefulWidget {
  const PhoneSignInForm({super.key});

  @override
  ConsumerState<PhoneSignInForm> createState() => _PhoneSignInFormState();
}

class _PhoneSignInFormState extends ConsumerState<PhoneSignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _submitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(sendPhoneOtpProvider)
          .call(phone: _phoneController.text.trim());
      if (!mounted) return;
      setState(() => _otpSent = true);
      _showSnackBar('Kode OTP terkirim.');
    } on Object {
      if (!mounted) return;
      _showSnackBar('Gagal mengirim kode OTP. Coba lagi.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(verifyPhoneOtpProvider)
          .call(
            phone: _phoneController.text.trim(),
            token: _otpController.text.trim(),
          );
      if (!mounted) return;
      _showSnackBar('Berhasil masuk.');
    } on Object {
      if (!mounted) return;
      _showSnackBar('Verifikasi gagal. Coba lagi.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _backToPhoneStep() {
    setState(() {
      _otpSent = false;
      _otpController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Nomor HP',
              hintText: '081234567890',
            ),
            keyboardType: TextInputType.phone,
            enabled: !_otpSent,
            validator: (value) =>
                requiredValidator(value) ?? phoneValidator(value),
          ),
          if (!_otpSent) ...[
            const SizedBox(height: PfSpacing.lg),
            PfButton(
              label: 'Kirim kode OTP',
              onPressed: _submitting ? null : _sendOtp,
              isLoading: _submitting,
            ),
          ],
          if (_otpSent) ...[
            const SizedBox(height: PfSpacing.md),
            TextFormField(
              controller: _otpController,
              decoration: const InputDecoration(labelText: 'Kode OTP'),
              keyboardType: TextInputType.number,
              maxLength: 6,
              validator: (value) =>
                  requiredValidator(value) ?? otpValidator(value),
            ),
            const SizedBox(height: PfSpacing.md),
            PfButton(
              label: 'Verifikasi',
              onPressed: _submitting ? null : _verify,
              isLoading: _submitting,
            ),
            const SizedBox(height: PfSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _submitting ? null : _sendOtp,
                  child: const Text('Kirim ulang kode'),
                ),
                TextButton(
                  onPressed: _submitting ? null : _backToPhoneStep,
                  child: const Text('Ganti nomor'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
