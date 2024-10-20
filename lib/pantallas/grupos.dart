// grupos.dart
import 'package:flutter/material.dart';
import 'package:uniconnect/widgets/bottom_nav_bar.dart';

class GruposPage extends StatelessWidget {
  const GruposPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grupos'),
        backgroundColor: const Color.fromARGB(255, 42, 143, 62),
      ),
      body: const Center(
        child: Text(
          'Pantalla de Grupos',
          style: TextStyle(fontSize: 24),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 1, // Índice para Grupos
        onItemTapped: (index) {},
      ),
    );
  }
}
