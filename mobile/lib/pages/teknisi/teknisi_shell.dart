import 'package:flutter/material.dart';

import 'beranda_teknisi_page.dart';
import 'pesanan_teknisi_page.dart';
import 'dompet_teknisi_page.dart';
import 'kelola_profil_teknisi_page.dart'; // sesuaikan path kalau file-nya di lib/pages/

class TeknisiShell extends StatefulWidget {
  const TeknisiShell({super.key});

  @override
  State<TeknisiShell> createState() => _TeknisiShellState();
}

class _TeknisiShellState extends State<TeknisiShell> {
  int _index = 0;

  // IndexedStack: state tiap tab (scroll, form) nggak hilang saat pindah tab
  final _pages = const [
    BerandaTeknisiPage(),
    PesananTeknisiPage(),
    DompetTeknisiPage(),
    KelolaProfilTeknisiPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Pesanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Dompet',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
