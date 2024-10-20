// actividades.dart
import 'package:flutter/material.dart';
import 'package:uniconnect/widgets/bottom_nav_bar.dart';

class ActividadesPage extends StatelessWidget {
  const ActividadesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actividades'),
        backgroundColor: const Color.fromARGB(255, 42, 143, 62),
      ),
      body: const Center(
        child: Text(
          'Pantalla de Actividades',
          style: TextStyle(fontSize: 24),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 2, // Índice para Actividades
        onItemTapped: (index) {},
      ),
    );
  }
}
