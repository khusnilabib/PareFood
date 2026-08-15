/// Default [FinanceRepository] backed by Supabase PostgREST (PF-DOC-14 §3.2).
/// Admin role only — RLS scopes all reads to the admin JWT.
library;

import 'package:pare_core/pare_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/payout.dart';
import '../domain/reconciliation_report.dart';
import '../domain/settlement.dart';
import 'finance_repository.dart';

class SupabaseFinanceRepository implements FinanceRepository {
  SupabaseFinanceRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<Settlement>> fetchSettlements({
    String? restaurantId,
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _client
        .from('settlements')
        .select(
          'id, restaurant_id, period_start, period_end, gross_amount, '
          'commission_amount, net_amount, status, approved_at, '
          'restaurants(name)',
        );
    if (restaurantId != null) {
      query = query.eq('restaurant_id', restaurantId);
    }
    if (from != null) {
      query = query.gte('period_end', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('period_start', to.toIso8601String());
    }
    final rows = await query.order('period_end', ascending: false).limit(100);
    return rows.map(_toSettlement).toList();
  }

  @override
  Future<void> approveSettlements(List<String> settlementIds) async {
    await _client
        .from('settlements')
        .update({
          'status': 'approved',
          'approved_at': DateTime.now().toUtc().toIso8601String(),
        })
        .inFilter('id', settlementIds);
  }

  @override
  Future<List<DriverPayout>> fetchPayouts({
    String? driverId,
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _client
        .from('payouts')
        .select(
          'id, driver_id, period_date, amount, delivery_count, status, '
          'bank_account_ref, profiles(full_name)',
        );
    if (driverId != null) {
      query = query.eq('driver_id', driverId);
    }
    if (from != null) {
      query = query.gte('period_date', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('period_date', to.toIso8601String());
    }
    final rows = await query.order('period_date', ascending: false).limit(100);
    return rows.map(_toPayout).toList();
  }

  @override
  Future<ReconciliationReport> fetchReconciliation({
    required DateTime from,
    required DateTime to,
  }) async {
    // Aggregate delivered orders in the period.
    final orders = await _client
        .from('orders')
        .select('total, subtotal, delivery_fee, payment_method, payment_status')
        .eq('status', 'delivered')
        .gte('completed_at', from.toIso8601String())
        .lte('completed_at', to.toIso8601String());

    var grossOrderTotal = 0;
    var commissionTotal = 0;
    var driverFareTotal = 0;
    var codCollected = 0;

    for (final o in orders) {
      final total = (o['total'] as int?) ?? 0;
      final subtotal = (o['subtotal'] as int?) ?? 0;
      final deliveryFee = (o['delivery_fee'] as int?) ?? 0;
      grossOrderTotal += total;
      // Commission ≈ 15% of subtotal (simplified; real impl reads per-restaurant rate).
      commissionTotal += (subtotal * 0.15).round();
      driverFareTotal += deliveryFee;
      if (o['payment_method'] == 'cod') {
        codCollected += total;
      }
    }

    // COD remitted = sum of wallet_transactions with reason 'cod_remittance'.
    final remittances = await _client
        .from('wallet_transactions')
        .select('amount')
        .eq('reason', 'cod_remittance')
        .eq('status', 'completed')
        .gte('created_at', from.toIso8601String())
        .lte('created_at', to.toIso8601String());
    var codRemitted = 0;
    for (final r in remittances) {
      codRemitted += (r['amount'] as int?) ?? 0;
    }

    // Restaurant settlements net in the period.
    final settlements = await _client
        .from('settlements')
        .select('net_amount')
        .gte('period_end', from.toIso8601String())
        .lte('period_start', to.toIso8601String());
    var restaurantSettlementsTotal = 0;
    for (final s in settlements) {
      restaurantSettlementsTotal += (s['net_amount'] as int?) ?? 0;
    }

    final codOutstanding = codCollected - codRemitted;
    final mismatchCount = codOutstanding > 0 ? 1 : 0;

    return ReconciliationReport(
      periodStart: from,
      periodEnd: to,
      grossOrderTotal: Money.fromRupiah(grossOrderTotal),
      commissionCollected: Money.fromRupiah(commissionTotal),
      driverFaresPaid: Money.fromRupiah(driverFareTotal),
      restaurantSettlements: Money.fromRupiah(restaurantSettlementsTotal),
      codCollected: Money.fromRupiah(codCollected),
      codRemitted: Money.fromRupiah(codRemitted),
      mismatchCount: mismatchCount,
    );
  }

  @override
  Future<PlatformKpis> fetchKpis() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    // Orders today count + GMV.
    final orders = await _client
        .from('orders')
        .select('total')
        .gte('placed_at', startOfDay.toIso8601String());
    var gmv = 0;
    for (final o in orders) {
      gmv += (o['total'] as int?) ?? 0;
    }

    // Active merchants.
    final merchants = await _client
        .from('restaurants')
        .select('id')
        .eq('status', 'active');
    // Active drivers.
    final drivers = await _client
        .from('driver_locations')
        .select('id')
        .eq('online', true);

    // Pending settlements + payouts amounts.
    final pendingSettlements = await _client
        .from('settlements')
        .select('net_amount')
        .eq('status', 'calculated');
    var pendingSettle = 0;
    for (final s in pendingSettlements) {
      pendingSettle += (s['net_amount'] as int?) ?? 0;
    }
    final pendingPayouts = await _client
        .from('payouts')
        .select('amount')
        .eq('status', 'pending');
    var pendingPay = 0;
    for (final p in pendingPayouts) {
      pendingPay += (p['amount'] as int?) ?? 0;
    }

    return PlatformKpis(
      ordersToday: orders.length,
      gmvToday: Money.fromRupiah(gmv),
      activeMerchants: merchants.length,
      activeDrivers: drivers.length,
      pendingSettlements: Money.fromRupiah(pendingSettle),
      pendingPayouts: Money.fromRupiah(pendingPay),
    );
  }

  Settlement _toSettlement(Map<String, dynamic> row) {
    final rest = (row['restaurants'] as Map<String, dynamic>?) ?? const {};
    return Settlement(
      id: row['id'] as String,
      restaurantId: row['restaurant_id'] as String,
      restaurantName: (rest['name'] as String?) ?? 'Restoran',
      periodStart: DateTime.parse(row['period_start'] as String),
      periodEnd: DateTime.parse(row['period_end'] as String),
      gross: Money.fromRupiah((row['gross_amount'] as int?) ?? 0),
      commission: Money.fromRupiah((row['commission_amount'] as int?) ?? 0),
      net: Money.fromRupiah((row['net_amount'] as int?) ?? 0),
      status: SettlementStatusX.fromString(row['status'] as String?),
      approvedAt: row['approved_at'] != null
          ? DateTime.tryParse(row['approved_at'] as String)
          : null,
    );
  }

  DriverPayout _toPayout(Map<String, dynamic> row) {
    final profile = (row['profiles'] as Map<String, dynamic>?) ?? const {};
    return DriverPayout(
      id: row['id'] as String,
      driverId: row['driver_id'] as String,
      driverName: (profile['full_name'] as String?) ?? 'Driver',
      periodDate: DateTime.parse(row['period_date'] as String),
      amount: Money.fromRupiah((row['amount'] as int?) ?? 0),
      deliveryCount: (row['delivery_count'] as int?) ?? 0,
      status: PayoutStatusX.fromString(row['status'] as String?),
      bankAccountRef: row['bank_account_ref'] as String?,
    );
  }
}
