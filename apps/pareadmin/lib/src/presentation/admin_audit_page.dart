/// Admin audit log page: read-only list of admin actions (FR-ORDER-010 audit).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_shell.dart';

/// Provider that fetches the audit log (refreshable).
final auditLogProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final rows = await Supabase.instance.client
      .from('audit_logs')
      .select('id, actor_id, action, entity_type, entity_id, created_at')
      .order('created_at', ascending: false)
      .limit(100);
  return List<Map<String, dynamic>>.from(rows);
});

/// Admin audit log viewer.
class AdminAuditPage extends ConsumerWidget {
  const AdminAuditPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(auditLogProvider);
    return AdminShell(
      section: AdminSection.audit,
      child: Scaffold(
        appBar: AppBar(title: const Text('Audit Log')),
        body: logs.when(
          data: (list) {
            if (list.isEmpty) {
              return const PfEmptyState(
                icon: Icons.history,
                title: 'Belum ada log',
                subtitle: 'Aksi admin akan tercatat di sini.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(PfSpacing.md),
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final log = list[index];
                return ListTile(
                  leading: Icon(
                    _iconFor(log['action'] as String? ?? ''),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(log['action'] as String? ?? ''),
                  subtitle: Text(
                    '${log['entity_type'] ?? ''} ${log['entity_id'] ?? ''} • '
                    '${formatDateIndonesian(DateTime.parse(log['created_at'] as String))}',
                  ),
                  trailing: Text(
                    (log['actor_id'] as String?)?.substring(0, 8) ?? '—',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => PfErrorState(
            onRetry: () => ref.invalidate(auditLogProvider),
            title: 'Gagal memuat audit log.',
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String action) {
    if (action.contains('cancel')) return Icons.cancel_outlined;
    if (action.contains('approve')) return Icons.check_circle_outline;
    if (action.contains('suspend')) return Icons.block;
    if (action.contains('role')) return Icons.badge_outlined;
    return Icons.history;
  }
}
