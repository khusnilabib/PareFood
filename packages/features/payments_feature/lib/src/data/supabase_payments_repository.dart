/// Default [PaymentsRepository] backed by Supabase PostgREST + Edge Functions
/// (PF-DOC-11 §3.1, PF-DOC-14 §3.2). Reads go through PostgREST (RLS); charge
/// creation goes through the `process-payment` Edge Function (API-R01).
library;

import 'package:pare_core/pare_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/payment_intent.dart';
import '../domain/payment_method.dart';
import '../domain/payment_result.dart';
import '../domain/promo_code.dart';
import 'payments_repository.dart';

/// Adapts the Supabase client to [PaymentsRepository].
class SupabasePaymentsRepository implements PaymentsRepository {
  SupabasePaymentsRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<PaymentResult> createCharge({
    required String orderId,
    required String idempotencyKey,
    required Money amount,
    required PaymentMethod method,
  }) async {
    // Call the process-payment Edge Function (API-R01: money mutations are
    // Edge Functions, never PostgREST).
    final res = await _client.functions.invoke(
      'process-payment',
      headers: {'x-idempotency-key': idempotencyKey},
      body: {
        'order_id': orderId,
        'action': 'charge',
        'amount': amount.toJson,
        'method': method.toWire(),
      },
    );
    final data = res.data as Map<String, dynamic>?;
    final intent = data?['data'] as Map<String, dynamic>?;
    if (intent == null) {
      return const PaymentResult(paymentId: '', status: PaymentStatus.failed);
    }
    final status = PaymentIntentStatus.statusFromString(
      intent['status'] as String?,
    );
    return PaymentResult(
      paymentId: intent['id'] as String? ?? '',
      status: switch (status) {
        PaymentIntentStatus.succeeded => PaymentStatus.success,
        PaymentIntentStatus.failed => PaymentStatus.failed,
        _ => PaymentStatus.pending,
      },
      authorizedAmount: amount,
    );
  }

  @override
  Future<List<PaymentMethod>> availableMethods() async {
    // MVP: all three methods are available. A real impl reads a config table
    // or a per-restaurant allowlist (PF-DOC-18 §3.4).
    return const [
      PaymentMethod.cashOnDelivery,
      PaymentMethod.ewallet,
      PaymentMethod.card,
    ];
  }

  @override
  Future<PromoValidation> validatePromo({
    required String code,
    required Money subtotal,
  }) async {
    if (code.trim().isEmpty) return PromoValidation.none;
    try {
      final row = await _client
          .from('promotions')
          .select(
            'code, type, value, min_subtotal, max_discount, status, valid_from, valid_until',
          )
          .eq('code', code.trim().toUpperCase())
          .eq('status', 'active')
          .maybeSingle();
      if (row == null) {
        return PromoValidation(
          code: code,
          type: PromoType.fixed,
          discountAmount: Money.fromRupiah(0),
          isValid: false,
          message: 'Kode promo tidak ditemukan atau sudah berakhir.',
        );
      }
      final type = PromoTypeWire.fromString(row['type'] as String?);
      final value = (row['value'] as num?)?.toDouble() ?? 0;
      final minSubtotal = row['min_subtotal'] != null
          ? Money.fromRupiah(row['min_subtotal'] as int)
          : null;
      final maxDiscount = row['max_discount'] != null
          ? Money.fromRupiah(row['max_discount'] as int)
          : null;

      // BR-PROMO-002: min subtotal enforced.
      if (minSubtotal != null && subtotal < minSubtotal) {
        return PromoValidation(
          code: code,
          type: type,
          discountAmount: Money.fromRupiah(0),
          isValid: false,
          message: 'Minimal pesanan belum terpenuhi.',
          minSubtotal: minSubtotal,
          maxDiscount: maxDiscount,
        );
      }

      // Compute discount (BR-PROMO-001).
      var discount = Money.fromRupiah(0);
      switch (type) {
        case PromoType.fixed:
          discount = Money.fromRupiah(value.toInt());
        case PromoType.percent:
          final pct = value / 100;
          discount = Money.fromRupiah(
            (subtotal.amount.toDouble() * pct).round(),
          );
        case PromoType.freeDelivery:
          discount = Money.fromRupiah(0); // applied to delivery fee at checkout
      }

      // BR-PROMO-002: max discount enforced.
      if (maxDiscount != null && discount > maxDiscount) {
        discount = maxDiscount;
      }
      // BR-PRICE-003: discount ≤ subtotal.
      if (discount > subtotal) {
        discount = subtotal;
      }

      return PromoValidation(
        code: code,
        type: type,
        discountAmount: discount,
        isValid: true,
        message: 'Promo diterapkan.',
        minSubtotal: minSubtotal,
        maxDiscount: maxDiscount,
      );
    } on PostgrestException {
      return PromoValidation(
        code: code,
        type: PromoType.fixed,
        discountAmount: Money.fromRupiah(0),
        isValid: false,
        message: 'Gagal memvalidasi promo. Coba lagi.',
      );
    }
  }

  @override
  Future<PaymentIntent?> fetchIntentForOrder(String orderId) async {
    try {
      final row = await _client
          .from('payment_intents')
          .select(
            'id, order_id, intent_type, amount, status, psp, psp_status, created_at',
          )
          .eq('order_id', orderId)
          .eq('intent_type', 'charge')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;
      return _toIntent(row);
    } on PostgrestException {
      return null;
    }
  }

  PaymentIntent _toIntent(Map<String, dynamic> row) {
    return PaymentIntent(
      id: row['id'] as String,
      orderId: row['order_id'] as String?,
      intentType: PaymentIntentTypeWire.fromString(
        row['intent_type'] as String?,
      ),
      amount: Money.fromRupiah((row['amount'] as int?) ?? 0),
      status: PaymentIntentStatus.statusFromString(row['status'] as String?),
      psp: row['psp'] as String?,
      pspStatus: row['psp_status'] as String?,
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'] as String)
          : null,
    );
  }
}
