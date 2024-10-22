import 'package:flutter/material.dart';
import 'package:uniconnect/pantallas/pantalla_principal.dart';
import 'package:uniconnect/pantallas/grupos.dart';
import 'package:uniconnect/pantallas/actividades.dart';
import 'package:uniconnect/pantallas/ajustes.dart';
import 'package:uniconnect/pantallas/novedades.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  void _navigateToScreen(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PantallaPrincipal()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GruposPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ActividadesPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NovedadesPage()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AjustesPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble),
          label: 'Chats',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group),
          label: 'Grupos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Actividades',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.announcement),
          label: 'Novedades',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Ajustes',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: const Color.fromARGB(255, 42, 143, 62), // Color verde
      unselectedItemColor: Colors.grey, // Color gris
      backgroundColor: Colors.white,
      onTap: (index) =>
          _navigateToScreen(context, index), // Navegar al hacer tap
      elevation: 5,
      type: BottomNavigationBarType.fixed,
    );
  }
}
