// ajustes.dart
import 'package:flutter/material.dart';
import 'package:uniconnect/widgets/bottom_nav_bar.dart';

class AjustesPage extends StatelessWidget {
  const AjustesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: const Color.fromARGB(255, 42, 143, 62),
      ),
      body: const Center(
        child: Text(
          'Pantalla de Ajustes',
          style: TextStyle(fontSize: 24),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 4, // Índice para Ajustes
        onItemTapped: (index) {},
      ),
    );
  }
}
