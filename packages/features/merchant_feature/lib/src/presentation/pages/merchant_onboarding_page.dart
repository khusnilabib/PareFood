/// Merchant onboarding wizard (FR-ONB-001, PF-DOC-11 §3.1 presentation).
///
/// Collects business info, location, opening hours and KTP/NIB documents, then
/// submits them through [restaurantRepositoryProvider] in one flow.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../application/restaurant_providers.dart';
import 'merchant_status_page.dart';

/// A picked verification document.
class _MerchantDocument {
  _MerchantDocument({
    required this.docType,
    required this.fileName,
    required this.bytes,
  });

  final String docType;
  final String fileName;
  final Uint8List bytes;
}

/// Four-step onboarding flow.
class MerchantOnboardingPage extends ConsumerStatefulWidget {
  const MerchantOnboardingPage({super.key});

  @override
  ConsumerState<MerchantOnboardingPage> createState() =>
      _MerchantOnboardingPageState();
}

class _MerchantOnboardingPageState
    extends ConsumerState<MerchantOnboardingPage> {
  final _infoFormKey = GlobalKey<FormState>();
  final _locationFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _slugController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _radiusController = TextEditingController(text: '5');
  final _documents = <_MerchantDocument>[];
  final _hours = <int, ({String open, String close})>{};
  int _step = 0;
  bool _submitting = false;

  static const _dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _slugController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument(String docType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null || !mounted) return;
    setState(() {
      _documents.removeWhere((d) => d.docType == docType);
      _documents.add(
        _MerchantDocument(
          docType: docType,
          fileName: file.name,
          bytes: file.bytes!,
        ),
      );
    });
  }

  Future<void> _pickTime(int day) async {
    final now = TimeOfDay.now();
    final open = await showTimePicker(context: context, initialTime: now);
    if (open == null || !mounted) return;
    final close = await showTimePicker(
      context: context,
      initialTime: open.replacing(hour: open.hour + 1),
    );
    if (close == null || !mounted) return;
    setState(() {
      _hours[day] = (
        open:
            '${open.hour.toString().padLeft(2, '0')}:${open.minute.toString().padLeft(2, '0')}',
        close:
            '${close.hour.toString().padLeft(2, '0')}:${close.minute.toString().padLeft(2, '0')}',
      );
    });
  }

  Future<void> _submit() async {
    if (!_infoFormKey.currentState!.validate()) return;
    if (!_locationFormKey.currentState!.validate()) return;
    if (_documents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unggah minimal satu dokumen (KTP atau NIB).'),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final repo = ref.read(restaurantRepositoryProvider);
      final restaurant = await repo.createRestaurant(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        slug: _slugController.text.trim(),
        latitude: double.parse(_latController.text.trim()),
        longitude: double.parse(_lngController.text.trim()),
        deliveryRadiusMeters:
            (double.parse(_radiusController.text.trim()) * 1000).round(),
      );
      for (final entry in _hours.entries) {
        await repo.setHours(
          restaurantId: restaurant.id,
          dayOfWeek: entry.key,
          openTime: entry.value.open,
          closeTime: entry.value.close,
        );
      }
      for (final doc in _documents) {
        await repo.uploadDocument(
          restaurantId: restaurant.id,
          fileName: doc.fileName,
          bytes: doc.bytes,
        );
        await repo.submitDocument(
          docType: doc.docType,
          storagePath: '${restaurant.id}/${doc.fileName}',
        );
      }
      if (!mounted) return;
      unawaited(
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => MerchantStatusPage(restaurant: restaurant),
          ),
        ),
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Restoran')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stepper(
                currentStep: _step,
                onStepContinue: () async {
                  if (_step == 3) {
                    await _submit();
                  } else {
                    setState(() => _step += 1);
                  }
                },
                onStepCancel: () {
                  if (_step > 0) setState(() => _step -= 1);
                },
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: const EdgeInsets.only(top: PfSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: PfButton(
                            label: _step == 3 ? 'Kirim' : 'Lanjut',
                            onPressed: _submitting
                                ? null
                                : details.onStepContinue,
                            isLoading: _submitting,
                          ),
                        ),
                        if (_step > 0) ...[
                          const SizedBox(width: PfSpacing.md),
                          TextButton(
                            onPressed: _submitting
                                ? null
                                : details.onStepCancel,
                            child: const Text('Kembali'),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                steps: [
                  Step(
                    title: const Text('Info Bisnis'),
                    content: _buildInfoStep(),
                  ),
                  Step(
                    title: const Text('Lokasi'),
                    content: _buildLocationStep(),
                  ),
                  Step(
                    title: const Text('Jam Operasional'),
                    content: _buildHoursStep(),
                  ),
                  Step(
                    title: const Text('Dokumen Verifikasi'),
                    content: _buildDocumentsStep(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoStep() {
    return Form(
      key: _infoFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nama restoran'),
            validator: requiredValidator,
          ),
          const SizedBox(height: PfSpacing.md),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Deskripsi'),
            maxLines: 3,
          ),
          const SizedBox(height: PfSpacing.md),
          TextFormField(
            controller: _slugController,
            decoration: const InputDecoration(
              labelText: 'Slug (cth: warung-nusantara)',
            ),
            validator: requiredValidator,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return Form(
      key: _locationFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _latController,
            decoration: const InputDecoration(labelText: 'Latitude'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || double.tryParse(v) == null) {
                return 'Masukkan latitude yang valid.';
              }
              return null;
            },
          ),
          const SizedBox(height: PfSpacing.md),
          TextFormField(
            controller: _lngController,
            decoration: const InputDecoration(labelText: 'Longitude'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || double.tryParse(v) == null) {
                return 'Masukkan longitude yang valid.';
              }
              return null;
            },
          ),
          const SizedBox(height: PfSpacing.md),
          TextFormField(
            controller: _radiusController,
            decoration: const InputDecoration(
              labelText: 'Radius pengiriman (km)',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
    );
  }

  Widget _buildHoursStep() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _dayNames.length,
      itemBuilder: (context, index) {
        final value = _hours[index];
        return ListTile(
          title: Text(_dayNames[index]),
          trailing: value == null
              ? const Text('Atur jam')
              : Text('${value.open} – ${value.close}'),
          onTap: () => _pickTime(index),
        );
      },
    );
  }

  Widget _buildDocumentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Unggah KTP dan/atau NIB untuk verifikasi.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: PfSpacing.md),
        for (final docType in const ['ktp', 'nib']) ...[
          _documentTile(
            label: docType == 'ktp' ? 'KTP' : 'NIB',
            picked: _documents.any((d) => d.docType == docType),
            onPick: () => _pickDocument(docType),
          ),
          const SizedBox(height: PfSpacing.sm),
        ],
      ],
    );
  }

  Widget _documentTile({
    required String label,
    required bool picked,
    required VoidCallback onPick,
  }) {
    return ListTile(
      tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PfRadius.md),
      ),
      leading: Icon(picked ? Icons.check_circle : Icons.upload_file),
      title: Text(label),
      trailing: TextButton(onPressed: onPick, child: const Text('Pilih')),
    );
  }
}
