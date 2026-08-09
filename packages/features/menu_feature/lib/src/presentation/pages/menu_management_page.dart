/// Menu management page (FR-MENU-001/002/003, PF-DOC-11 §3.1).
///
/// Shows categories and items grouped by category with availability toggles,
/// plus item add/edit and CSV import entry points.
library;

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';

import '../../application/menu_providers.dart';
import '../../domain/menu_models.dart';
import 'menu_item_edit_page.dart';

/// Menu management entry point for a merchant's restaurant.
class MenuManagementPage extends ConsumerStatefulWidget {
  const MenuManagementPage({required this.restaurantId, super.key});

  final String restaurantId;

  @override
  ConsumerState<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends ConsumerState<MenuManagementPage> {
  @override
  Widget build(BuildContext context) {
    final menu = ref.watch(menuProvider(widget.restaurantId));
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: menu.when(
        data: _buildList,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => PfErrorState(
          onRetry: () => ref.invalidate(menuProvider(widget.restaurantId)),
          error: error is PareException ? error : null,
          title: 'Gagal memuat menu.',
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openItemEditor,
        icon: const Icon(Icons.add),
        label: const Text('Tambah item'),
      ),
    );
  }

  Widget _buildList(
    ({List<MenuCategory> categories, List<MenuItem> items}) data,
  ) {
    if (data.items.isEmpty) {
      return PfEmptyState(
        icon: Icons.restaurant_menu,
        title: 'Belum ada item',
        subtitle: 'Tambahkan item pertama Anda atau impor dari CSV.',
        actionLabel: 'Impor CSV',
        onAction: _importCsv,
      );
    }
    final categoriesById = <String, MenuCategory>{
      for (final c in data.categories) c.id: c,
    };
    final grouped = <String?, List<MenuItem>>{};
    for (final item in data.items) {
      grouped.putIfAbsent(item.categoryId, () => []).add(item);
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(menuProvider(widget.restaurantId)),
      child: ListView(
        padding: const EdgeInsets.all(PfSpacing.md),
        children: [
          TextButton.icon(
            onPressed: _importCsv,
            icon: const Icon(Icons.upload_file),
            label: const Text('Impor dari CSV'),
          ),
          for (final entry in grouped.entries) ...[
            ListTile(
              dense: true,
              leading: const Icon(Icons.category_outlined, size: 20),
              title: Text(
                categoriesById[entry.key]?.name ?? 'Tanpa kategori',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            for (final item in entry.value) _itemTile(item, categoriesById),
          ],
        ],
      ),
    );
  }

  Widget _itemTile(MenuItem item, Map<String, MenuCategory> categoriesById) {
    return Card(
      margin: const EdgeInsets.only(bottom: PfSpacing.xs),
      child: ListTile(
        title: Text(item.name),
        subtitle: Text(
          '${formatIdr(item.price.amount)} · ${categoriesById[item.categoryId]?.name ?? ''}',
        ),
        trailing: Switch(
          value: item.isAvailable,
          onChanged: (value) => _toggleAvailability(item, value),
        ),
        onTap: () => _openItemEditor(item: item),
      ),
    );
  }

  Future<void> _toggleAvailability(MenuItem item, bool available) async {
    await ref
        .read(menuRepositoryProvider)
        .setAvailability(
          restaurantId: widget.restaurantId,
          itemId: item.id,
          isAvailable: available,
        );
    ref.invalidate(menuProvider(widget.restaurantId));
  }

  Future<void> _openItemEditor({MenuItem? item}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            MenuItemEditPage(restaurantId: widget.restaurantId, item: item),
      ),
    );
    ref.invalidate(menuProvider(widget.restaurantId));
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    final file = result?.files.single;
    if (file == null) return;

    final String raw;
    if (file.bytes != null) {
      raw = utf8.decode(file.bytes!);
    } else {
      raw = await file.xFile.readAsString();
    }
    final rows = <Map<String, String>>[];
    final lines = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return;
    final header = lines.first.split(',').map((h) => h.trim()).toList();
    for (final line in lines.skip(1)) {
      final cells = line.split(',');
      final row = <String, String>{};
      for (var i = 0; i < header.length; i++) {
        row[header[i]] = i < cells.length ? cells[i].trim() : '';
      }
      rows.add(row);
    }

    final result2 = await ref
        .read(menuRepositoryProvider)
        .importCsv(restaurantId: widget.restaurantId, rows: rows);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Impor selesai: ${result2.created} dibuat, ${result2.skipped} dilewati.',
        ),
      ),
    );
    ref.invalidate(menuProvider(widget.restaurantId));
  }
}
