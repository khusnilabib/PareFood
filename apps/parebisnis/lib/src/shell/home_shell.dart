/// Signed-in merchant shell: bottom navigation with lazy-loaded tabs.
/// Uses PageView for efficient tab switching without rebuilding off-screen tabs.
library;

import 'package:flutter/material.dart';
import 'package:profile_feature/profile_feature.dart';

import 'menu_tab.dart';
import 'restaurant_tab.dart';

/// Bottom-navigation host for the signed-in merchant experience.
/// Implements lazy loading via PageView to prevent unnecessary rebuilds.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
  }

  void _onDestinationSelected(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          _RestaurantTabKeepAlive(),
          _MenuTabKeepAlive(),
          _ProfilePageKeepAlive(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store),
            label: 'Restoran',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Menu',
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

/// Wraps RestaurantTab with AutomaticKeepAliveClientMixin to preserve state
/// when tab is not visible (prevents rebuild on navigation).
class _RestaurantTabKeepAlive extends StatefulWidget {
  const _RestaurantTabKeepAlive();

  @override
  State<_RestaurantTabKeepAlive> createState() =>
      _RestaurantTabKeepAliveState();
}

class _RestaurantTabKeepAliveState extends State<_RestaurantTabKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const RestaurantTab();
  }
}

/// Wraps MenuTab with AutomaticKeepAliveClientMixin to preserve state
/// when tab is not visible (prevents rebuild on navigation).
class _MenuTabKeepAlive extends StatefulWidget {
  const _MenuTabKeepAlive();

  @override
  State<_MenuTabKeepAlive> createState() => _MenuTabKeepAliveState();
}

class _MenuTabKeepAliveState extends State<_MenuTabKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const MenuTab();
  }
}

/// Wraps ProfilePage with AutomaticKeepAliveClientMixin to preserve state
/// when tab is not visible (prevents rebuild on navigation).
class _ProfilePageKeepAlive extends StatefulWidget {
  const _ProfilePageKeepAlive();

  @override
  State<_ProfilePageKeepAlive> createState() => _ProfilePageKeepAliveState();
}

class _ProfilePageKeepAliveState extends State<_ProfilePageKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const ProfilePage();
  }
}
