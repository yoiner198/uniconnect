// novedades.dart
import 'package:flutter/material.dart';
import 'package:uniconnect/widgets/bottom_nav_bar.dart';

class NovedadesPage extends StatelessWidget {
  const NovedadesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novedades'),
        backgroundColor: const Color.fromARGB(255, 42, 143, 62),
      ),
      body: const Center(
        child: Text(
          'Pantalla de Novedades',
          style: TextStyle(fontSize: 24),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 3, // Índice para Novedades
        onItemTapped: (index) {},
      ),
    );
  }
}
