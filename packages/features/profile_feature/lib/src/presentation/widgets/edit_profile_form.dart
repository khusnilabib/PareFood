/// Edit-profile form: name, phone and avatar (F2, PF-DOC-11 §3.1
/// presentation layer). Phone changes go through OTP re-verification
/// (FR-AUTH-005).
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../application/profile_providers.dart';
import '../../domain/user_profile.dart';

/// Form bound to [updateProfileProvider] and the avatar upload.
class EditProfileForm extends ConsumerStatefulWidget {
  const EditProfileForm({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _newPhoneController;
  late final TextEditingController _phoneOtpController;
  Uint8List? _avatarBytes;
  String? _avatarName;
  bool _submitting = false;
  bool _uploadingAvatar = false;
  bool _changingPhone = false;
  bool _phoneOtpSent = false;
  bool _sendingOtp = false;
  bool _verifyingPhone = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _phoneController = TextEditingController(text: widget.profile.phone);
    _newPhoneController = TextEditingController();
    _phoneOtpController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _newPhoneController.dispose();
    _phoneOtpController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _avatarBytes = bytes;
      _avatarName = picked.name;
    });
  }

  Future<void> _saveAvatar() async {
    final bytes = _avatarBytes;
    final name = _avatarName;
    if (bytes == null || name == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateAvatar(bytes: bytes, fileName: name);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Foto profil diperbarui.')));
      ref.invalidate(profileProvider);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal mengunggah foto.')));
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      // Phone is immutable here: changes go through the OTP flow below
      // (FR-AUTH-005), so only the name is submitted.
      await ref
          .read(updateProfileProvider)
          .call(name: _nameController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil disimpan.')));
      Navigator.of(context).pop();
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _startPhoneChange() {
    setState(() {
      _changingPhone = true;
      _phoneOtpSent = false;
      _newPhoneController.clear();
      _phoneOtpController.clear();
    });
  }

  void _cancelPhoneChange() {
    setState(() {
      _changingPhone = false;
      _phoneOtpSent = false;
      _newPhoneController.clear();
      _phoneOtpController.clear();
    });
  }

  Future<void> _sendPhoneOtp() async {
    final useCase = ref.read(requestPhoneChangeProvider);
    final phone = _newPhoneController.text.trim();
    final error = useCase.validate(phone);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _sendingOtp = true);
    try {
      await useCase.call(phone);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kode OTP terkirim.')));
      setState(() => _phoneOtpSent = true);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim kode OTP. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  Future<void> _resendPhoneOtp() async {
    try {
      await ref
          .read(resendPhoneChangeOtpProvider)
          .call(_newPhoneController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kode OTP terkirim.')));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim kode OTP. Coba lagi.')),
      );
    }
  }

  Future<void> _verifyPhoneChange() async {
    final useCase = ref.read(verifyPhoneChangeProvider);
    final token = _phoneOtpController.text.trim();
    final error = useCase.validate(token);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _verifyingPhone = true);
    try {
      final updated = await useCase.call(
        newPhone: _newPhoneController.text.trim(),
        token: token,
      );
      if (!mounted) return;
      _phoneController.text = updated.phone;
      ref.invalidate(profileProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nomor HP diperbarui.')));
      setState(() {
        _changingPhone = false;
        _phoneOtpSent = false;
      });
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verifikasi gagal. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _verifyingPhone = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 40,
                  foregroundImage: _avatarBytes == null
                      ? (widget.profile.avatarUrl == null
                            ? null
                            : NetworkImage(widget.profile.avatarUrl!))
                      : MemoryImage(_avatarBytes!),
                  child: Text(
                    widget.profile.name.characters.first.toUpperCase(),
                  ),
                ),
                IconButton.filled(
                  onPressed: _uploadingAvatar ? null : _pickAvatar,
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  tooltip: 'Ganti foto profil',
                ),
              ],
            ),
          ),
          if (_avatarBytes != null) ...[
            const SizedBox(height: PfSpacing.xs),
            Align(
              child: TextButton(
                onPressed: _uploadingAvatar ? null : _saveAvatar,
                child: _uploadingAvatar
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan foto'),
              ),
            ),
          ],
          const SizedBox(height: PfSpacing.lg),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nama'),
            validator: requiredValidator,
          ),
          const SizedBox(height: PfSpacing.md),
          TextFormField(
            controller: _phoneController,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Telepon'),
            keyboardType: TextInputType.phone,
          ),
          if (!_changingPhone)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _startPhoneChange,
                child: const Text('Ganti nomor HP'),
              ),
            )
          else ...[
            const SizedBox(height: PfSpacing.sm),
            TextFormField(
              controller: _newPhoneController,
              enabled: !_phoneOtpSent,
              decoration: const InputDecoration(labelText: 'Nomor HP baru'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: PfSpacing.sm),
            if (!_phoneOtpSent)
              PfButton(
                label: 'Kirim kode OTP',
                onPressed: _sendingOtp ? null : _sendPhoneOtp,
                isLoading: _sendingOtp,
              )
            else ...[
              TextFormField(
                controller: _phoneOtpController,
                decoration: const InputDecoration(labelText: 'Kode OTP'),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              const SizedBox(height: PfSpacing.sm),
              PfButton(
                label: 'Verifikasi nomor',
                onPressed: _verifyingPhone ? null : _verifyPhoneChange,
                isLoading: _verifyingPhone,
              ),
              const SizedBox(height: PfSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _resendPhoneOtp,
                    child: const Text('Kirim ulang kode'),
                  ),
                  TextButton(
                    onPressed: _cancelPhoneChange,
                    child: const Text('Batal'),
                  ),
                ],
              ),
            ],
          ],
          const SizedBox(height: PfSpacing.lg),
          PfButton(
            label: 'Simpan perubahan',
            onPressed: _submitting ? null : _submit,
            isLoading: _submitting,
          ),
        ],
      ),
    );
  }
}
