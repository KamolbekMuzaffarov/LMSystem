import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'potolok/potolok_screen.dart';

/// Ilovaning ikki bo'limi orasidagi almashtirgich.
///
/// «Chizmalar» — o'lchov va hisob, «Potolok» — natyajnoy potolok xizmati.
class RootShell extends StatefulWidget {
  const RootShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  late int _index = widget.initialIndex.clamp(0, 1);

  /// Ochilgan bo'limlar. Potolok bo'limi birinchi marta bosilgandagina
  /// quriladi — ilova shu sabab tez ochiladi.
  late final Set<int> _opened = <int>{_index};

  void _select(int value) {
    setState(() {
      _index = value;
      _opened.add(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ekranlar jonli qoladi: bo'lim almashganda ro'yxat joyida turadi.
      body: IndexedStack(
        index: _index,
        children: <Widget>[
          const HomeScreen(),
          if (_opened.contains(1))
            const PotolokScreen()
          else
            const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.shapeFill,
        surfaceTintColor: Colors.transparent,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.straighten_outlined),
            selectedIcon: Icon(Icons.straighten),
            label: 'Chizmalar',
          ),
          NavigationDestination(
            icon: Icon(Icons.roofing_outlined),
            selectedIcon: Icon(Icons.roofing),
            label: 'Potolok',
          ),
        ],
      ),
    );
  }
}
