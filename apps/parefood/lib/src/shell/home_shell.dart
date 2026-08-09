/// Signed-in customer shell: bottom navigation over the Sprint 1 tabs
/// (Beranda = discovery, Akun = profile). Sprint 2 adds cart/order tabs.
library;

import 'package:discovery_feature/discovery_feature.dart';
import 'package:flutter/material.dart';
import 'package:profile_feature/profile_feature.dart';

/// Bottom-navigation host for the signed-in customer experience.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [DiscoveryPage(), ProfilePage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}
