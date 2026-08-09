/// Menu item add/edit page (FR-MENU-001, PF-DOC-11 §3.1).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../application/menu_providers.dart';
import '../../domain/menu_models.dart';

/// Creates or edits a single menu item.
class MenuItemEditPage extends ConsumerStatefulWidget {
  const MenuItemEditPage({required this.restaurantId, this.item, super.key});

  final String restaurantId;

  /// When `null`, a new item is created.
  final MenuItem? item;

  @override
  ConsumerState<MenuItemEditPage> createState() => _MenuItemEditPageState();
}

class _MenuItemEditPageState extends ConsumerState<MenuItemEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  String? _categoryId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _priceController = TextEditingController(
      text: item == null ? '' : item.price.amount.toString(),
    );
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _categoryId = item?.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(menuRepositoryProvider)
          .upsertItem(
            restaurantId: widget.restaurantId,
            id: widget.item?.id,
            categoryId: _categoryId,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            price: int.parse(_priceController.text.trim()),
          );
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(menuProvider(widget.restaurantId)).value;
    final categoryOptions = <String?, String>{null: 'Tanpa kategori'};
    if (categories != null) {
      for (final c in categories.categories) {
        categoryOptions[c.id] = c.name;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Tambah item' : 'Edit item'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PfSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama item'),
                  validator: requiredValidator,
                ),
                const SizedBox(height: PfSpacing.md),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Harga (Rp)'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final price = int.tryParse(v ?? '');
                    if (price == null || price < 0) {
                      return 'Masukkan harga yang valid.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: PfSpacing.md),
                DropdownButtonFormField<String?>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: categoryOptions.entries
                      .map(
                        (e) => DropdownMenuItem<String?>(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _categoryId = value),
                ),
                const SizedBox(height: PfSpacing.md),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                  maxLines: 3,
                ),
                const SizedBox(height: PfSpacing.lg),
                PfButton(
                  label: widget.item == null ? 'Tambah' : 'Simpan',
                  onPressed: _submitting ? null : _submit,
                  isLoading: _submitting,
                ),
                if (widget.item != null) ...[
                  const SizedBox(height: PfSpacing.sm),
                  TextButton.icon(
                    onPressed: () async {
                      await ref
                          .read(menuRepositoryProvider)
                          .deleteItem(widget.item!.id);
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus item'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
