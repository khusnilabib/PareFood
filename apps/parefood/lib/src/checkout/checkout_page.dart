/// Checkout page: address + promo + fee breakdown + payment method + place
/// order (FR-CART-002..006, FR-PAY-001..002).
///
/// Lives in the app composition root so it can import both [cart_feature] and
/// [payments_feature] (MO-R02d: features never cross-import; the app wires
/// them together). The place-order call goes through the `place-order` Edge
/// Function via [PaymentsRepository.createCharge] + a direct Supabase
/// functions invoke.
library;

import 'package:cart_feature/cart_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pare_core/pare_core.dart';
import 'package:pare_design/pare_design.dart';
import 'package:pare_util/pare_util.dart';
import 'package:payments_feature/payments_feature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Full checkout flow bound to [cartProvider] + [paymentsRepositoryProvider].
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({this.onOrderPlaced, super.key});

  /// Called with the new order id when placement succeeds.
  final void Function(String orderId)? onOrderPlaced;

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _addressController = TextEditingController();
  final _promoController = TextEditingController();
  PaymentMethod? _selectedMethod;
  PromoValidation _promo = PromoValidation.none;
  bool _validatingPromo = false;
  bool _placing = false;

  // BR-PRICE defaults (PF-DOC-18 §3.1). In production these come from a
  // config table or the restaurant's delivery settings.
  static const _deliveryFee = 6000;
  static const _serviceFee = 2000;
  static const _minOrder = 15000;

  @override
  void dispose() {
    _addressController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  CheckoutSummary get _summary {
    final cart = ref.read(cartProvider);
    return CheckoutSummary(
      subtotal: cart.subtotal,
      deliveryFee: Money.fromRupiah(_deliveryFee),
      serviceFee: Money.fromRupiah(_serviceFee),
      discount: _promo.discountAmount,
    );
  }

  Future<void> _validatePromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      setState(() => _promo = PromoValidation.none);
      return;
    }
    setState(() => _validatingPromo = true);
    try {
      final result = await ref
          .read(paymentsRepositoryProvider)
          .validatePromo(code: code, subtotal: ref.read(cartProvider).subtotal);
      if (mounted) setState(() => _promo = result);
    } finally {
      if (mounted) setState(() => _validatingPromo = false);
    }
  }

  Future<void> _placeOrder() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty || _selectedMethod == null) return;
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat pengiriman wajib diisi.')),
      );
      return;
    }
    if (!_summary.meetsMinimum(Money.fromRupiah(_minOrder))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal pesanan Rp $_minOrder.')),
      );
      return;
    }

    final restaurantId = cart.restaurantId;
    if (restaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restoran tidak diketahui.')),
      );
      return;
    }

    setState(() => _placing = true);
    try {
      final idempotencyKey = DateTime.now().microsecondsSinceEpoch.toString();
      final res = await Supabase.instance.client.functions.invoke(
        'place-order',
        headers: {'x-idempotency-key': idempotencyKey},
        body: {
          'restaurant_id': restaurantId,
          'delivery_address': address,
          'payment_method': _selectedMethod!.toWire(),
          'items': cart.items
              .map(
                (item) => {
                  'menu_item_id': item.productId,
                  'name': item.name,
                  'unit_price': item.unitPrice.toJson,
                  'quantity': item.quantity,
                },
              )
              .toList(),
          'subtotal': cart.subtotal.toJson,
          'delivery_fee': _deliveryFee,
          'service_fee': _serviceFee,
          'discount': _promo.discountAmount.toJson,
        },
      );
      final data = res.data as Map<String, dynamic>?;
      final order = data?['data']?['order'] as Map<String, dynamic>?;
      final orderId = order?['id'] as String?;

      if (orderId != null) {
        // For non-COD, create a charge via process-payment.
        if (_selectedMethod != PaymentMethod.cashOnDelivery) {
          await ref
              .read(paymentsRepositoryProvider)
              .createCharge(
                orderId: orderId,
                idempotencyKey: 'charge-$idempotencyKey',
                amount: _summary.total,
                method: _selectedMethod!,
              );
        }
        ref.read(cartProvider.notifier).clear();
        if (mounted) widget.onOrderPlaced?.call(orderId);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membuat pesanan. Coba lagi.')),
          );
        }
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat pesanan: $e')));
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);
    final methods = ref.watch(paymentMethodsProvider);
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: cart.isEmpty
          ? const PfEmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Keranjang kosong',
              subtitle: 'Tambahkan menu sebelum checkout.',
            )
          : ListView(
              padding: const EdgeInsets.all(PfSpacing.md),
              children: [
                // Items summary
                Text('Ringkasan Pesanan', style: theme.textTheme.titleMedium),
                const SizedBox(height: PfSpacing.sm),
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final item in cart.items) ...[
                        ListTile(
                          title: Text(item.name),
                          subtitle: Text(
                            '${item.quantity} × ${formatIdr(item.unitPrice.amount)}',
                          ),
                          trailing: Text(formatIdr(item.lineTotal.amount)),
                        ),
                        if (item != cart.items.last) const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: PfSpacing.md),

                // Delivery address (FR-CART-003)
                Text('Alamat Pengiriman', style: theme.textTheme.titleMedium),
                const SizedBox(height: PfSpacing.sm),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Alamat lengkap',
                    hintText: 'Jl. Contoh No. 123, RT/RW, Kelurahan',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: PfSpacing.md),

                // Promo code (FR-CART-004)
                Text('Kode Promo', style: theme.textTheme.titleMedium),
                const SizedBox(height: PfSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promoController,
                        decoration: const InputDecoration(
                          labelText: 'Kode promo',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                    const SizedBox(width: PfSpacing.sm),
                    PfButton(
                      label: 'Cek',
                      variant: PfButtonVariant.outline,
                      size: PfButtonSize.medium,
                      expandWidth: false,
                      isLoading: _validatingPromo,
                      onPressed: _validatePromo,
                    ),
                  ],
                ),
                if (_promo.message != null) ...[
                  const SizedBox(height: PfSpacing.xs),
                  Text(
                    _promo.message!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _promo.isValid
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: PfSpacing.md),

                // Payment method (FR-PAY-001)
                Text('Metode Pembayaran', style: theme.textTheme.titleMedium),
                const SizedBox(height: PfSpacing.sm),
                methods.when(
                  data: (list) => Card(
                    margin: EdgeInsets.zero,
                    child: RadioGroup<PaymentMethod>(
                      groupValue: _selectedMethod,
                      onChanged: (v) => setState(() => _selectedMethod = v),
                      child: Column(
                        children: [
                          for (final m in list) ...[
                            RadioListTile<PaymentMethod>(
                              value: m,
                              title: Text(m.label),
                            ),
                            if (m != list.last) const Divider(height: 1),
                          ],
                        ],
                      ),
                    ),
                  ),
                  loading: () => const SizedBox(
                    height: 48,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) =>
                      const Text('Gagal memuat metode pembayaran.'),
                ),
                const SizedBox(height: PfSpacing.md),

                // Fee breakdown (FR-CART-002)
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(PfSpacing.md),
                    child: Column(
                      children: [
                        _row('Subtotal', formatIdr(summary.subtotal.amount)),
                        _row(
                          'Ongkos kirim',
                          formatIdr(summary.deliveryFee.amount),
                        ),
                        _row(
                          'Biaya layanan',
                          formatIdr(summary.serviceFee.amount),
                        ),
                        if (summary.discount != null &&
                            !summary.discount!.isZero)
                          _row(
                            'Diskon',
                            '-${formatIdr(summary.discount!.amount)}',
                          ),
                        const Divider(),
                        _row(
                          'Total',
                          formatIdr(summary.total.amount),
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: PfSpacing.lg),

                // Place order CTA (FR-PAY-002)
                PfButton(
                  label: 'Pesan Sekarang',
                  icon: Icons.shopping_bag_outlined,
                  isLoading: _placing,
                  onPressed: _placing || _selectedMethod == null
                      ? null
                      : _placeOrder,
                ),
              ],
            ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: bold
                ? theme.textTheme.titleMedium
                : theme.textTheme.bodyMedium,
          ),
          const Spacer(),
          Text(
            value,
            style: bold
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  )
                : theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
