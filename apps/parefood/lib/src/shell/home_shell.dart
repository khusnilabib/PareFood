/// Signed-in customer shell: bottom navigation over the customer tabs
/// (Beranda = discovery, Keranjang = cart, Akun = profile).
///
/// Wires the discovery → detail → add-to-cart flow (FR-DISC-004 + FR-CART-001):
/// tapping a restaurant opens [RestaurantDetailPage] with an [onAddToCart]
/// callback bound to [cartProvider]. BR-CART-001 (single-restaurant cart) is
/// enforced by the domain; the shell shows a confirmation dialog when the user
/// adds an item from a different restaurant than the cart's current one.
library;

import 'package:cart_feature/cart_feature.dart';
import 'package:discovery_feature/discovery_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profile_feature/profile_feature.dart';

/// Bottom-navigation host for the signed-in customer experience.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  void _openRestaurant(String restaurantId, String restaurantName) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RestaurantDetailPage(
          restaurantId: restaurantId,
          onAddToCart: (item) => _addToCart(
            restaurantId: restaurantId,
            restaurantName: restaurantName,
            item: item,
          ),
        ),
      ),
    );
  }

  void _addToCart({
    required String restaurantId,
    required String restaurantName,
    required DiscoveryMenuItem item,
  }) {
    final cart = ref.read(cartProvider);
    if (!cart.isSameRestaurant(restaurantId) && !cart.isEmpty) {
      // BR-CART-001: adding from a different restaurant replaces the cart.
      _confirmRestaurantSwitch(
        restaurantName: restaurantName,
        onConfirm: () => _doAdd(restaurantId, restaurantName, item),
      );
      return;
    }
    _doAdd(restaurantId, restaurantName, item);
  }

  void _doAdd(
    String restaurantId,
    String restaurantName,
    DiscoveryMenuItem item,
  ) {
    ref
        .read(cartProvider.notifier)
        .addItem(
          CartItem(productId: item.id, name: item.name, unitPrice: item.price),
          restaurantId: restaurantId,
          restaurantName: restaurantName,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} ditambahkan ke keranjang'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _confirmRestaurantSwitch({
    required String restaurantName,
    required VoidCallback onConfirm,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ganti restoran?'),
          content: Text(
            'Keranjangmu berisi menu dari restoran lain. Menambahkan menu dari '
            '$restaurantName akan mengosongkan keranjang saat ini.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm();
              },
              child: const Text('Ganti'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final qty = cart.totalQuantity;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DiscoveryPage(
            onViewRestaurant: (context, restaurantId) {
              final list = ref
                  .read(
                    nearbyRestaurantsProvider((
                      lat: -6.200000,
                      lng: 106.816666,
                      radiusKm: 5,
                    )),
                  )
                  .asData
                  ?.value;
              String name = 'Restoran';
              if (list != null) {
                for (final r in list) {
                  if (r.id == restaurantId) {
                    name = r.name;
                    break;
                  }
                }
              }
              _openRestaurant(restaurantId, name);
            },
          ),
          const CartPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: qty > 0,
              label: Text('$qty'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: qty > 0,
              label: Text('$qty'),
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Keranjang',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}
